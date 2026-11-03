import { Router } from 'express';
import { query, resolveBranchId } from '../config/db.js';
import { authenticate, requireRole } from '../middleware/auth.middleware.js';

const router = Router();

// Protect all payroll routes
router.use('/payrolls', authenticate);

// GET /api/v1/payrolls — list payroll records
router.get('/payrolls', async (req, res, next) => {
  try {
    const { branchId, payrollPeriod, employeeId, startDate, endDate, search } = req.query;
    const targetBranchId = await resolveBranchId(branchId);

    let sql = `
      SELECT p.*,
             e.name AS employee_name,
             e.role AS employee_role,
             e.phone AS employee_phone,
             b.name AS branch_name,
             u.name AS paid_by_name
      FROM payrolls p
      JOIN employees e ON p.employee_id = e.id
      JOIN branches b ON p.branch_id = b.id
      LEFT JOIN users u ON p.paid_by = u.id
      WHERE 1=1
    `;

    const params = [];

    if (targetBranchId) {
      params.push(targetBranchId);
      sql += ` AND p.branch_id = $${params.length}`;
    }

    if (payrollPeriod) {
      params.push(payrollPeriod);
      sql += ` AND p.payroll_period = $${params.length}`;
    }

    if (employeeId) {
      params.push(employeeId);
      sql += ` AND p.employee_id = $${params.length}`;
    }

    if (startDate) {
      params.push(startDate);
      sql += ` AND p.payment_date >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      sql += ` AND p.payment_date <= $${params.length}`;
    }

    if (search) {
      params.push(`%${search}%`);
      sql += ` AND (e.name ILIKE $${params.length} OR e.phone ILIKE $${params.length})`;
    }

    sql += ' ORDER BY p.payment_date DESC, p.created_at DESC';

    const result = await query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/payrolls/summary — get payroll expenditure aggregated by branch and period
router.get('/payrolls/summary', requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { branchId, payrollPeriod } = req.query;

    let sql = `
      SELECT 
        p.branch_id,
        b.name AS branch_name,
        p.payroll_period,
        COUNT(p.id) AS total_disbursements,
        COALESCE(SUM(p.basic_salary), 0) AS total_basic_salary,
        COALESCE(SUM(p.bonus_amount), 0) AS total_bonuses,
        COALESCE(SUM(p.deduction_amount), 0) AS total_deductions,
        COALESCE(SUM(p.net_salary), 0) AS total_net_salary
      FROM payrolls p
      JOIN branches b ON p.branch_id = b.id
      WHERE 1=1
    `;

    const params = [];
    const targetBranchId = await resolveBranchId(branchId);

    if (targetBranchId) {
      params.push(targetBranchId);
      sql += ` AND p.branch_id = $${params.length}`;
    }

    if (payrollPeriod) {
      params.push(payrollPeriod);
      sql += ` AND p.payroll_period = $${params.length}`;
    }

    sql += ' GROUP BY p.branch_id, b.name, p.payroll_period ORDER BY p.payroll_period DESC, b.name ASC';

    const result = await query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/payrolls/:id — get single payroll detail
router.get('/payrolls/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const sql = `
      SELECT p.*,
             e.name AS employee_name,
             e.role AS employee_role,
             e.phone AS employee_phone,
             e.address AS employee_address,
             b.name AS branch_name,
             u.name AS paid_by_name
      FROM payrolls p
      JOIN employees e ON p.employee_id = e.id
      JOIN branches b ON p.branch_id = b.id
      LEFT JOIN users u ON p.paid_by = u.id
      WHERE p.id = $1
    `;
    const result = await query(sql, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Payroll record not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/payrolls — disburse salary
router.post('/payrolls', requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const {
      employeeId,
      branchId,
      payrollPeriod, // e.g. "2026-10"
      basicSalary = 0,
      bonusAmount = 0,
      bonusDescription,
      deductionAmount = 0,
      deductionDescription,
      paymentMethod = 'cash',
      paymentDate,
      notes,
    } = req.body;

    const targetBranchId = await resolveBranchId(branchId);
    if (!employeeId || !targetBranchId || !payrollPeriod) {
      return res.status(400).json({
        success: false,
        message: 'employeeId, branchId, and payrollPeriod are required',
      });
    }

    const insertSql = `
      INSERT INTO payrolls (
        employee_id, branch_id, payroll_period, basic_salary,
        bonus_amount, bonus_description, deduction_amount, deduction_description,
        payment_method, payment_date, paid_by, notes
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::payment_method, $10, $11, $12)
      RETURNING *
    `;

    const result = await query(insertSql, [
      employeeId,
      targetBranchId,
      payrollPeriod,
      Number(basicSalary) || 0,
      Number(bonusAmount) || 0,
      bonusDescription || null,
      Number(deductionAmount) || 0,
      deductionDescription || null,
      paymentMethod,
      paymentDate ? new Date(paymentDate) : new Date(),
      req.user.id,
      notes || null,
    ]);

    // Fetch joined record with employee & branch name
    const detailRes = await query(
      `SELECT p.*, e.name AS employee_name, e.role AS employee_role, b.name AS branch_name
       FROM payrolls p
       JOIN employees e ON p.employee_id = e.id
       JOIN branches b ON p.branch_id = b.id
       WHERE p.id = $1`,
      [result.rows[0].id]
    );

    res.status(201).json({
      success: true,
      data: detailRes.rows[0],
      message: 'Salary disbursed successfully',
    });
  } catch (err) {
    next(err);
  }
});

export default router;

