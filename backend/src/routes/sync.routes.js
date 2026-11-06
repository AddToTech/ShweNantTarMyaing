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
router.use('/sync', optionalAuth);

// POST /api/v1/sync/push — Flush offline queue from tablet
router.post('/sync/push', async (req, res, next) => {
  const client = await pool.connect();
  try {
    const { branchId, sales = [], wastageLogs = [] } = req.body;
    const syncedSaleUuids = [];
    const syncedWastageUuids = [];

    const defaultBranchId = await resolveBranchId(branchId);
    const fallbackUserRes = await query(
      'SELECT id FROM users WHERE is_active = TRUE ORDER BY created_at ASC LIMIT 1'
    );
    const fallbackUserId = fallbackUserRes.rows[0]?.id || null;

    for (const log of wastageLogs) {
      const r = normalizeWastageReason(log.reason);
      await query(`ALTER TYPE wastage_reason ADD VALUE IF NOT EXISTS '${r}'`).catch(() => {});
    }

    await client.query('BEGIN');

    // Process queued sales
    for (const sale of sales) {
      const existing = await client.query(
        `SELECT id FROM sync_audit_log WHERE record_id = $1 AND entity_name = 'sales'`,
        [sale.saleUuid]
      );
      if (existing.rows.length === 0) {
        const targetBranchId = (await resolveBranchId(sale.branchId)) || defaultBranchId;
        const actualCashierId =
          sale.cashierId && UUID_REGEX.test(String(sale.cashierId))
            ? String(sale.cashierId)
            : req.user?.id || fallbackUserId;

        const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
        const receiptNo = `SP-${dateStr}-SYNC-${String(sale.saleUuid).slice(0, 4).toUpperCase()}`;
        const createdAtDate = (sale.createdAt || sale.clientCreatedAt)
          ? new Date(sale.createdAt || sale.clientCreatedAt)
          : new Date();
        const tendered = Number(sale.tenderedAmount || sale.amountTendered || 0);

        const saleRes = await client.query(
          `INSERT INTO sales (
            branch_id, cashier_id, receipt_no, customer_name, subtotal,
            discount_amount, tax_amount, total_amount, payment_method,
            tendered_amount, amount_tendered, change_amount, notes, is_offline_created, created_at, sold_at
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::payment_method, $10, $10, $11, $12, TRUE, $13, $13)
          RETURNING id`,
          [
            targetBranchId,
            actualCashierId,
            receiptNo,
            sale.customerName || null,
            sale.subtotal || 0,
            sale.discountAmount || 0,
            sale.taxAmount || 0,
            sale.totalAmount || 0,
            sale.paymentMethod || 'cash',
            tendered,
            sale.changeAmount || 0,
            sale.notes || `Synced offline [${sale.saleUuid}]`,
            createdAtDate,
          ]
        );

        const newSaleId = saleRes.rows[0].id;

        if (Array.isArray(sale.items)) {
          for (const item of sale.items) {
            const resolvedProdId = await resolveProductId(item.productId);
            const disc = item.discountPercent || item.discountPct || 0;
            await client.query(
              `INSERT INTO sale_items (
                sale_id, product_id, product_name, quantity, unit_price,
                discount_pct, discount_percent, line_total
              ) VALUES ($1, $2, $3, $4, $5, $6, $6, $7)`,
              [
                newSaleId,
                resolvedProdId,
                item.productName,
                item.quantity,
                item.unitPrice,
                disc,
                item.lineTotal,
              ]
            );

            if (resolvedProdId) {
              await client.query(
                `UPDATE branch_inventories
                 SET stock_quantity = GREATEST(0, stock_quantity - $1),
                     updated_at = NOW()
                 WHERE branch_id = $2 AND product_id = $3`,
                [item.quantity, targetBranchId, resolvedProdId]
              );
            }
          }
        }

        await client.query(
          `INSERT INTO sync_audit_log (branch_id, table_name, entity_name, record_id, operation, changed_by, payload)
           VALUES ($1, 'sales', 'sales', $2, 'INSERT', $3, $4)`,
          [targetBranchId, sale.saleUuid, actualCashierId, JSON.stringify(sale)]
        );
      }
      syncedSaleUuids.push(sale.saleUuid);
    }

    // Process queued wastage logs
    for (const log of wastageLogs) {
      const existing = await client.query(
        `SELECT id FROM sync_audit_log WHERE record_id = $1 AND entity_name = 'wastage_logs'`,
        [log.logUuid]
      );
      if (existing.rows.length === 0) {
        const targetBranchId = (await resolveBranchId(log.branchId)) || defaultBranchId;
        let targetProductId = await resolveProductId(log.productId);
        if (!targetProductId && log.productName) {
          const byName = await client.query(
            'SELECT id FROM products WHERE name = $1 LIMIT 1',
            [String(log.productName).trim()]
          );
          targetProductId = byName.rows[0]?.id || null;
        }
        const actualRecorder =
          log.recordedBy && UUID_REGEX.test(String(log.recordedBy))
            ? String(log.recordedBy)
            : req.user?.id || fallbackUserId;
        const normalizedReason = normalizeWastageReason(log.reason);
        const noteText = log.notes || log.description || `Synced offline [${log.logUuid}]`;

        if (targetBranchId && targetProductId) {
          await client.query(
            `INSERT INTO wastage_logs (
              branch_id, product_id, recorded_by, product_name, quantity,
              unit_cost, reason, description, notes
            ) VALUES ($1, $2, $3, $4, $5, $6, $7::wastage_reason, $8, $8)`,
            [
              targetBranchId,
              targetProductId,
              actualRecorder,
              log.productName || '',
              Number(log.quantity) || 1,
              Number(log.unitCost) || 0,
              normalizedReason,
              noteText,
            ]
          );

          await client.query(
            `UPDATE branch_inventories
             SET stock_quantity = GREATEST(0, stock_quantity - $1),
                 updated_at = NOW()
             WHERE branch_id = $2 AND product_id = $3`,
            [Number(log.quantity) || 1, targetBranchId, targetProductId]
          );

          await client.query(
            `INSERT INTO sync_audit_log (branch_id, table_name, entity_name, record_id, operation, changed_by, payload)
             VALUES ($1, 'wastage_logs', 'wastage_logs', $2, 'INSERT', $3, $4)`,
            [targetBranchId, log.logUuid, actualRecorder, JSON.stringify(log)]
          );
        }
      }
      syncedWastageUuids.push(log.logUuid);
    }

    await client.query('COMMIT');

    res.json({
      success: true,
      syncedSaleUuids,
      syncedWastageUuids,
      syncedAt: new Date().toISOString(),
    });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});

// GET /api/v1/sync/pull — Incremental sync pull for tablet
router.get('/sync/pull', async (req, res, next) => {
  try {
    const { branchId, since } = req.query;
    const targetBranchId = await resolveBranchId(branchId);
    const sinceDate = since ? new Date(since) : new Date(0);

    const products = await pool.query(
      `SELECT p.*, COALESCE(bi.stock_quantity, 0) AS stock_quantity
       FROM products p
       LEFT JOIN branch_inventories bi ON p.id = bi.product_id ${
         targetBranchId ? 'AND bi.branch_id = $1' : ''
       }
       WHERE p.updated_at >= $${targetBranchId ? 2 : 1}`,
      targetBranchId ? [targetBranchId, sinceDate] : [sinceDate]
    );

    const categories = await pool.query(
      `SELECT * FROM categories WHERE updated_at >= $1 ORDER BY sort_order ASC`,
      [sinceDate]
    );

    const subcategories = await pool.query(
      `SELECT * FROM subcategories WHERE updated_at >= $1 ORDER BY sort_order ASC`,
      [sinceDate]
    );

    const employees = await pool.query(
      `SELECT * FROM employees WHERE updated_at >= $1 ${
        targetBranchId ? 'AND branch_id = $2' : ''
      }`,
      targetBranchId ? [sinceDate, targetBranchId] : [sinceDate]
    );

    const branches = await pool.query(
      `SELECT * FROM branches WHERE is_active = TRUE ORDER BY name ASC`
    );

    res.json({
      success: true,
      data: {
        products: products.rows,
        categories: categories.rows,
        subcategories: subcategories.rows,
        employees: employees.rows,
        branches: branches.rows,
        serverTime: new Date().toISOString(),
      },
    });
  } catch (err) {
    next(err);
  }
});

export default router;
