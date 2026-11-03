import { Router } from 'express';
import { pool, query, resolveBranchId, resolveProductId } from '../config/db.js';
import { optionalAuth, authenticate, requireDeletePermission } from '../middleware/auth.middleware.js';

const router = Router();
const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Attach user if Bearer token is provided, and allow seamless POS sync
router.use('/sales', optionalAuth);

// POST /api/v1/sales — create a new sale with transactional inventory deduction
router.post('/sales', async (req, res, next) => {
  const client = await pool.connect();
  try {
    const {
      branchId,
      cashierId,
      cashierName,
      customerName,
      customerPhone,
      items, // [{ productId, productName, quantity, unitPrice, discountPercent }]
      discountAmount = 0,
      taxAmount = 0,
      paymentMethod = 'cash',
      tenderedAmount = 0,
      amountTendered = 0,
      notes,
      isOfflineCreated = false,
      clientCreatedAt,
    } = req.body;

    let actualCashierId =
      cashierId && UUID_REGEX.test(String(cashierId))
        ? String(cashierId)
        : req.user?.id || null;

    if (!actualCashierId && cashierName) {
      const userByName = await client.query(
        'SELECT id FROM users WHERE LOWER(name) = LOWER($1) LIMIT 1',
        [String(cashierName).trim()]
      );
      actualCashierId = userByName.rows[0]?.id || null;
    }
    if (!actualCashierId) {
      const fallbackUser = await client.query(
        'SELECT id FROM users WHERE is_active = TRUE ORDER BY created_at ASC LIMIT 1'
      );
      actualCashierId = fallbackUser.rows[0]?.id || null;
    }

    const actualTendered = Number(tenderedAmount || amountTendered || 0);
    const targetBranchId = await resolveBranchId(branchId);

    if (!targetBranchId || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({
        success: false,
        message: 'branchId and a non-empty items array are required',
      });
    }

    await client.query('BEGIN');

    // 1. Calculate totals
    let subtotal = 0;
    const computedItems = items.map((item) => {
      const discountPct = Number(item.discountPercent || item.discountPct || 0);
      const lineTotal =
        Number(item.quantity) * Number(item.unitPrice) * (1 - discountPct / 100);
      subtotal += lineTotal;
      return { ...item, discountPct, lineTotal };
    });

    const totalAmount = Math.max(0, subtotal - Number(discountAmount) + Number(taxAmount));
    const changeAmount =
      paymentMethod === 'cash' ? Math.max(0, actualTendered - totalAmount) : 0;

    // 2. Generate unique receipt number across all branches and dates
    const createdAtDate = clientCreatedAt ? new Date(clientCreatedAt) : new Date();
    const validCreatedAt = Number.isNaN(createdAtDate.getTime()) ? new Date() : createdAtDate;
    const dateStr = validCreatedAt.toISOString().slice(0, 10).replace(/-/g, '');
    const seqRes = await client.query(
      `SELECT COALESCE(
         MAX(NULLIF(regexp_replace(receipt_no, '^SP-' || $1 || '-', ''), '')::int),
         0
       ) + 1 AS next_seq
       FROM sales
       WHERE receipt_no ~ ('^SP-' || $1 || '-[0-9]+$')`,
      [dateStr]
    );
    const seq = String(seqRes.rows[0]?.next_seq || 1).padStart(4, '0');
    const receiptNo = `SP-${dateStr}-${seq}`;

    // 3. Insert sale header
    const saleInsertSql = `
      INSERT INTO sales (
        branch_id, cashier_id, receipt_no, customer_name, customer_phone,
        subtotal, discount_amount, tax_amount, total_amount, payment_method,
        tendered_amount, amount_tendered, change_amount, notes, is_offline_created, created_at, sold_at
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10::payment_method, $11, $12, $13, $14, $15, $16, $16)
      RETURNING *
    `;

    const saleResult = await client.query(saleInsertSql, [
      targetBranchId,
      actualCashierId,
      receiptNo,
      customerName || null,
      customerPhone || null,
      subtotal,
      Number(discountAmount),
      Number(taxAmount),
      totalAmount,
      paymentMethod,
      actualTendered,
      actualTendered,
      changeAmount,
      notes || null,
      Boolean(isOfflineCreated),
      validCreatedAt,
    ]);

    const createdSale = saleResult.rows[0];

    // 4. Insert sale items & deduct inventory
    const savedItems = [];
    for (const item of computedItems) {
      let resolvedProdId = await resolveProductId(item.productId);
      if (!resolvedProdId && item.productName) {
        const byName = await client.query(
          'SELECT id FROM products WHERE name = $1 LIMIT 1',
          [String(item.productName).trim()]
        );
        resolvedProdId = byName.rows[0]?.id || null;
      }
      if (!resolvedProdId) {
        const fallbackProd = await client.query(
          'SELECT id FROM products ORDER BY created_at DESC LIMIT 1'
        );
        resolvedProdId = fallbackProd.rows[0]?.id || null;
      }

      const itemRes = await client.query(
        `INSERT INTO sale_items (
          sale_id, product_id, product_name, quantity, unit_price,
          discount_pct, discount_percent, line_total
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
        RETURNING *`,
        [
          createdSale.id,
          resolvedProdId,
          item.productName,
          item.quantity,
          item.unitPrice,
          item.discountPct,
          item.discountPct,
          item.lineTotal,
        ]
      );
      savedItems.push(itemRes.rows[0]);

      // Decrement branch inventory
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

    const metaRes = await client.query(
      `SELECT
         (SELECT name FROM users WHERE id = $1) AS cashier_name,
         (SELECT name FROM branches WHERE id = $2) AS branch_name`,
      [actualCashierId, targetBranchId]
    );

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      data: {
        ...createdSale,
        cashier_name: metaRes.rows[0]?.cashier_name || cashierName || req.user?.name || 'Cashier',
        branch_name: metaRes.rows[0]?.branch_name || null,
        items: savedItems,
      },
    });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});

// GET /api/v1/sales — list sales with filters
router.get('/sales', async (req, res, next) => {
  try {
    const { branchId, startDate, endDate, paymentMethod, search, limit = 50, offset = 0 } = req.query;
    const targetBranchId = await resolveBranchId(branchId);

    let sql = `
      SELECT s.*,
             u.name AS cashier_name,
             b.name AS branch_name,
             COALESCE(
               json_agg(
                 json_build_object(
                   'id', si.id,
                   'product_id', si.product_id,
                   'product_name', si.product_name,
                   'quantity', si.quantity,
                   'unit_price', si.unit_price,
                   'discount_percent', si.discount_percent,
                   'line_total', si.line_total
                 )
               ) FILTER (WHERE si.id IS NOT NULL), '[]'
             ) AS items
      FROM sales s
      LEFT JOIN users u ON s.cashier_id = u.id
      LEFT JOIN branches b ON s.branch_id = b.id
      LEFT JOIN sale_items si ON s.id = si.sale_id
      WHERE 1=1
    `;

    const params = [];

    if (targetBranchId) {
      params.push(targetBranchId);
      sql += ` AND s.branch_id = $${params.length}`;
    }

    if (startDate) {
      params.push(startDate);
      sql += ` AND s.sold_at >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      sql += ` AND s.sold_at <= $${params.length}`;
    }

    if (paymentMethod) {
      params.push(paymentMethod);
      sql += ` AND s.payment_method = $${params.length}::payment_method`;
    }

    if (search) {
      params.push(`%${search}%`);
      sql += ` AND (s.receipt_no ILIKE $${params.length} OR s.customer_name ILIKE $${params.length} OR s.customer_phone ILIKE $${params.length})`;
    }

    sql += ` GROUP BY s.id, u.name, b.name ORDER BY s.sold_at DESC LIMIT $${params.length + 1} OFFSET $${params.length + 2}`;
    params.push(Number(limit) || 50, Number(offset) || 0);

    const result = await query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/sales/:id — get single sale with full receipt items
router.get('/sales/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    const saleRes = await query(
      `SELECT s.*, u.name AS cashier_name, b.name AS branch_name, b.address AS branch_address, b.phone AS branch_phone
       FROM sales s
       LEFT JOIN users u ON s.cashier_id = u.id
       LEFT JOIN branches b ON s.branch_id = b.id
       WHERE s.id = $1`,
      [id]
    );

    if (saleRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Sale not found' });
    }

    const itemsRes = await query(
      `SELECT si.*, p.sku, p.barcode
       FROM sale_items si
       LEFT JOIN products p ON si.product_id = p.id
       WHERE si.sale_id = $1
       ORDER BY si.created_at ASC`,
      [id]
    );

    res.json({
      success: true,
      data: {
        ...saleRes.rows[0],
        items: itemsRes.rows,
      },
    });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/sales/:id/pay — record partial or full credit payment on a sale
router.patch('/sales/:id/pay', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { paymentAmount = 0, markAsPaid = false } = req.body;

    const isUuid = UUID_REGEX.test(id);
    const lookupRes = await query(
      isUuid
        ? 'SELECT * FROM sales WHERE id = $1 OR receipt_no = $1 LIMIT 1'
        : 'SELECT * FROM sales WHERE receipt_no = $1 LIMIT 1',
      [id]
    );

    if (lookupRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Sale receipt not found' });
    }

    const sale = lookupRes.rows[0];
    const totalAmount = Number(sale.total_amount || 0);
    const currentTendered = Number(sale.tendered_amount ?? sale.amount_tendered ?? 0);
    const newTendered = markAsPaid
      ? totalAmount
      : Math.min(totalAmount, currentTendered + Math.max(0, Number(paymentAmount) || 0));

    const updatedRes = await query(
      `UPDATE sales
       SET tendered_amount = $1,
           amount_tendered = $1
       WHERE id = $2
       RETURNING *`,
      [newTendered, sale.id]
    );

    res.json({
      success: true,
      data: updatedRes.rows[0],
      message: 'Credit payment recorded successfully',
    });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/sales/:id — void/delete a sale order, restore stock items, requires delete permission
router.delete('/sales/:id', authenticate, requireDeletePermission, async (req, res, next) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;
    const isUuid = UUID_REGEX.test(id);

    const lookupRes = await client.query(
      isUuid
        ? 'SELECT id, receipt_no, branch_id FROM sales WHERE id = $1 OR receipt_no = $1 LIMIT 1'
        : 'SELECT id, receipt_no, branch_id FROM sales WHERE receipt_no = $1 LIMIT 1',
      [id]
    );

    if (lookupRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Sale order not found' });
    }

    const sale = lookupRes.rows[0];

    await client.query('BEGIN');

    // Fetch sale items to restore stock
    const itemsRes = await client.query(
      'SELECT product_id, quantity FROM sale_items WHERE sale_id = $1',
      [sale.id]
    );

    // Revert inventory back to branch_inventories
    for (const item of itemsRes.rows) {
      if (item.product_id && item.quantity > 0 && sale.branch_id) {
        await client.query(
          `INSERT INTO branch_inventories (branch_id, product_id, stock_quantity, updated_at)
           VALUES ($1, $2, $3, NOW())
           ON CONFLICT (branch_id, product_id)
           DO UPDATE SET stock_quantity = branch_inventories.stock_quantity + EXCLUDED.stock_quantity, updated_at = NOW()`,
          [sale.branch_id, item.product_id, item.quantity]
        );
      }
    }

    // Delete sale (cascades to sale_items)
    await client.query('DELETE FROM sales WHERE id = $1', [sale.id]);

    await client.query('COMMIT');

    res.json({
      success: true,
      message: `ဘောက်ချာ #${sale.receipt_no} ကို အောင်မြင်စွာ ပယ်ဖျက်ပြီး ပစ္စည်းလက်ကျန်များကို ပြန်လည်ဖြည့်သွင်းပြီးပါပြီ။`,
      data: { id: sale.id, receiptNo: sale.receipt_no },
    });
  } catch (err) {
    await client.query('ROLLBACK').catch(() => {});
    next(err);
  } finally {
    client.release();
  }
});

export default router;
