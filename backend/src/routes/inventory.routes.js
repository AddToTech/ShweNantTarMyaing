import { Router } from 'express';
import { query, resolveBranchId, resolveProductId } from '../config/db.js';
import { authenticate, requireRole } from '../middleware/auth.middleware.js';

const router = Router();

// GET /api/v1/inventory/branch/:branchId — get inventory for a branch
router.get('/inventory/branch/:branchId', async (req, res, next) => {
  try {
    const targetBranchId = await resolveBranchId(req.params.branchId);
    const sql = `
      SELECT 
        bi.id, bi.branch_id, bi.product_id, bi.stock_quantity, bi.min_alert_threshold,
        bi.last_counted_at,
        p.name AS product_name, p.sku, p.barcode, p.sale_price, p.cost_price,
        p.origin_type, COALESCE(po.name, p.origin_type) AS origin_name, p.size_label, p.unit_of_measure, p.image_url,
        c.name AS category_name
      FROM branch_inventories bi
      JOIN products p ON bi.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      LEFT JOIN plant_origins po ON (p.origin_id = po.id OR p.origin_type = po.code OR p.origin_type = po.name)
      WHERE bi.branch_id = $1 AND p.is_active = TRUE
      ORDER BY p.created_at DESC, p.sku DESC, p.name DESC
    `;
    const result = await query(sql, [targetBranchId]);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/inventory/low-stock/:branchId — get low stock alert items
router.get('/inventory/low-stock/:branchId', async (req, res, next) => {
  try {
    const targetBranchId = await resolveBranchId(req.params.branchId);
    const sql = `
      SELECT 
        bi.id, bi.branch_id, bi.product_id, bi.stock_quantity, bi.min_alert_threshold,
        p.name AS product_name, p.sku, p.origin_type, c.name AS category_name
      FROM branch_inventories bi
      JOIN products p ON bi.product_id = p.id
      JOIN categories c ON p.category_id = c.id
      WHERE bi.branch_id = $1 AND bi.stock_quantity <= bi.min_alert_threshold AND p.is_active = TRUE
      ORDER BY bi.stock_quantity ASC
    `;
    const result = await query(sql, [targetBranchId]);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/inventory/adjust — manual stock adjustment (manager/owner)
router.post('/inventory/adjust', authenticate, requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { branchId, productId, newQuantity, deltaQuantity, reason, minAlertThreshold } = req.body;

    if (!branchId || !productId) {
      return res.status(400).json({
        success: false,
        message: 'branchId and productId are required',
      });
    }

    const targetBranchId = await resolveBranchId(branchId);
    const targetProductId = await resolveProductId(productId);

    let updateSql;
    let params;

    if (newQuantity !== undefined) {
      updateSql = `
        INSERT INTO branch_inventories (branch_id, product_id, stock_quantity, min_alert_threshold, last_counted_at, last_counted_by, updated_at)
        VALUES ($1, $2, $3, COALESCE($4, 5), NOW(), $5, NOW())
        ON CONFLICT (branch_id, product_id)
        DO UPDATE SET
          stock_quantity = EXCLUDED.stock_quantity,
          min_alert_threshold = COALESCE($4, branch_inventories.min_alert_threshold),
          last_counted_at = NOW(),
          last_counted_by = $5,
          updated_at = NOW()
        RETURNING *
      `;
      params = [targetBranchId, targetProductId, Math.max(0, Number(newQuantity)), minAlertThreshold || null, req.user?.id || null];
    } else if (deltaQuantity !== undefined) {
      updateSql = `
        INSERT INTO branch_inventories (branch_id, product_id, stock_quantity, min_alert_threshold, last_counted_at, last_counted_by, updated_at)
        VALUES ($1, $2, GREATEST(0, $3), COALESCE($4, 5), NOW(), $5, NOW())
        ON CONFLICT (branch_id, product_id)
        DO UPDATE SET
          stock_quantity = GREATEST(0, branch_inventories.stock_quantity + $3),
          min_alert_threshold = COALESCE($4, branch_inventories.min_alert_threshold),
          last_counted_at = NOW(),
          last_counted_by = $5,
          updated_at = NOW()
        RETURNING *
      `;
      params = [targetBranchId, targetProductId, Number(deltaQuantity), minAlertThreshold || null, req.user?.id || null];
    } else if (minAlertThreshold !== undefined) {
      updateSql = `
        UPDATE branch_inventories
        SET min_alert_threshold = $3, updated_at = NOW()
        WHERE branch_id = $1 AND product_id = $2
        RETURNING *
      `;
      params = [targetBranchId, targetProductId, Number(minAlertThreshold)];
    } else {
      return res.status(400).json({
        success: false,
        message: 'Either newQuantity, deltaQuantity, or minAlertThreshold must be provided',
      });
    }

    const result = await query(updateSql, params);

    // Record audit log
    await query(
      `INSERT INTO sync_audit_log (branch_id, table_name, entity_name, record_id, operation, changed_by, payload)
       VALUES ($1, 'branch_inventories', 'branch_inventories', $2, 'UPDATE', $3, $4)`,
      [
        targetBranchId,
        targetProductId,
        req.user.id,
        JSON.stringify({ reason: reason || 'Manual adjustment', updated: result.rows[0] }),
      ]
    );

    res.json({
      success: true,
      data: result.rows[0],
      message: 'Inventory adjusted successfully',
    });
  } catch (err) {
    next(err);
  }
});

export default router;
