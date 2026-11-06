import { Router } from 'express';
import { query } from '../config/db.js';
import { authenticate, requireDeletePermission } from '../middleware/auth.middleware.js';

const router = Router();

// GET /api/v1/branches — list all branches (supports ?includeInactive=true)
router.get('/branches', async (req, res, next) => {
  try {
    const { includeInactive } = req.query;
    const sql = (includeInactive === 'true' || includeInactive === '1')
      ? 'SELECT id, name, address, phone, is_active, created_at, updated_at FROM branches ORDER BY is_active DESC, name ASC'
      : 'SELECT id, name, address, phone, is_active, created_at, updated_at FROM branches WHERE is_active = TRUE ORDER BY name ASC';
    const result = await query(sql);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/branches — create a branch
router.post('/branches', async (req, res, next) => {
  try {
    const { name, address, phone, isActive = true } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: 'ဆိုင်ခွဲအမည် (Branch name) ထည့်သွင်းရန် လိုအပ်ပါသည်' });
    }

    const result = await query(
      `INSERT INTO branches (name, address, phone, is_active)
       VALUES ($1, $2, $3, $4)
       RETURNING id, name, address, phone, is_active, created_at, updated_at`,
      [name.trim(), address ? address.trim() : null, phone ? phone.trim() : null, isActive ?? true]
    );

    res.status(201).json({
      success: true,
      message: 'ဆိုင်ခွဲအသစ် ထည့်သွင်းပြီးပါပြီ',
      data: result.rows[0],
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/branches/:id — update a branch
router.patch('/branches/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, address, phone, isActive } = req.body;

    const existing = await query('SELECT * FROM branches WHERE id = $1', [id]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'ဆိုင်ခွဲ ရှာမတွေ့ပါ (Branch not found)' });
    }

    const current = existing.rows[0];
    const newName = name !== undefined ? name.trim() : current.name;
    const newAddress = address !== undefined ? (address ? address.trim() : null) : current.address;
    const newPhone = phone !== undefined ? (phone ? phone.trim() : null) : current.phone;
    const newActive = isActive !== undefined ? isActive : current.is_active;

    const result = await query(
      `UPDATE branches
       SET name = $1, address = $2, phone = $3, is_active = $4, updated_at = NOW()
       WHERE id = $5
       RETURNING id, name, address, phone, is_active, created_at, updated_at`,
      [newName, newAddress, newPhone, newActive, id]
    );

    res.json({
      success: true,
      message: 'ဆိုင်ခွဲ အချက်အလက်များ မွမ်းမံပြီးပါပြီ',
      data: result.rows[0],
    });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/branches/:id — delete or deactivate branch safely (requires delete permission)
router.delete('/branches/:id', authenticate, requireDeletePermission, async (req, res, next) => {
  try {
    const { id } = req.params;

    const existing = await query('SELECT id, name FROM branches WHERE id = $1', [id]);
    if (existing.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'ဆိုင်ခွဲ ရှာမတွေ့ပါ (Branch not found)' });
    }

    // Check if referenced in transactions or active stock
    const salesCheck = await query('SELECT 1 FROM sales WHERE branch_id = $1 LIMIT 1', [id]);
    const purchaseCheck = await query('SELECT 1 FROM purchases WHERE branch_id = $1 LIMIT 1', [id]);
    const stockCheck = await query('SELECT 1 FROM branch_inventories WHERE branch_id = $1 AND stock_quantity > 0 LIMIT 1', [id]);
    const empCheck = await query('SELECT 1 FROM employees WHERE branch_id = $1 LIMIT 1', [id]);
    const transferCheck = await query('SELECT 1 FROM branch_transfers WHERE from_branch_id = $1 OR to_branch_id = $1 LIMIT 1', [id]);
    const wastageCheck = await query('SELECT 1 FROM wastage_logs WHERE branch_id = $1 LIMIT 1', [id]);
    const payrollCheck = await query('SELECT 1 FROM payrolls WHERE branch_id = $1 LIMIT 1', [id]);
    const batchCheck = await query('SELECT 1 FROM product_batches WHERE branch_id = $1 LIMIT 1', [id]);

    const hasHistory = salesCheck.rows.length > 0 ||
                       purchaseCheck.rows.length > 0 ||
                       stockCheck.rows.length > 0 ||
                       empCheck.rows.length > 0 ||
                       transferCheck.rows.length > 0 ||
                       wastageCheck.rows.length > 0 ||
                       payrollCheck.rows.length > 0 ||
                       batchCheck.rows.length > 0;

    if (hasHistory) {
      // Soft-delete to preserve business integrity
      await query('UPDATE branches SET is_active = FALSE, updated_at = NOW() WHERE id = $1', [id]);
      return res.json({
        success: true,
        message: 'ဆိုင်ခွဲတွင် အရောင်းနှင့် စာရင်းမှတ်တမ်းများ ရှိနေသောကြောင့် စာရင်းများမပျက်စီးစေရန် ဆိုင်ခွဲကို ပိတ်သိမ်း (Deactivate) ထားလိုက်ပါပြီ။',
        deactivated: true,
      });
    } else {
      // Safe to hard delete: clean up empty branch_inventories records if any, unlink users, then delete branch
      await query('UPDATE users SET branch_id = NULL WHERE branch_id = $1', [id]);
      await query('DELETE FROM branch_inventories WHERE branch_id = $1', [id]);
      await query('DELETE FROM branches WHERE id = $1', [id]);
      return res.json({
        success: true,
        message: 'ဆိုင်ခွဲကို အပြီးအပိုင် ဖျက်သိမ်းပြီးပါပြီ။',
        deleted: true,
      });
    }
  } catch (err) {
    next(err);
  }
});

export default router;

