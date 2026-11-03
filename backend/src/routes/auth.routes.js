import { Router } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import crypto from 'crypto';
import { query } from '../config/db.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = Router();

const JWT_SECRET = process.env.JWT_SECRET || 'sitepyoe_jwt_super_secret_key_change_in_production';
const JWT_ACCESS_EXPIRES_IN = process.env.JWT_ACCESS_EXPIRES_IN || '24h';
const JWT_REFRESH_SECRET = process.env.JWT_REFRESH_SECRET || 'sitepyoe_jwt_refresh_secret_key_change_in_production';
const JWT_REFRESH_EXPIRES_IN = process.env.JWT_REFRESH_EXPIRES_IN || '30d';

const hashToken = (token) => crypto.createHash('sha256').update(token).digest('hex');

// Generate access & refresh tokens
const generateTokens = async (user) => {
  const payload = {
    id: user.id,
    name: user.name,
    email: user.email,
    phone: user.phone,
    role: user.role,
    branchId: user.branch_id,
  };

  const accessToken = jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_ACCESS_EXPIRES_IN });
  const refreshToken = jwt.sign(
    { id: user.id, jti: crypto.randomUUID() },
    JWT_REFRESH_SECRET,
    { expiresIn: JWT_REFRESH_EXPIRES_IN }
  );

  // Store refresh token hash in DB (expires in 30 days)
  const tokenHash = hashToken(refreshToken);
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);

  await query(
    `INSERT INTO refresh_tokens (user_id, token_hash, expires_at)
     VALUES ($1, $2, $3)
     ON CONFLICT (token_hash) DO UPDATE SET expires_at = EXCLUDED.expires_at`,
    [user.id, tokenHash, expiresAt]
  );

  return { accessToken, refreshToken, expiresIn: 86400 }; // 24 hours
};

// POST /api/v1/auth/login
router.post('/login', async (req, res, next) => {
  try {
    const { email, phone, identifier, username, password } = req.body;
    const loginIdentifier = email || phone || identifier || username;

    if (!loginIdentifier || !password) {
      return res.status(400).json({
        success: false,
        message: 'Username/Email/Phone and password are required',
      });
    }

    // Lookup user by email, phone, or name
    const userRes = await query(
      `SELECT u.*, b.name AS branch_name
       FROM users u
       LEFT JOIN branches b ON u.branch_id = b.id
       WHERE (LOWER(u.email) = LOWER($1) OR u.phone = $1 OR LOWER(u.name) = LOWER($1))
       LIMIT 1`,
      [loginIdentifier.trim()]
    );

    if (userRes.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    const user = userRes.rows[0];

    if (!user.is_active) {
      return res.status(403).json({
        success: false,
        message: 'Account has been deactivated. Please contact an administrator.',
      });
    }

    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({
        success: false,
        message: 'Invalid credentials',
      });
    }

    // Update last login
    await query('UPDATE users SET last_login_at = NOW() WHERE id = $1', [user.id]);

    // Issue tokens
    const tokens = await generateTokens(user);

    res.json({
      success: true,
      data: {
        ...tokens,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          permissionGroupId: user.permission_group_id,
          customPermissions: user.custom_permissions,
          branchId: user.branch_id,
          branchName: user.branch_name,
        },
      },
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/auth/refresh
router.post('/refresh', async (req, res, next) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({
        success: false,
        message: 'Refresh token is required',
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(refreshToken, JWT_REFRESH_SECRET);
    } catch {
      return res.status(401).json({
        success: false,
        code: 'INVALID_REFRESH_TOKEN',
        message: 'Invalid or expired refresh token',
      });
    }

    const incomingHash = hashToken(refreshToken);

    // Opportunistically clean up expired refresh tokens
    await query('DELETE FROM refresh_tokens WHERE expires_at <= NOW()');

    // Keep a 60-second grace window on rotated tokens to prevent concurrent refresh race conditions
    const tokenRes = await query(
      `UPDATE refresh_tokens
       SET expires_at = LEAST(expires_at, NOW() + INTERVAL '60 seconds')
       WHERE token_hash = $1 AND expires_at > NOW()
       RETURNING user_id`,
      [incomingHash]
    );

    const userId = tokenRes.rows.length > 0 ? tokenRes.rows[0].user_id : decoded.id;
    if (!userId) {
      return res.status(401).json({
        success: false,
        code: 'EXPIRED_REFRESH_TOKEN',
        message: 'Refresh token has expired or already been revoked',
      });
    }

    // Fetch user details
    const userRes = await query(
      `SELECT u.*, b.name AS branch_name
       FROM users u
       LEFT JOIN branches b ON u.branch_id = b.id
       WHERE u.id = $1 AND u.is_active = TRUE`,
      [userId]
    );

    if (userRes.rows.length === 0) {
      return res.status(401).json({
        success: false,
        message: 'User not found or account deactivated',
      });
    }

    const user = userRes.rows[0];
    const newTokens = await generateTokens(user);

    res.json({
      success: true,
      data: {
        ...newTokens,
        user: {
          id: user.id,
          name: user.name,
          email: user.email,
          phone: user.phone,
          role: user.role,
          permissionGroupId: user.permission_group_id,
          customPermissions: user.custom_permissions,
          branchId: user.branch_id,
          branchName: user.branch_name,
        },
      },
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/auth/logout
router.post('/logout', async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (refreshToken) {
      const incomingHash = hashToken(refreshToken);
      await query('DELETE FROM refresh_tokens WHERE token_hash = $1', [incomingHash]);
    }

    res.json({
      success: true,
      message: 'Logged out successfully',
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/auth/accounts — public terminal user list for login switch & staff directory
router.get('/accounts', async (req, res, next) => {
  try {
    const result = await query(
      `SELECT u.id, u.branch_id, u.name, u.email, u.phone, u.role,
              u.permission_group_id, u.custom_permissions, u.is_active,
              u.last_login_at, u.created_at, u.updated_at,
              b.name AS branch_name
       FROM users u
       LEFT JOIN branches b ON u.branch_id = b.id
       ORDER BY u.created_at ASC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/auth/me (Protected)
router.get('/me', authenticate, async (req, res, next) => {
  try {
    const userRes = await query(
      `SELECT u.id, u.branch_id, u.name, u.email, u.phone, u.role,
              u.permission_group_id, u.custom_permissions, u.is_active, u.last_login_at,
              b.name AS branch_name
       FROM users u
       LEFT JOIN branches b ON u.branch_id = b.id
       WHERE u.id = $1`,
      [req.user.id]
    );

    if (userRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({
      success: true,
      data: userRes.rows[0],
    });
  } catch (err) {
    next(err);
  }
});

export default router;

