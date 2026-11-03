import { Router } from 'express';
import { pool, query, resolveBranchId, resolveProductId } from '../config/db.js';
import { optionalAuth } from '../middleware/auth.middleware.js';

const router = Router();
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const normalizeWastageReason = (raw) => {
  const str = String(raw || 'other').toLowerCase().trim();
  if (str.includes('dead') || str.includes('wither') || str.includes('mortality')) {
    return 'mortality';
  }
  if (str.includes('pest') || str.includes('disease')) {
    return 'pest_disease';
  }
  if (str.includes('broken') || str.includes('crack') || str.includes('pot')) {
    return 'broken_pot';
  }
  if (str.includes('transport') || str.includes('damage')) {
    return 'transport_damage';
  }
  if (str.includes('overwater')) return 'overwatering';
  if (str.includes('underwater')) return 'underwatering';
  if (str.includes('expir')) return 'expired_chemical';
  return 'other';
};

// Attach user if Bearer token is provided
router.use('/wastage', optionalAuth);

// POST /api/v1/wastage — record plant wastage / mortality log
router.post('/wastage', async (req, res, next) => {
  const client = await pool.connect();
  try {
    const {
      branchId,
      productId,
      productName: bodyProductName,
      recordedBy,
      quantity,
      unitCost,
      reason,
      notes,
      description,
      photoUrl,
    } = req.body;

    const targetBranchId = await resolveBranchId(branchId);
    let targetProductId = await resolveProductId(productId);
    if (!targetProductId && bodyProductName) {
      const byName = await query(
        'SELECT id FROM products WHERE name = $1 LIMIT 1',
        [String(bodyProductName).trim()]
      );
      targetProductId = byName.rows[0]?.id || null;
    }
    if (!targetProductId && productId && UUID_REGEX.test(String(productId))) {
      targetProductId = String(productId);
    }

    let actualRecorder =
      recordedBy && UUID_REGEX.test(String(recordedBy))
        ? String(recordedBy)
        : req.user?.id || null;
    if (!actualRecorder) {
      const fallbackUser = await query(
        'SELECT id FROM users WHERE is_active = TRUE ORDER BY created_at ASC LIMIT 1'
      );
      actualRecorder = fallbackUser.rows[0]?.id || null;
    }

    const actualNotes = notes || description || null;
    const normalizedReason = normalizeWastageReason(reason);

    if (!targetBranchId || !targetProductId || !quantity || !reason) {
      return res.status(400).json({
        success: false,
        message: 'branchId, productId, quantity, and reason are required',
      });
    }

    // Ensure the enum value exists in PostgreSQL before starting transaction
    await query(
      `ALTER TYPE wastage_reason ADD VALUE IF NOT EXISTS '${normalizedReason}'`
    ).catch(() => {});

    await client.query('BEGIN');

    // Fetch product name and unit cost if not supplied
    let cost = unitCost;
    let productName = bodyProductName || '';
    const prodRes = await client.query(
      'SELECT name, cost_price FROM products WHERE id = $1',
      [targetProductId]
    );
    if (prodRes.rows.length > 0) {
      productName = prodRes.rows[0].name;
      if (cost === undefined || cost === null) {
        cost = prodRes.rows[0].cost_price;
      }
    }

    const insertSql = `
      INSERT INTO wastage_logs (
        branch_id, product_id, recorded_by, product_name, quantity,
        unit_cost, reason, description, notes, photo_url
      ) VALUES ($1, $2, $3, $4, $5, $6, $7::wastage_reason, $8, $8, $9)
      RETURNING *
    `;

    const result = await client.query(insertSql, [
      targetBranchId,
      targetProductId,
      actualRecorder,
      productName,
      Number(quantity),
      Number(cost) || 0,
      normalizedReason,
      actualNotes,
      photoUrl || null,
    ]);

    // Deduct stock in branch inventory
    await client.query(
      `UPDATE branch_inventories
       SET stock_quantity = GREATEST(0, stock_quantity - $1),
           updated_at = NOW()
       WHERE branch_id = $2 AND product_id = $3`,
      [Number(quantity), targetBranchId, targetProductId]
    );

    const branchMeta = await client.query(
      'SELECT name FROM branches WHERE id = $1',
      [targetBranchId]
    );

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      data: {
        ...result.rows[0],
        branch_name: branchMeta.rows[0]?.name || null,
      },
      message: 'Wastage recorded successfully',
    });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});

// GET /api/v1/wastage — get wastage logs with filters
router.get('/wastage', async (req, res, next) => {
  try {
    const { branchId, reason, startDate, endDate, limit = 50, offset = 0 } = req.query;
    const targetBranchId = await resolveBranchId(branchId);

    let sql = `
      SELECT wl.*, u.name AS recorder_name, b.name AS branch_name
      FROM wastage_logs wl
      LEFT JOIN users u ON wl.recorded_by = u.id
      LEFT JOIN branches b ON wl.branch_id = b.id
      WHERE 1=1
    `;

    const params = [];

    if (targetBranchId) {
      params.push(targetBranchId);
      sql += ` AND wl.branch_id = $${params.length}`;
    }

    if (reason) {
      params.push(normalizeWastageReason(reason));
      sql += ` AND wl.reason = $${params.length}::wastage_reason`;
    }

    if (startDate) {
      params.push(startDate);
      sql += ` AND wl.recorded_at >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      sql += ` AND wl.recorded_at <= $${params.length}`;
    }

    sql += ` ORDER BY wl.recorded_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(Number(limit) || 50, Number(offset) || 0);

    const result = await query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/wastage/branch/:branchId — get wastage logs for a specific branch
router.get('/wastage/branch/:branchId', async (req, res, next) => {
  try {
    const targetBranchId = await resolveBranchId(req.params.branchId);
    const { limit = 50, offset = 0 } = req.query;

    const sql = `
      SELECT wl.*, u.name AS recorder_name, b.name AS branch_name
      FROM wastage_logs wl
      LEFT JOIN users u ON wl.recorded_by = u.id
      LEFT JOIN branches b ON wl.branch_id = b.id
      WHERE wl.branch_id = $1
      ORDER BY wl.recorded_at DESC
      LIMIT $2 OFFSET $3
    `;

    const result = await query(sql, [targetBranchId, Number(limit) || 50, Number(offset) || 0]);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

export default router;
