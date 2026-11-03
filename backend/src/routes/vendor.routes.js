import { Router } from 'express';
import { query } from '../config/db.js';
import { authenticate, requireRole } from '../middleware/auth.middleware.js';

const router = Router();

// Protect all vendor routes
router.use('/vendors', authenticate);

// GET /api/v1/vendors — list vendors
router.get('/vendors', async (req, res, next) => {
  try {
    const { search, isActive } = req.query;

    let sql = `
      SELECT v.*,
             COUNT(p.id) AS purchase_count,
             COALESCE(SUM(p.balance_due) FILTER (WHERE p.payment_status IN ('unpaid', 'partial')), 0) AS outstanding_balance
      FROM vendors v
      LEFT JOIN purchases p ON p.vendor_id = v.id
      WHERE 1=1
    `;

    const params = [];

    if (isActive !== undefined) {
      params.push(isActive === 'true');
      sql += ` AND v.is_active = $${params.length}`;
    }

    if (search) {
      params.push(`%${search}%`);
      sql += ` AND (v.name ILIKE $${params.length} OR v.phone ILIKE $${params.length} OR v.address ILIKE $${params.length})`;
    }

    sql += ' GROUP BY v.id ORDER BY v.name ASC';

    const result = await query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/vendors/payables — view outstanding payables summary
router.get('/vendors/payables', requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const sql = `
      SELECT * FROM vendor_outstanding_payables
      WHERE total_outstanding > 0
      ORDER BY total_outstanding DESC
    `;
    const result = await query(sql);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/vendors/:id — get vendor details
router.get('/vendors/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query('SELECT * FROM vendors WHERE id = $1', [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Vendor not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/vendors — create vendor (owner/manager)
router.post('/vendors', requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { name, phone, address, notes } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: 'Vendor name is required' });
    }

    const insertSql = `
      INSERT INTO vendors (name, phone, address, notes)
      VALUES ($1, $2, $3, $4)
      RETURNING *
    `;

    const result = await query(insertSql, [
      name.trim(),
      phone ? phone.trim() : null,
      address ? address.trim() : null,
      notes || null,
    ]);

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'Vendor created successfully',
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/vendors/:id — update vendor
router.patch('/vendors/:id', requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, phone, address, notes, isActive } = req.body;

    const fields = [];
    const values = [];

    if (name !== undefined) {
      values.push(name.trim());
      fields.push(`name = $${values.length}`);
    }
    if (phone !== undefined) {
      values.push(phone ? phone.trim() : null);
      fields.push(`phone = $${values.length}`);
    }
    if (address !== undefined) {
      values.push(address ? address.trim() : null);
      fields.push(`address = $${values.length}`);
    }
    if (notes !== undefined) {
      values.push(notes || null);
      fields.push(`notes = $${values.length}`);
    }
    if (isActive !== undefined) {
      values.push(Boolean(isActive));
      fields.push(`is_active = $${values.length}`);
    }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields to update' });
    }

    values.push(id);
    const updateSql = `
      UPDATE vendors
      SET ${fields.join(', ')}, updated_at = NOW()
      WHERE id = $${values.length}
      RETURNING *
    `;

    const result = await query(updateSql, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Vendor not found' });
    }

    res.json({
      success: true,
      data: result.rows[0],
      message: 'Vendor updated successfully',
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/vendors/:id/toggle — toggle vendor active status
router.patch('/vendors/:id/toggle', requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      'UPDATE vendors SET is_active = NOT is_active, updated_at = NOW() WHERE id = $1 RETURNING id, name, is_active',
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Vendor not found' });
    }

    res.json({
      success: true,
      data: result.rows[0],
      message: `Vendor '${result.rows[0].name}' status changed to ${result.rows[0].is_active ? 'active' : 'inactive'}`,
    });
  } catch (err) {
    next(err);
  }
});

export default router;

