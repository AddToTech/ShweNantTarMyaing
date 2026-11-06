import { Router } from 'express';
import { query } from '../config/db.js';
import { optionalAuth, requireRole } from '../middleware/auth.middleware.js';

const router = Router();

// GET /api/v1/plant-origins — list all plant origins
router.get('/plant-origins', optionalAuth, async (req, res, next) => {
  try {
    const { search, isActive } = req.query;

    let sql = `
      SELECT po.*,
             COUNT(p.id) FILTER (WHERE p.is_active = TRUE)::int AS product_count
      FROM plant_origins po
      LEFT JOIN products p ON (p.origin_id = po.id OR p.origin_type = po.code OR p.origin_type = po.name)
      WHERE 1=1
    `;
    const params = [];

    if (isActive !== undefined) {
      params.push(isActive === 'true');
      sql += ` AND po.is_active = $${params.length}`;
    }

    if (search) {
      params.push(`%${search.trim()}%`);
      sql += ` AND (po.name ILIKE $${params.length} OR po.code ILIKE $${params.length})`;
    }

    sql += ' GROUP BY po.id ORDER BY po.sort_order ASC, po.name ASC';

    const result = await query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/plant-origins — create a new plant origin
router.post('/plant-origins', optionalAuth, async (req, res, next) => {
  try {
    const { name, code, sortOrder } = req.body;

    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: 'မူရင်းဒေသ အမည် (Name) ထည့်သွင်းရန် လိုအပ်ပါသည်' });
    }

    const trimmedName = name.trim();
    const finalCode = code && code.trim()
      ? code.trim().toLowerCase().replace(/[^a-z0-9_]+/g, '_')
      : `origin_${Date.now()}`;

    const insertSql = `
      INSERT INTO plant_origins (name, code, sort_order, is_active)
      VALUES ($1, $2, $3, TRUE)
      ON CONFLICT (name) DO UPDATE 
        SET is_active = TRUE, updated_at = NOW()
      RETURNING *
    `;

    const result = await query(insertSql, [
      trimmedName,
      finalCode,
      Number(sortOrder) || 0,
    ]);

    res.status(201).json({
      success: true,
      data: result.rows[0],
      message: 'မူရင်းဒေသ အသစ် အောင်မြင်စွာ ထည့်သွင်းပြီးပါပြီ',
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/plant-origins/:id — update plant origin
router.patch('/plant-origins/:id', optionalAuth, async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, code, sortOrder, isActive } = req.body;

    const fields = [];
    const values = [];

    if (name !== undefined && name.trim()) {
      values.push(name.trim());
      fields.push(`name = $${values.length}`);
    }
    if (code !== undefined) {
      values.push(code ? code.trim() : null);
      fields.push(`code = $${values.length}`);
    }
    if (sortOrder !== undefined) {
      values.push(Number(sortOrder) || 0);
      fields.push(`sort_order = $${values.length}`);
    }
    if (isActive !== undefined) {
      values.push(Boolean(isActive));
      fields.push(`is_active = $${values.length}`);
    }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields provided to update' });
    }

    values.push(id);
    const sql = `
      UPDATE plant_origins
      SET ${fields.join(', ')}, updated_at = NOW()
      WHERE id = $${values.length}
      RETURNING *
    `;

    const result = await query(sql, values);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Plant origin not found' });
    }

    res.json({
      success: true,
      data: result.rows[0],
      message: 'မူရင်းဒေသ ပြင်ဆင်ပြီးပါပြီ',
    });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/plant-origins/:id — delete or soft-delete origin
router.delete('/plant-origins/:id', optionalAuth, async (req, res, next) => {
  try {
    const { id } = req.params;

    // Check if any products are using it
    const checkSql = `
      SELECT COUNT(*)::int AS count 
      FROM products p
      JOIN plant_origins po ON (p.origin_id = po.id OR p.origin_type = po.code OR p.origin_type = po.name)
      WHERE po.id = $1 AND p.is_active = TRUE
    `;
    const checkRes = await query(checkSql, [id]);
    const inUse = checkRes.rows[0]?.count > 0;

    if (inUse) {
      // Soft-delete if in use to preserve product history
      await query('UPDATE plant_origins SET is_active = FALSE, updated_at = NOW() WHERE id = $1', [id]);
      return res.json({
        success: true,
        message: 'မူရင်းဒေသကို ပစ္စည်းများတွင် အသုံးပြုထားသောကြောင့် ပိတ်ထားလိုက်ပါပြီ (Deactivated)',
      });
    }

    const result = await query('DELETE FROM plant_origins WHERE id = $1 RETURNING id', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Plant origin not found' });
    }

    res.json({ success: true, message: 'မူရင်းဒေသ ဖျက်ပစ်ပြီးပါပြီ' });
  } catch (err) {
    next(err);
  }
});

export default router;

