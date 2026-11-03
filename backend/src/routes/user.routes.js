import { Router } from 'express';
import bcrypt from 'bcryptjs';
import { pool, query, resolveBranchId } from '../config/db.js';
import { authenticate, requireRole } from '../middleware/auth.middleware.js';

const router = Router();

// ============================================================
// Permission Groups Routes (/api/v1/permission-groups)
// ============================================================

router.get('/permission-groups', async (req, res, next) => {
  try {
    const result = await query(
      `SELECT id, name, burmese_name, description, icon, permissions, is_built_in, sort_order
       FROM permission_groups
       ORDER BY sort_order ASC, created_at ASC`
    );
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

router.post(
  '/permission-groups',
  authenticate,
  requireRole('owner', 'manager'),
  async (req, res, next) => {
    try {
      const {
        id,
        name,
        burmeseName = '',
        description = '',
        icon = '🛡️',
        permissions = [],
      } = req.body;
      if (!name || !String(name).trim()) {
        return res.status(400).json({ success: false, message: 'Group name is required' });
      }
      const groupId = id && String(id).trim() ? String(id).trim() : `pg_${Date.now()}`;
      const result = await query(
        `INSERT INTO permission_groups (id, name, burmese_name, description, icon, permissions, is_built_in, sort_order)
         VALUES ($1, $2, $3, $4, $5, $6::jsonb, FALSE, 99)
         RETURNING *`,
        [
          groupId,
          String(name).trim(),
          String(burmeseName).trim(),
          String(description).trim(),
          String(icon).trim() || '🛡️',
          JSON.stringify(Array.isArray(permissions) ? permissions : []),
        ]
      );
      res.status(201).json({ success: true, data: result.rows[0] });
    } catch (err) {
      next(err);
    }
  }
);

router.patch(
  '/permission-groups/:id',
  authenticate,
  requireRole('owner', 'manager'),
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const { name, burmeseName, description, icon, permissions } = req.body;
      const fields = [];
      const values = [];
      if (name !== undefined) {
        values.push(String(name).trim());
        fields.push(`name = $${values.length}`);
      }
      if (burmeseName !== undefined) {
        values.push(String(burmeseName).trim());
        fields.push(`burmese_name = $${values.length}`);
      }
      if (description !== undefined) {
        values.push(String(description).trim());
        fields.push(`description = $${values.length}`);
      }
      if (icon !== undefined) {
        values.push(String(icon).trim() || '🛡️');
        fields.push(`icon = $${values.length}`);
      }
      if (permissions !== undefined) {
        values.push(JSON.stringify(Array.isArray(permissions) ? permissions : []));
        fields.push(`permissions = $${values.length}::jsonb`);
      }
      if (fields.length === 0) {
        return res.status(400).json({ success: false, message: 'No fields provided' });
      }
      values.push(id);
      const result = await query(
        `UPDATE permission_groups
         SET ${fields.join(', ')}, updated_at = NOW()
         WHERE id = $${values.length}
         RETURNING *`,
        values
      );
      if (result.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Permission group not found' });
      }
      res.json({ success: true, data: result.rows[0] });
    } catch (err) {
      next(err);
    }
  }
);

router.delete(
  '/permission-groups/:id',
  authenticate,
  requireRole('owner', 'manager'),
  async (req, res, next) => {
    try {
      const { id } = req.params;
      const checkRes = await query('SELECT is_built_in, name FROM permission_groups WHERE id = $1', [id]);
      if (checkRes.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'Permission group not found' });
      }
      if (checkRes.rows[0].is_built_in) {
        return res.status(400).json({
          success: false,
          message: `Cannot delete built-in permission group (${checkRes.rows[0].name})`,
        });
      }
      await query('DELETE FROM permission_groups WHERE id = $1', [id]);
      res.json({ success: true, message: 'Permission group deleted successfully' });
    } catch (err) {
      next(err);
    }
  }
);

router.post(
  '/permission-groups/reset',
  authenticate,
  requireRole('owner', 'manager'),
  async (req, res, next) => {
    try {
      await query('DELETE FROM permission_groups WHERE is_built_in = FALSE');
      const result = await query(
        `SELECT id, name, burmese_name, description, icon, permissions, is_built_in, sort_order
         FROM permission_groups
         ORDER BY sort_order ASC, created_at ASC`
      );
      res.json({ success: true, data: result.rows });
    } catch (err) {
      next(err);
    }
  }
);

// Protect all user management routes with authentication
router.use('/users', authenticate);

// GET /api/v1/users — list users
router.get('/users', async (req, res, next) => {
  try {
    const { branchId, role, search, isActive } = req.query;
    const targetBranchId = await resolveBranchId(branchId);

    let sql = `
      SELECT u.id, u.branch_id, u.name, u.email, u.phone, u.role,
             u.permission_group_id, u.custom_permissions, u.is_active,
             u.last_login_at, u.created_at, u.updated_at,
             b.name AS branch_name
      FROM users u
      LEFT JOIN branches b ON u.branch_id = b.id
      WHERE 1=1
    `;

    const params = [];

    if (targetBranchId) {
      params.push(targetBranchId);
      sql += ` AND u.branch_id = $${params.length}`;
    }

    if (role) {
      params.push(role);
      sql += ` AND u.role = $${params.length}::user_role`;
    }

    if (isActive !== undefined) {
      params.push(isActive === 'true');
      sql += ` AND u.is_active = $${params.length}`;
    }

    if (search) {
      params.push(`%${search}%`);
      sql += ` AND (u.name ILIKE $${params.length} OR u.email ILIKE $${params.length} OR u.phone ILIKE $${params.length})`;
    }

    sql += ' ORDER BY u.created_at DESC';

    const result = await query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/users/:id
router.get('/users/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `SELECT u.id, u.branch_id, u.name, u.email, u.phone, u.role,
              u.permission_group_id, u.custom_permissions, u.is_active,
              u.last_login_at, u.created_at, u.updated_at,
              b.name AS branch_name
       FROM users u
       LEFT JOIN branches b ON u.branch_id = b.id
       WHERE u.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/users — create user (owner only)
router.post('/users', requireRole('owner'), async (req, res, next) => {
  try {
    const {
      name,
      email,
      phone,
      password,
      role = 'cashier',
      permissionGroupId,
      customPermissions,
      branchId,
      isActive = true,
    } = req.body;

    if (!name || !password) {
      return res.status(400).json({
        success: false,
        message: 'Name and password are required',
      });
    }

    if (email) {
      const existing = await query('SELECT id FROM users WHERE email = $1', [email.trim().toLowerCase()]);
      if (existing.rows.length > 0) {
        return res.status(409).json({
          success: false,
          message: 'A user with this email already exists',
        });
      }
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password, salt);

    const defaultGroupId =
      permissionGroupId ||
      (role === 'owner'
        ? 'pg_owner'
        : role === 'manager'
        ? 'pg_manager'
        : role === 'stock_clerk'
        ? 'pg_stock'
        : 'pg_cashier');

    const insertSql = `
      INSERT INTO users (name, email, phone, password_hash, role, permission_group_id, custom_permissions, branch_id, is_active)
      VALUES ($1, $2, $3, $4, $5::user_role, $6, $7::jsonb, $8, $9)
      RETURNING id, branch_id, name, email, phone, role, permission_group_id, custom_permissions, is_active, created_at
    `;

    const resolvedBranchId = branchId ? await resolveBranchId(branchId) : null;

    const result = await query(insertSql, [
      name.trim(),
      email ? email.trim().toLowerCase() : null,
      phone ? phone.trim() : null,
      passwordHash,
      role,
      defaultGroupId,
      Array.isArray(customPermissions) ? JSON.stringify(customPermissions) : null,
      resolvedBranchId,
      Boolean(isActive),
    ]);

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'User created successfully',
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/users/:id — update user profile / role / branch / permissions (owner only)
router.patch('/users/:id', requireRole('owner'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const {
      name,
      email,
      phone,
      password,
      role,
      permissionGroupId,
      customPermissions,
      branchId,
      isActive,
    } = req.body;

    const fields = [];
    const values = [];

    if (name !== undefined) {
      values.push(name.trim());
      fields.push(`name = $${values.length}`);
    }

    if (email !== undefined) {
      values.push(email ? email.trim().toLowerCase() : null);
      fields.push(`email = $${values.length}`);
    }

    if (phone !== undefined) {
      values.push(phone ? phone.trim() : null);
      fields.push(`phone = $${values.length}`);
    }

    if (password !== undefined && String(password).trim().length >= 4) {
      const salt = await bcrypt.genSalt(10);
      const passwordHash = await bcrypt.hash(String(password).trim(), salt);
      values.push(passwordHash);
      fields.push(`password_hash = $${values.length}`);
    }

    if (role !== undefined) {
      values.push(role);
      fields.push(`role = $${values.length}::user_role`);
    }

    if (permissionGroupId !== undefined) {
      values.push(permissionGroupId || null);
      fields.push(`permission_group_id = $${values.length}`);
    }

    if (customPermissions !== undefined) {
      values.push(
        Array.isArray(customPermissions) ? JSON.stringify(customPermissions) : null
      );
      fields.push(`custom_permissions = $${values.length}::jsonb`);
    }

    if (branchId !== undefined) {
      const resolvedBranchId = branchId ? await resolveBranchId(branchId) : null;
      values.push(resolvedBranchId);
      fields.push(`branch_id = $${values.length}`);
    }

    if (isActive !== undefined) {
      values.push(Boolean(isActive));
      fields.push(`is_active = $${values.length}`);
    }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields provided for update' });
    }

    values.push(id);
    const updateSql = `
      UPDATE users
      SET ${fields.join(', ')}, updated_at = NOW()
      WHERE id = $${values.length}
      RETURNING id, branch_id, name, email, phone, role, permission_group_id, custom_permissions, is_active, updated_at
    `;

    const result = await query(updateSql, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    res.json({
      success: true,
      data: result.rows[0],
      message: 'User updated successfully',
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/users/:id/password — reset or change password
router.patch('/users/:id/password', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { oldPassword, newPassword } = req.body;

    if (!newPassword || newPassword.length < 6) {
      return res.status(400).json({
        success: false,
        message: 'New password must be at least 6 characters long',
      });
    }

    // Owner can reset anyone's password without oldPassword; regular users must verify oldPassword
    const isOwner = req.user.role === 'owner';
    const isSelf = req.user.id === id;

    if (!isOwner && !isSelf) {
      return res.status(403).json({
        success: false,
        message: 'You can only change your own password',
      });
    }

    if (!isOwner && isSelf) {
      if (!oldPassword) {
        return res.status(400).json({
          success: false,
          message: 'Current password is required',
        });
      }
      const userRes = await query('SELECT password_hash FROM users WHERE id = $1', [id]);
      if (userRes.rows.length === 0) {
        return res.status(404).json({ success: false, message: 'User not found' });
      }
      const matches = await bcrypt.compare(oldPassword, userRes.rows[0].password_hash);
      if (!matches) {
        return res.status(400).json({ success: false, message: 'Current password does not match' });
      }
    }

    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(newPassword, salt);

    await query('UPDATE users SET password_hash = $1, updated_at = NOW() WHERE id = $2', [passwordHash, id]);

    // Invalidate any active refresh tokens for this user
    await query('DELETE FROM refresh_tokens WHERE user_id = $1', [id]);

    res.json({
      success: true,
      message: 'Password updated successfully. Please log in again.',
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/users/:id/toggle — activate/deactivate user (owner only)
router.patch('/users/:id/toggle', requireRole('owner'), async (req, res, next) => {
  try {
    const { id } = req.params;

    if (id === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'You cannot deactivate your own account',
      });
    }

    const result = await query(
      `UPDATE users
       SET is_active = NOT is_active, updated_at = NOW()
       WHERE id = $1
       RETURNING id, name, is_active`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    const updatedUser = result.rows[0];
    if (!updatedUser.is_active) {
      // Deactivate all active refresh tokens
      await query('DELETE FROM refresh_tokens WHERE user_id = $1', [id]);
    }

    res.json({
      success: true,
      data: updatedUser,
      message: `User ${updatedUser.name} is now ${updatedUser.is_active ? 'active' : 'inactive'}`,
    });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/users/:id — delete user account (owner only)
router.delete('/users/:id', requireRole('owner'), async (req, res, next) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;

    if (id === req.user.id) {
      return res.status(400).json({
        success: false,
        message: 'You cannot delete your own active account',
      });
    }

    await client.query('BEGIN');
    await client.query('DELETE FROM refresh_tokens WHERE user_id = $1', [id]);
    await client.query('UPDATE sales SET cashier_id = NULL WHERE cashier_id = $1', [id]).catch(() => {});
    await client.query('UPDATE wastage_logs SET logged_by = NULL WHERE logged_by = $1', [id]).catch(() => {});
    await client.query('UPDATE stock_transfers SET initiated_by = NULL WHERE initiated_by = $1', [id]).catch(() => {});
    await client.query('UPDATE stock_transfers SET received_by = NULL WHERE received_by = $1', [id]).catch(() => {});

    const result = await client.query(
      'DELETE FROM users WHERE id = $1 RETURNING id, name, email',
      [id]
    );

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, message: 'User not found' });
    }

    await client.query('COMMIT');
    res.json({
      success: true,
      data: result.rows[0],
      message: `User ${result.rows[0].name} deleted successfully`,
    });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});

export default router;

