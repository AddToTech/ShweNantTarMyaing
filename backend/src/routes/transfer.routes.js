import { Router } from 'express';
import { pool, query, resolveBranchId, resolveProductId } from '../config/db.js';
import { authenticate } from '../middleware/auth.middleware.js';

const router = Router();

// Protect transfer routes
router.use('/transfers', authenticate);

// GET /api/v1/transfers — list transfers with filters
router.get('/transfers', async (req, res, next) => {
  try {
    const { fromBranchId, toBranchId, branchId, status, startDate, endDate, limit = 50, offset = 0 } = req.query;
    const targetFrom = await resolveBranchId(fromBranchId);
    const targetTo = await resolveBranchId(toBranchId);
    const targetBranch = await resolveBranchId(branchId);

    let sql = `
      SELECT t.*,
             fb.name AS from_branch_name,
             tb.name AS to_branch_name,
             u1.name AS requested_by_name,
             u2.name AS received_by_name,
             COUNT(ti.id) AS item_count,
             COALESCE(
               json_agg(
                 json_build_object(
                   'id', ti.id,
                   'product_id', ti.product_id,
                   'product_name', ti.product_name,
                   'requested_quantity', ti.requested_quantity,
                   'sent_quantity', ti.sent_quantity,
                   'received_quantity', ti.received_quantity
                 )
               ) FILTER (WHERE ti.id IS NOT NULL),
               '[]'::json
             ) AS items
      FROM branch_transfers t
      JOIN branches fb ON t.from_branch_id = fb.id
      JOIN branches tb ON t.to_branch_id = tb.id
      LEFT JOIN users u1 ON (t.requested_by = u1.id OR t.initiated_by = u1.id)
      LEFT JOIN users u2 ON t.received_by = u2.id
      LEFT JOIN branch_transfer_items ti ON t.id = ti.transfer_id
      WHERE 1=1
    `;

    const params = [];

    if (targetFrom) {
      params.push(targetFrom);
      sql += ` AND t.from_branch_id = $${params.length}`;
    }

    if (targetTo) {
      params.push(targetTo);
      sql += ` AND t.to_branch_id = $${params.length}`;
    }

    if (targetBranch) {
      params.push(targetBranch);
      sql += ` AND (t.from_branch_id = $${params.length} OR t.to_branch_id = $${params.length})`;
    }

    if (status) {
      params.push(status);
      sql += ` AND t.status = $${params.length}::transfer_status`;
    }

    if (startDate) {
      params.push(startDate);
      sql += ` AND t.created_at >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      sql += ` AND t.created_at <= $${params.length}`;
    }

    sql += ` GROUP BY t.id, fb.name, tb.name, u1.name, u2.name ORDER BY t.created_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(Number(limit) || 50, Number(offset) || 0);

    const result = await query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/transfers/:id — get transfer with items
router.get('/transfers/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    const transferRes = await query(
      `SELECT t.*,
              fb.name AS from_branch_name,
              tb.name AS to_branch_name,
              u1.name AS requested_by_name,
              u2.name AS received_by_name
       FROM branch_transfers t
       JOIN branches fb ON t.from_branch_id = fb.id
       JOIN branches tb ON t.to_branch_id = tb.id
       LEFT JOIN users u1 ON (t.requested_by = u1.id OR t.initiated_by = u1.id)
       LEFT JOIN users u2 ON t.received_by = u2.id
       WHERE t.id = $1`,
      [id]
    );

    if (transferRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Transfer not found' });
    }

    const itemsRes = await query(
      `SELECT ti.*, p.sku, p.barcode
       FROM branch_transfer_items ti
       LEFT JOIN products p ON ti.product_id = p.id
       WHERE ti.transfer_id = $1
       ORDER BY ti.product_name ASC`,
      [id]
    );

    res.json({
      success: true,
      data: {
        ...transferRes.rows[0],
        items: itemsRes.rows,
      },
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/transfers — create inter-branch transfer
router.post('/transfers', async (req, res, next) => {
  const client = await pool.connect();
  try {
    const {
      fromBranchId,
      toBranchId,
      requestedBy,
      notes,
      items, // [{ productId, sentQuantity || requestedQuantity }]
    } = req.body;

    const targetFrom = await resolveBranchId(fromBranchId);
    const targetTo = await resolveBranchId(toBranchId);
    const actualRequester = requestedBy || req.user?.id || null;

    if (!targetFrom || !targetTo || targetFrom === targetTo) {
      return res.status(400).json({
        success: false,
        message: 'fromBranchId and toBranchId must be specified and different',
      });
    }

    if (!items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'Transfer items array is required',
      });
    }

    await client.query('BEGIN');

    // 1. Generate collision-proof transfer number
    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const countRes = await client.query(
      `SELECT COALESCE(MAX(CAST(SUBSTRING(transfer_no FROM '[0-9]+$') AS INTEGER)), 0) + 1 AS next_seq
       FROM branch_transfers
       WHERE transfer_no ~ $1`,
      [`^TR-${dateStr}-[0-9]+$`]
    );
    const seq = String(countRes.rows[0].next_seq).padStart(4, '0');
    const transferNo = `TR-${dateStr}-${seq}`;

    // 2. Insert transfer header
    const transferRes = await client.query(
      `INSERT INTO branch_transfers (
        reference_no, transfer_no, from_branch_id, to_branch_id, status, initiated_by, requested_by, notes, dispatched_at
      ) VALUES ($1, $1, $2, $3, 'in_transit', $4, $4, $5, NOW())
      RETURNING *`,
      [transferNo, targetFrom, targetTo, actualRequester, notes || null]
    );

    const transfer = transferRes.rows[0];

    // 3. Insert items and deduct from source branch
    const savedItems = [];
    for (const item of items) {
      const resolvedProdId = (await resolveProductId(item.productId)) || item.productId;
      const prodRes = await client.query(
        'SELECT name FROM products WHERE id = $1',
        [resolvedProdId]
      );
      const prodName = prodRes.rows[0]?.name || item.productName || '';
      const qty = Number(item.sentQuantity || item.requestedQuantity || 0);

      const itemRes = await client.query(
        `INSERT INTO branch_transfer_items (
          transfer_id, product_id, product_name, requested_quantity, sent_quantity
        ) VALUES ($1, $2, $3, $4, $4)
        RETURNING *`,
        [transfer.id, resolvedProdId, prodName, qty]
      );
      savedItems.push(itemRes.rows[0]);

      // Deduct from source branch
      await client.query(
        `UPDATE branch_inventories
         SET stock_quantity = GREATEST(0, stock_quantity - $1),
             updated_at = NOW()
         WHERE branch_id = $2 AND product_id = $3`,
        [qty, targetFrom, resolvedProdId]
      );
    }

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      data: { ...transfer, items: savedItems },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});

// PATCH /api/v1/transfers/:id/receive — receiving branch confirms items
router.patch('/transfers/:id/receive', async (req, res, next) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;
    const { receivedBy, items } = req.body; // items: [{ id: transferItemId, receivedQuantity }]
    const actualReceiver = receivedBy || req.user?.id || null;

    await client.query('BEGIN');

    const transferRes = await client.query(
      'SELECT * FROM branch_transfers WHERE id::text = $1 OR transfer_no = $1 OR reference_no = $1 LIMIT 1',
      [id]
    );

    if (transferRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, message: 'Transfer not found' });
    }

    const transfer = transferRes.rows[0];
    if (transfer.status === 'received') {
      await client.query('ROLLBACK');
      return res.status(400).json({ success: false, message: 'Transfer already marked received' });
    }

    const allTransferItemsRes = await client.query(
      'SELECT * FROM branch_transfer_items WHERE transfer_id = $1',
      [transfer.id]
    );

    const itemsToProcess =
      Array.isArray(items) && items.length > 0
        ? items
        : allTransferItemsRes.rows.map((r) => ({
            id: r.id,
            receivedQuantity: r.sent_quantity ?? r.requested_quantity ?? 0,
          }));

    // Update each item received_quantity and add to receiving branch inventory
    for (const item of itemsToProcess) {
      const trItem = allTransferItemsRes.rows.find((r) => String(r.id) === String(item.id));
      if (trItem) {
        const qty = Number(item.receivedQuantity ?? trItem.sent_quantity ?? trItem.requested_quantity ?? 0);

        await client.query(
          'UPDATE branch_transfer_items SET received_quantity = $1 WHERE id = $2',
          [qty, trItem.id]
        );

        // Upsert receiving branch inventory
        await client.query(
          `INSERT INTO branch_inventories (branch_id, product_id, stock_quantity, updated_at)
           VALUES ($1, $2, $3, NOW())
           ON CONFLICT (branch_id, product_id)
           DO UPDATE SET stock_quantity = branch_inventories.stock_quantity + EXCLUDED.stock_quantity,
                         updated_at = NOW()`,
          [transfer.to_branch_id, trItem.product_id, qty]
        );
      }
    }

    // Mark transfer received
    await client.query(
      `UPDATE branch_transfers
       SET status = 'received', received_by = $1, received_at = NOW(), updated_at = NOW()
       WHERE id = $2`,
      [actualReceiver, transfer.id]
    );

    await client.query('COMMIT');

    res.json({ success: true, message: 'Transfer received and inventory updated' });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});

export default router;
