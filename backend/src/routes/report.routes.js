import { Router } from 'express';
import { query } from '../config/db.js';
import { authenticate, requireRole } from '../middleware/auth.middleware.js';

const router = Router();

// Protect all report routes
router.use('/reports', authenticate, requireRole('owner', 'manager'));

// GET /api/v1/reports/sales-summary
router.get('/reports/sales-summary', async (req, res, next) => {
  try {
    const { branchId, startDate, endDate } = req.query;

    let sql = `
      SELECT 
        COUNT(id) AS total_transactions,
        COALESCE(SUM(subtotal), 0) AS total_subtotal,
        COALESCE(SUM(discount_amount), 0) AS total_discount,
        COALESCE(SUM(tax_amount), 0) AS total_tax,
        COALESCE(SUM(total_amount), 0) AS total_sales,
        COALESCE(SUM(total_amount) FILTER (WHERE payment_method = 'cash'), 0) AS cash_sales,
        COALESCE(SUM(total_amount) FILTER (WHERE payment_method = 'kpay'), 0) AS kpay_sales,
        COALESCE(SUM(total_amount) FILTER (WHERE payment_method = 'banking'), 0) AS banking_sales,
        COALESCE(SUM(total_amount) FILTER (WHERE payment_method = 'credit'), 0) AS credit_sales
      FROM sales
      WHERE status = 'completed'
    `;

    const params = [];

    if (branchId) {
      params.push(branchId);
      sql += ` AND branch_id = $${params.length}`;
    }

    if (startDate) {
      params.push(startDate);
      sql += ` AND sold_at >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      sql += ` AND sold_at <= $${params.length}`;
    }

    const summaryRes = await query(sql, params);

    // Top selling products in this period
    let topProdSql = `
      SELECT si.product_id, si.product_name,
             SUM(si.quantity) AS total_quantity,
             SUM(si.line_total) AS total_revenue
      FROM sale_items si
      JOIN sales s ON si.sale_id = s.id
      WHERE s.status = 'completed'
    `;
    const topProdParams = [];

    if (branchId) {
      topProdParams.push(branchId);
      topProdSql += ` AND s.branch_id = $${topProdParams.length}`;
    }
    if (startDate) {
      topProdParams.push(startDate);
      topProdSql += ` AND s.sold_at >= $${topProdParams.length}`;
    }
    if (endDate) {
      topProdParams.push(endDate);
      topProdSql += ` AND s.sold_at <= $${topProdParams.length}`;
    }

    topProdSql += ' GROUP BY si.product_id, si.product_name ORDER BY total_revenue DESC LIMIT 10';
    const topProdRes = await query(topProdSql, topProdParams);

    res.json({
      success: true,
      data: {
        summary: summaryRes.rows[0],
        topProducts: topProdRes.rows,
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/reports/purchases — အဝယ်စာရင်း အစီရင်ခံစာ (Purchases & Stock-in report)
router.get('/reports/purchases', async (req, res, next) => {
  try {
    const { branchId, vendorId, startDate, endDate } = req.query;

    let sql = `
      SELECT 
        COUNT(p.id) AS total_purchases,
        COALESCE(SUM(p.subtotal), 0) AS total_subtotal,
        COALESCE(SUM(p.discount), 0) AS total_discount,
        COALESCE(SUM(p.total_amount), 0) AS total_purchase_amount,
        COALESCE(SUM(p.paid_amount), 0) AS total_paid_amount,
        COALESCE(SUM(p.balance_due), 0) AS total_outstanding_payables
      FROM purchases p
      WHERE 1=1
    `;

    const params = [];

    if (branchId) {
      params.push(branchId);
      sql += ` AND p.branch_id = $${params.length}`;
    }

    if (vendorId) {
      params.push(vendorId);
      sql += ` AND p.vendor_id = $${params.length}`;
    }

    if (startDate) {
      params.push(startDate);
      sql += ` AND p.purchase_date >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      sql += ` AND p.purchase_date <= $${params.length}`;
    }

    const summaryRes = await query(sql, params);

    // Vendor breakdown
    let vendorBreakdownSql = `
      SELECT v.id AS vendor_id, v.name AS vendor_name,
             COUNT(p.id) AS purchase_count,
             COALESCE(SUM(p.total_amount), 0) AS total_amount,
             COALESCE(SUM(p.paid_amount), 0) AS paid_amount,
             COALESCE(SUM(p.balance_due), 0) AS balance_due
      FROM purchases p
      LEFT JOIN vendors v ON p.vendor_id = v.id
      WHERE 1=1
    `;
    const vendorParams = [];
    if (branchId) {
      vendorParams.push(branchId);
      vendorBreakdownSql += ` AND p.branch_id = $${vendorParams.length}`;
    }
    if (startDate) {
      vendorParams.push(startDate);
      vendorBreakdownSql += ` AND p.purchase_date >= $${vendorParams.length}`;
    }
    if (endDate) {
      vendorParams.push(endDate);
      vendorBreakdownSql += ` AND p.purchase_date <= $${vendorParams.length}`;
    }
    vendorBreakdownSql += ' GROUP BY v.id, v.name ORDER BY total_amount DESC';
    const vendorRes = await query(vendorBreakdownSql, vendorParams);

    res.json({
      success: true,
      data: {
        summary: summaryRes.rows[0],
        vendorBreakdown: vendorRes.rows,
      },
    });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/reports/expenses — Operating Expenses (OPEX: Payroll + Wastage)
router.get('/reports/expenses', async (req, res, next) => {
  try {
    const { branchId, startDate, endDate, period } = req.query;

    // 1. Payroll expenses
    let payrollSql = `
      SELECT 
        COUNT(id) AS payroll_count,
        COALESCE(SUM(basic_salary), 0) AS basic_salary_total,
        COALESCE(SUM(bonus_amount), 0) AS bonus_total,
        COALESCE(SUM(deduction_amount), 0) AS deduction_total,
        COALESCE(SUM(net_salary), 0) AS total_salaries_paid
      FROM payrolls
      WHERE 1=1
    `;
    const payrollParams = [];
    if (branchId) {
      payrollParams.push(branchId);
      payrollSql += ` AND branch_id = $${payrollParams.length}`;
    }
    if (period) {
      payrollParams.push(period);
      payrollSql += ` AND payroll_period = $${payrollParams.length}`;
    }
    if (startDate) {
      payrollParams.push(startDate);
      payrollSql += ` AND payment_date >= $${payrollParams.length}`;
    }
    if (endDate) {
      payrollParams.push(endDate);
      payrollSql += ` AND payment_date <= $${payrollParams.length}`;
    }
    const payrollRes = await query(payrollSql, payrollParams);

    // 2. Wastage expenses
    let wastageSql = `
      SELECT 
        COUNT(id) AS wastage_count,
        COALESCE(SUM(quantity), 0) AS total_items_wasted,
        COALESCE(SUM(cost_impact), 0) AS total_wastage_cost
      FROM wastage_logs
      WHERE 1=1
    `;
    const wastageParams = [];
    if (branchId) {
      wastageParams.push(branchId);
      wastageSql += ` AND branch_id = $${wastageParams.length}`;
    }
    if (startDate) {
      wastageParams.push(startDate);
      wastageSql += ` AND recorded_at >= $${wastageParams.length}`;
    }
    if (endDate) {
      wastageParams.push(endDate);
      wastageSql += ` AND recorded_at <= $${wastageParams.length}`;
    }
    const wastageRes = await query(wastageSql, wastageParams);

    const salariesPaid = Number(payrollRes.rows[0].total_salaries_paid) || 0;
    const wastageCost = Number(wastageRes.rows[0].total_wastage_cost) || 0;
    const totalOpex = salariesPaid + wastageCost;

    res.json({
      success: true,
      data: {
        totalOpex,
        payroll: {
          ...payrollRes.rows[0],
          total_salaries_paid: salariesPaid,
        },
        wastage: {
          ...wastageRes.rows[0],
          total_wastage_cost: wastageCost,
        },
      },
    });
  } catch (err) {
    next(err);
  }
});

export default router;

