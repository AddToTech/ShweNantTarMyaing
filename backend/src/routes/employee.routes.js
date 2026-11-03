import { Router } from 'express';
import { query, resolveBranchId } from '../config/db.js';
import { authenticate, requireRole, requireDeletePermission } from '../middleware/auth.middleware.js';

const router = Router();

// Protect all employee routes
router.use('/employees', authenticate);

// GET /api/v1/employees — list employees
router.get('/employees', async (req, res, next) => {
  try {
    const { branchId, isActive, role, search } = req.query;
    const targetBranchId = await resolveBranchId(branchId);

    let sql = `
      SELECT e.*, b.name AS branch_name
      FROM employees e
      LEFT JOIN branches b ON e.branch_id = b.id
      WHERE 1=1
    `;

    const params = [];

    if (targetBranchId) {
      params.push(targetBranchId);
      sql += ` AND e.branch_id = $${params.length}`;
    }

    if (isActive !== undefined) {
      params.push(isActive === 'true');
      sql += ` AND e.is_active = $${params.length}`;
    }

    if (role) {
      params.push(role);
      sql += ` AND e.role ILIKE $${params.length}`;
    }

    if (search) {
      params.push(`%${search}%`);
      sql += ` AND (e.name ILIKE $${params.length} OR e.phone ILIKE $${params.length} OR e.role ILIKE $${params.length})`;
    }

    sql += ' ORDER BY e.name ASC';

    const result = await query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/employees/:id — get single employee
router.get('/employees/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `SELECT e.*, b.name AS branch_name
       FROM employees e
       LEFT JOIN branches b ON e.branch_id = b.id
       WHERE e.id = $1`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/employees — create employee (owner, manager)
router.post('/employees', requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const {
      branchId,
      name,
      role,
      phone,
      address,
      basicSalary = 0,
      joinDate,
      isActive = true,
    } = req.body;

    const targetBranchId = await resolveBranchId(branchId);
    if (!name || !role || !targetBranchId) {
      return res.status(400).json({
        success: false,
        message: 'name, role, and branchId are required',
      });
    }

    const insertSql = `
      INSERT INTO employees (
        branch_id, name, role, phone, address, basic_salary, join_date, is_active
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
      RETURNING *
    `;

    const result = await query(insertSql, [
      targetBranchId,
      name.trim(),
      role.trim(),
      phone ? phone.trim() : null,
      address ? address.trim() : null,
      Number(basicSalary) || 0,
      joinDate ? new Date(joinDate) : new Date(),
      Boolean(isActive),
    ]);

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Employee created successfully',
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/employees/:id — update employee
router.patch('/employees/:id', requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { branchId, name, role, phone, address, basicSalary, joinDate, isActive } = req.body;

    const fields = [];
    const values = [];

    if (branchId !== undefined) {
      const targetBranchId = await resolveBranchId(branchId);
      if (targetBranchId) {
        values.push(targetBranchId);
        fields.push(`branch_id = $${values.length}`);
      }
    }
    if (name !== undefined) {
      values.push(name.trim());
      fields.push(`name = $${values.length}`);
    }
    if (role !== undefined) {
      values.push(role.trim());
      fields.push(`role = $${values.length}`);
    }
    if (phone !== undefined) {
      values.push(phone ? phone.trim() : null);
      fields.push(`phone = $${values.length}`);
    }
    if (address !== undefined) {
      values.push(address ? address.trim() : null);
      fields.push(`address = $${values.length}`);
    }
    if (basicSalary !== undefined) {
      values.push(Number(basicSalary) || 0);
      fields.push(`basic_salary = $${values.length}`);
    }
    if (joinDate !== undefined) {
      values.push(new Date(joinDate));
      fields.push(`join_date = $${values.length}`);
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
      UPDATE employees
      SET ${fields.join(', ')}, updated_at = NOW()
      WHERE id = $${values.length}
      RETURNING *
    `;

    const result = await query(updateSql, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }

    res.json({
      success: true,
      data: result.rows[0],
      message: 'Employee updated successfully',
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/employees/:id/toggle — toggle employee active status
router.patch('/employees/:id/toggle', requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      'UPDATE employees SET is_active = NOT is_active, updated_at = NOW() WHERE id = $1 RETURNING id, name, is_active',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }

    res.json({
      success: true,
      data: result.rows[0],
      message: `Employee '${result.rows[0].name}' status changed to ${result.rows[0].is_active ? 'active' : 'inactive'}`,
    });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/employees/:id — soft delete (requires delete permission)
router.delete('/employees/:id', requireDeletePermission, async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      'UPDATE employees SET is_active = FALSE, updated_at = NOW() WHERE id = $1 RETURNING id, name',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Employee not found' });
    }

    res.json({
      success: true,
      message: `Employee '${result.rows[0].name}' deactivated`,
    });
  } catch (err) {
    next(err);
  }
});

export default router;

