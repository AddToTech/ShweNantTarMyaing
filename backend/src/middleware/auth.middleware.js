import jwt from 'jsonwebtoken';
import { query } from '../config/db.js';

const JWT_SECRET = process.env.JWT_SECRET || 'sitepyoe_jwt_super_secret_key_change_in_production';

/**
 * Verifies JWT Access Token from Authorization: Bearer <token> header.
 * Attaches decoded user payload and database status to req.user.
 */
export const authenticate = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        success: false,
        message: 'Authentication token required (Bearer)',
      });
    }

    const token = authHeader.split(' ')[1];
    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Invalid authorization format',
      });
    }

    let decoded;
    try {
      decoded = jwt.verify(token, JWT_SECRET);
    } catch (err) {
      if (err.name === 'TokenExpiredError') {
        return res.status(401).json({
          success: false,
          code: 'TOKEN_EXPIRED',
          message: 'Access token has expired',
        });
      }
      return res.status(401).json({
        success: false,
        code: 'TOKEN_INVALID',
        message: 'Invalid access token',
      });
    }

    // Verify user is still active in database
    const userRes = await query(
      'SELECT id, branch_id, name, email, phone, role, is_active, permission_group_id, custom_permissions FROM users WHERE id = $1',
      [decoded.id]
    );

    if (userRes.rows.length === 0 || !userRes.rows[0].is_active) {
      return res.status(401).json({
        success: false,
        code: 'USER_INACTIVE',
        message: 'User account not found or has been deactivated',
      });
    }

    const dbUser = userRes.rows[0];
    req.user = {
      id: dbUser.id,
      name: dbUser.name,
      email: dbUser.email,
      phone: dbUser.phone,
      role: dbUser.role,
      branchId: dbUser.branch_id,
      permissionGroupId: dbUser.permission_group_id,
      customPermissions: dbUser.custom_permissions,
    };

    next();
  } catch (err) {
    next(err);
  }
};

/**
 * Optional authentication: attaches req.user if a valid token is provided,
 * otherwise proceeds as unauthenticated without throwing 401.
 */
export const optionalAuth = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return next();
    }

    const token = authHeader.split(' ')[1];
    if (!token) return next();

    try {
      const decoded = jwt.verify(token, JWT_SECRET);
      const userRes = await query(
        'SELECT id, branch_id, name, email, phone, role, is_active, permission_group_id, custom_permissions FROM users WHERE id = $1',
        [decoded.id]
      );
      if (userRes.rows.length > 0 && userRes.rows[0].is_active) {
        const dbUser = userRes.rows[0];
        req.user = {
          id: dbUser.id,
          name: dbUser.name,
          email: dbUser.email,
          phone: dbUser.phone,
          role: dbUser.role,
          branchId: dbUser.branch_id,
          permissionGroupId: dbUser.permission_group_id,
          customPermissions: dbUser.custom_permissions,
        };
      }
    } catch {
      // Ignore token errors in optionalAuth
    }

    next();
  } catch (err) {
    next(err);
  }
};

/**
 * Role-based authorization middleware.
 * Usage: requireRole('owner', 'manager')
 */
export const requireRole = (...allowedRoles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
      });
    }

    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Forbidden: role '${req.user.role}' does not have sufficient permission`,
      });
    }

    next();
  };
};

/**
 * Delete permission authorization middleware.
 * - Super Admin / Owner unconditionally has delete access.
 * - Staff members require dynamic 'delete_data' permission either via
 *   custom_permissions or via their assigned permission group.
 */
export const requireDeletePermission = async (req, res, next) => {
  try {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required',
      });
    }

    // 1. Super Admin / Owner always has unconditional delete access
    if (req.user.role === 'owner') {
      return next();
    }

    // 2. Check user's custom_permissions override
    let customPerms = req.user.customPermissions;
    if (typeof customPerms === 'string') {
      try {
        customPerms = JSON.parse(customPerms);
      } catch {
        customPerms = [];
      }
    }
    if (Array.isArray(customPerms)) {
      if (customPerms.includes('delete_data')) {
        return next();
      }
    }

    // 3. Check user's assigned permission group
    if (req.user.permissionGroupId) {
      const groupRes = await query(
        'SELECT permissions FROM permission_groups WHERE id = $1',
        [req.user.permissionGroupId]
      );
      if (groupRes.rows.length > 0) {
        let groupPerms = groupRes.rows[0].permissions;
        if (typeof groupPerms === 'string') {
          try {
            groupPerms = JSON.parse(groupPerms);
          } catch {
            groupPerms = [];
          }
        }
        if (Array.isArray(groupPerms) && groupPerms.includes('delete_data')) {
          return next();
        }
      }
    }

    return res.status(403).json({
      success: false,
      code: 'PERMISSION_DENIED',
      message: 'ဒေတာနှင့် မှတ်တမ်းများ ပယ်ဖျက်ခွင့် (Delete Permission) မရှိပါ။ Super Admin ထံ ခွင့်ပြုချက်တောင်းခံပါ။',
    });
  } catch (err) {
    next(err);
  }
};

