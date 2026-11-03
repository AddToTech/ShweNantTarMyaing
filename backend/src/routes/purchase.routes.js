import { Router } from 'express';
import { pool, query, resolveBranchId, resolveProductId } from '../config/db.js';
import { authenticate, requireRole } from '../middleware/auth.middleware.js';

const router = Router();

// Protect all purchase routes
router.use('/purchases', authenticate);

// GET /api/v1/purchases — list purchases
router.get('/purchases', async (req, res, next) => {
  try {
    const { branchId, vendorId, paymentStatus, startDate, endDate, search } = req.query;
    const targetBranchId = await resolveBranchId(branchId);

    let sql = `
      SELECT p.*,
             v.name AS vendor_name,
             v.phone AS vendor_phone,
             b.name AS branch_name,
             u.name AS created_by_name,
             COUNT(pi.id) AS item_count,
             COALESCE(
               json_agg(
                 json_build_object(
                   'id', pi.id,
                   'product_id', pi.product_id,
                   'product_name_snapshot', pi.product_name_snapshot,
                   'quantity', pi.quantity,
                   'unit_cost', pi.unit_cost
                 )
               ) FILTER (WHERE pi.id IS NOT NULL),
               '[]'::json
             ) AS items
      FROM purchases p
      LEFT JOIN vendors v ON p.vendor_id = v.id
      LEFT JOIN branches b ON p.branch_id = b.id
      LEFT JOIN users u ON p.created_by = u.id
      LEFT JOIN purchase_items pi ON p.id = pi.purchase_id
      WHERE 1=1
    `;

    const params = [];

    if (targetBranchId) {
      params.push(targetBranchId);
      sql += ` AND p.branch_id = $${params.length}`;
    }

    if (vendorId) {
      params.push(vendorId);
      sql += ` AND p.vendor_id = $${params.length}`;
    }

    if (paymentStatus) {
      params.push(paymentStatus);
      sql += ` AND p.payment_status = $${params.length}::purchase_payment_status`;
    }

    if (startDate) {
      params.push(startDate);
      sql += ` AND p.purchase_date >= $${params.length}`;
    }

    if (endDate) {
      params.push(endDate);
      sql += ` AND p.purchase_date <= $${params.length}`;
    }

    if (search) {
      params.push(`%${search}%`);
      sql += ` AND (p.purchase_no ILIKE $${params.length} OR v.name ILIKE $${params.length})`;
    }

    sql += ' GROUP BY p.id, v.name, v.phone, b.name, u.name ORDER BY p.purchase_date DESC, p.created_at DESC';

    const result = await query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/purchases/:id — get purchase with items
router.get('/purchases/:id', async (req, res, next) => {
  try {
    const { id } = req.params;

    const purchaseRes = await query(
      `SELECT p.*,
              v.name AS vendor_name,
              v.phone AS vendor_phone,
              v.address AS vendor_address,
              b.name AS branch_name,
              u.name AS created_by_name
       FROM purchases p
       LEFT JOIN vendors v ON p.vendor_id = v.id
       LEFT JOIN branches b ON p.branch_id = b.id
       LEFT JOIN users u ON p.created_by = u.id
       WHERE p.id = $1`,
      [id]
    );

    if (purchaseRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Purchase not found' });
    }

    const itemsRes = await query(
      `SELECT pi.*, p.sku, p.barcode
       FROM purchase_items pi
       LEFT JOIN products p ON pi.product_id = p.id
       WHERE pi.purchase_id = $1
       ORDER BY pi.product_name_snapshot ASC`,
      [id]
    );

    res.json({
      success: true,
      data: {
        ...purchaseRes.rows[0],
        items: itemsRes.rows,
      },
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/purchases — create purchase order with items
router.post('/purchases', requireRole('owner', 'manager'), async (req, res, next) => {
  const client = await pool.connect();
  try {
    const {
      branchId,
      vendorId,
      purchaseDate,
      discount = 0,
      paidAmount = 0,
      notes,
      items, // [{ productId, quantity, unitCost }]
      autoApplyToInventory = false,
    } = req.body;

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
    const computedItems = [];

    for (const item of items) {
      const resolvedProdId = (await resolveProductId(item.productId)) || item.productId;
      const prodRes = await client.query('SELECT name FROM products WHERE id = $1', [resolvedProdId]);
      const prodName = prodRes.rows[0]?.name || item.productName || 'Product';
      const qty = Number(item.quantity) || 0;
      const cost = Number(item.unitCost) || 0;
      const lineTotal = qty * cost;
      subtotal += lineTotal;

      computedItems.push({
        productId: resolvedProdId,
        productName: prodName,
        quantity: qty,
        unitCost: cost,
        totalCost: lineTotal,
      });
    }

    const discountAmount = Number(discount) || 0;
    const totalAmount = Math.max(0, subtotal - discountAmount);
    const initialPaid = Number(paidAmount) || 0;

    let paymentStatus = 'unpaid';
    if (initialPaid >= totalAmount && totalAmount > 0) {
      paymentStatus = 'paid';
    } else if (initialPaid > 0) {
      paymentStatus = 'partial';
    }

    // 2. Generate collision-proof purchase number
    const dateStr = new Date().toISOString().slice(0, 10).replace(/-/g, '');
    const countRes = await client.query(
      `SELECT COALESCE(MAX(CAST(SUBSTRING(purchase_no FROM '[0-9]+$') AS INTEGER)), 0) + 1 AS next_seq
       FROM purchases
       WHERE purchase_no ~ $1`,
      [`^PO-${dateStr}-[0-9]+$`]
    );
    const seq = String(countRes.rows[0].next_seq).padStart(4, '0');
    const purchaseNo = `PO-${dateStr}-${seq}`;

    const uuidRegex = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
    const validVendorId = vendorId && uuidRegex.test(String(vendorId)) ? String(vendorId) : null;

    // 3. Insert purchase header
    const purchaseInsertSql = `
      INSERT INTO purchases (
        purchase_no, branch_id, vendor_id, purchase_date,
        subtotal, discount, total_amount, paid_amount,
        payment_status, notes, created_by
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9::purchase_payment_status, $10, $11)
      RETURNING *
    `;

    const purchaseRes = await client.query(purchaseInsertSql, [
      purchaseNo,
      targetBranchId,
      validVendorId,
      purchaseDate ? new Date(purchaseDate) : new Date(),
      subtotal,
      discountAmount,
      totalAmount,
      initialPaid,
      paymentStatus,
      notes || null,
      req.user.id,
    ]);

    const createdPurchase = purchaseRes.rows[0];

    // 4. Insert purchase items
    const savedItems = [];
    for (const item of computedItems) {
      const itemRes = await client.query(
        `INSERT INTO purchase_items (
          purchase_id, product_id, product_name_snapshot, quantity, unit_cost
        ) VALUES ($1, $2, $3, $4, $5)
        RETURNING *`,
        [createdPurchase.id, item.productId, item.productName, item.quantity, item.unitCost]
      );
      savedItems.push(itemRes.rows[0]);
    }

    // 5. If requested, apply to inventory immediately
    if (autoApplyToInventory) {
      await client.query('SELECT apply_purchase_to_inventory($1)', [createdPurchase.id]);
    }

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      data: {
        ...createdPurchase,
        items: savedItems,
      },
      message: 'Purchase created successfully',
    });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});

// POST /api/v1/purchases/:id/confirm — apply purchase items to inventory
router.post('/purchases/:id/confirm', requireRole('owner', 'manager'), async (req, res, next) => {
  const client = await pool.connect();
  try {
    const { id } = req.params;

    await client.query('BEGIN');

    const purchaseRes = await client.query('SELECT * FROM purchases WHERE id = $1', [id]);
    if (purchaseRes.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, message: 'Purchase not found' });
    }

    // Call stored procedure to update stock and cost price
    await client.query('SELECT apply_purchase_to_inventory($1)', [id]);

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Purchase inventory applied and product cost prices updated successfully',
    });
  } catch (err) {
    await client.query('ROLLBACK');
    next(err);
  } finally {
    client.release();
  }
});

// PATCH /api/v1/purchases/:id/pay — record payment against balance
router.patch('/purchases/:id/pay', requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { paymentAmount } = req.body;

    const amount = Number(paymentAmount);
    if (!amount || amount <= 0) {
      return res.status(400).json({ success: false, message: 'A positive payment amount is required' });
    }

    const checkRes = await query('SELECT * FROM purchases WHERE id = $1', [id]);
    if (checkRes.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Purchase not found' });
    }

    const current = checkRes.rows[0];
    const newPaid = Number(current.paid_amount) + amount;
    const total = Number(current.total_amount);

    let newStatus = 'partial';
    if (newPaid >= total) {
      newStatus = 'paid';
    } else if (newPaid <= 0) {
      newStatus = 'unpaid';
    }

    const result = await query(
      `UPDATE purchases
       SET paid_amount = $1, payment_status = $2::purchase_payment_status, updated_at = NOW()
       WHERE id = $3
       RETURNING *`,
      [newPaid, newStatus, id]
    );

    res.json({
      success: true,
      data: result.rows[0],
      message: 'Payment recorded successfully',
    });
  } catch (err) {
    next(err);
  }
});

export default router;

