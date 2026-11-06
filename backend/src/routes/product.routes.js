import { Router } from 'express';
import multer from 'multer';
import path from 'path';
import fs from 'fs';
import { pool, query, resolveBranchId } from '../config/db.js';
import { authenticate, requireRole, optionalAuth, requireDeletePermission } from '../middleware/auth.middleware.js';

const router = Router();

// Multer storage setup for product images
const uploadDir = path.resolve('uploads/products');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const uniqueSuffix = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `prod-${uniqueSuffix}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 10 * 1024 * 1024 }, // 10MB max
  fileFilter: (req, file, cb) => {
    const allowed = /jpeg|jpg|png|webp|gif/;
    const ext = path.extname(file.originalname).toLowerCase().replace('.', '');
    const mime = file.mimetype;
    if (allowed.test(ext) && (mime.startsWith('image/') || allowed.test(mime))) {
      return cb(null, true);
    }
    cb(new Error('Only image files (JPEG, PNG, WebP) are allowed'));
  },
});

// GET /api/v1/categories — get all categories with subcategories
router.get('/categories', async (req, res, next) => {
  try {
    const catResult = await query(
      `SELECT id, name, COALESCE(burmese_name, name) AS burmese_name, COALESCE(emoji, '🏷️') AS emoji, sort_order
       FROM categories
       ORDER BY sort_order ASC, created_at ASC`
    );
    const subResult = await query(
      'SELECT id, category_id, name, sort_order FROM subcategories ORDER BY sort_order ASC, created_at ASC'
    );

    const categories = catResult.rows.map((cat) => ({
      ...cat,
      subcategories: subResult.rows.filter((sub) => sub.category_id === cat.id),
    }));

    res.json({ success: true, data: categories });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/categories — create category
router.post('/categories', authenticate, requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { name, burmeseName, emoji = '🏷️', sortOrder = 0 } = req.body;
    const primaryName = (name && name.trim()) || (burmeseName && burmeseName.trim());
    if (!primaryName) {
      return res.status(400).json({ success: false, message: 'Category name is required' });
    }
    const cleanBurmese = (burmeseName && burmeseName.trim()) || primaryName;
    const cleanEmoji = (emoji && String(emoji).trim()) || '🏷️';
    const result = await query(
      'INSERT INTO categories (name, burmese_name, emoji, sort_order) VALUES ($1, $2, $3, $4) RETURNING *',
      [primaryName, cleanBurmese, cleanEmoji, Number(sortOrder) || 0]
    );
    res.status(201).json({ success: true, data: { ...result.rows[0], subcategories: [] } });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/categories/:id — update category
router.patch('/categories/:id', authenticate, requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, burmeseName, emoji, sortOrder } = req.body;
    const fields = [];
    const values = [];
    if (name !== undefined && String(name).trim() !== '') {
      values.push(String(name).trim());
      fields.push(`name = $${values.length}`);
    }
    if (burmeseName !== undefined && String(burmeseName).trim() !== '') {
      values.push(String(burmeseName).trim());
      fields.push(`burmese_name = $${values.length}`);
    }
    if (emoji !== undefined && String(emoji).trim() !== '') {
      values.push(String(emoji).trim());
      fields.push(`emoji = $${values.length}`);
    }
    if (sortOrder !== undefined) {
      values.push(Number(sortOrder) || 0);
      fields.push(`sort_order = $${values.length}`);
    }
    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields provided' });
    }
    values.push(id);
    const result = await query(
      `UPDATE categories SET ${fields.join(', ')}, updated_at = NOW() WHERE id = $${values.length} RETURNING *`,
      values
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Category not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/categories/:id — delete category
router.delete('/categories/:id', authenticate, requireDeletePermission, async (req, res, next) => {
  try {
    const { id } = req.params;
    const activeProdRes = await query('SELECT COUNT(*) FROM products WHERE category_id = $1 AND is_active = TRUE', [id]);
    const activeCount = parseInt(activeProdRes.rows[0].count, 10);
    if (activeCount > 0) {
      return res.status(400).json({
        success: false,
        message: `ဤအမျိုးအစားတွင် လက်ရှိအသုံးပြုနေသော ပစ္စည်း (${activeCount}) မျိုး ရှိနေသောကြောင့် ဖျက်၍မရသေးပါ။ ပစ္စည်းများကို အခြားအမျိုးအစားသို့ ပြောင်းရွှေ့ခြင်း သို့မဟုတ် အရင်ဖျက်ပေးပါ။`,
      });
    }

    // Reassign any soft-deleted (inactive) products to another category so foreign key is not violated
    const fallbackCat = await query('SELECT id FROM categories WHERE id != $1 ORDER BY sort_order ASC, name ASC LIMIT 1', [id]);
    if (fallbackCat.rows.length > 0) {
      await query('UPDATE products SET category_id = $1 WHERE category_id = $2', [fallbackCat.rows[0].id, id]);
    }

    await query('UPDATE products SET subcategory_id = NULL WHERE subcategory_id IN (SELECT id FROM subcategories WHERE category_id = $1)', [id]);
    await query('DELETE FROM subcategories WHERE category_id = $1', [id]);
    const result = await query('DELETE FROM categories WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Category not found' });
    }
    res.json({ success: true, message: 'Category deleted successfully' });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/categories/:id/subcategories — create subcategory
router.post('/categories/:id/subcategories', authenticate, requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, sortOrder = 0 } = req.body;
    if (!name || !name.trim()) {
      return res.status(400).json({ success: false, message: 'Subcategory name is required' });
    }
    const result = await query(
      'INSERT INTO subcategories (category_id, name, sort_order) VALUES ($1, $2, $3) RETURNING *',
      [id, name.trim(), Number(sortOrder) || 0]
    );
    res.status(201).json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// PATCH /api/v1/subcategories/:id — update subcategory
router.patch('/subcategories/:id', authenticate, requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const { name, sortOrder } = req.body;
    const fields = [];
    const values = [];
    if (name !== undefined) {
      values.push(name.trim());
      fields.push(`name = $${values.length}`);
    }
    if (sortOrder !== undefined) {
      values.push(Number(sortOrder) || 0);
      fields.push(`sort_order = $${values.length}`);
    }
    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields provided' });
    }
    values.push(id);
    const result = await query(
      `UPDATE subcategories SET ${fields.join(', ')}, updated_at = NOW() WHERE id = $${values.length} RETURNING *`,
      values
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Subcategory not found' });
    }
    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// DELETE /api/v1/subcategories/:id — delete subcategory
router.delete('/subcategories/:id', authenticate, requireDeletePermission, async (req, res, next) => {
  try {
    const { id } = req.params;
    // Disassociate products from this subcategory first so foreign key constraint is not violated
    await query('UPDATE products SET subcategory_id = NULL WHERE subcategory_id = $1', [id]);
    const result = await query('DELETE FROM subcategories WHERE id = $1 RETURNING *', [id]);
    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Subcategory not found' });
    }
    res.json({ success: true, message: 'Subcategory deleted successfully' });
  } catch (err) {
    next(err);
  }
});

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

const resolveCategoryUuid = async (catInput) => {
  if (!catInput) return null;
  if (UUID_REGEX.test(catInput)) return catInput;
  const lower = String(catInput).toLowerCase();
  let pattern = catInput;
  if (lower.includes('plant') && !lower.includes('chem')) pattern = 'Plants';
  else if (lower.includes('pot')) pattern = 'Pots';
  else if (lower.includes('chem')) pattern = 'Plant Chemicals';
  else if (lower.includes('tool')) pattern = 'Gardening Tools';
  else if (lower.includes('other')) pattern = 'Others';

  const res = await query('SELECT id FROM categories WHERE name ILIKE $1 LIMIT 1', [`%${pattern}%`]);
  if (res.rows.length > 0) return res.rows[0].id;
  const fallback = await query('SELECT id FROM categories ORDER BY sort_order ASC LIMIT 1');
  return fallback.rows[0]?.id || null;
};

const normalizeOriginType = (orig) => {
  if (!orig) return null;
  const s = String(orig).toLowerCase();
  if (s.includes('thai')) return 'thai_import';
  if (s.includes('china')) return 'china_import';
  if (s.includes('local')) return 'local';
  return null;
};

// GET /api/v1/products — list products with category and branch stock
router.get('/products', optionalAuth, async (req, res, next) => {
  try {
    const { branchId, categoryId, originType, search, includeInactive } = req.query;
    let targetBranchId = await resolveBranchId(branchId);
    if (!targetBranchId) {
      const defBranch = await query('SELECT id FROM branches WHERE is_active = TRUE ORDER BY name ASC LIMIT 1');
      targetBranchId = defBranch.rows[0]?.id || null;
    }

    let sql = `
      SELECT 
        p.id, p.category_id, p.subcategory_id, p.vendor_id, p.name, p.sku, p.barcode,
        p.cost_price, p.sale_price, p.origin_type, p.size_label, p.unit_of_measure,
        p.attributes, p.image_url, p.is_active, p.created_at, p.updated_at,
        c.name AS category_name,
        s.name AS subcategory_name,
        v.name AS vendor_name,
        COALESCE(bi.stock_quantity, 0) AS stock_quantity,
        COALESCE(bi.min_alert_threshold, 5) AS min_alert_threshold,
        (
          SELECT COALESCE(jsonb_object_agg(bi2.branch_id::text, bi2.stock_quantity), '{}'::jsonb)
          FROM branch_inventories bi2
          WHERE bi2.product_id = p.id
        ) AS branch_stocks
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN subcategories s ON p.subcategory_id = s.id
      LEFT JOIN vendors v ON p.vendor_id = v.id
      LEFT JOIN branch_inventories bi ON p.id = bi.product_id ${
        targetBranchId ? 'AND bi.branch_id = $1' : ''
      }
      WHERE 1=1
    `;

    const params = [];
    if (targetBranchId) params.push(targetBranchId);

    if (includeInactive !== 'true') {
      sql += ' AND p.is_active = TRUE';
    }

    if (categoryId) {
      const resolvedCat = await resolveCategoryUuid(categoryId);
      if (resolvedCat) {
        params.push(resolvedCat);
        sql += ` AND p.category_id = $${params.length}`;
      }
    }

    if (originType) {
      const normOrigin = normalizeOriginType(originType);
      if (normOrigin) {
        params.push(normOrigin);
        sql += ` AND p.origin_type = $${params.length}`;
      }
    }

    if (req.query.vendorId) {
      params.push(req.query.vendorId);
      sql += ` AND p.vendor_id = $${params.length}`;
    }

    if (search) {
      params.push(`%${search}%`);
      sql += ` AND (p.name ILIKE $${params.length} OR p.sku ILIKE $${params.length} OR p.barcode ILIKE $${params.length})`;
    }

    // Last-In, First-Out (LIFO): newest added products first
    sql += ' ORDER BY p.created_at DESC, p.sku DESC, p.name DESC';

    const result = await query(sql, params);
    res.json({ success: true, data: result.rows });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/products/barcode/:barcode — scan barcode lookup
router.get('/products/barcode/:barcode', async (req, res, next) => {
  try {
    const { barcode } = req.params;
    const { branchId } = req.query;
    const targetBranchId = await resolveBranchId(branchId);

    const sql = `
      SELECT 
        p.id, p.category_id, p.subcategory_id, p.vendor_id, p.name, p.sku, p.barcode,
        p.cost_price, p.sale_price, p.origin_type, p.size_label, p.unit_of_measure,
        p.attributes, p.image_url, p.is_active,
        c.name AS category_name,
        s.name AS subcategory_name,
        v.name AS vendor_name,
        COALESCE(bi.stock_quantity, 0) AS stock_quantity,
        COALESCE(bi.min_alert_threshold, 5) AS min_alert_threshold
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN subcategories s ON p.subcategory_id = s.id
      LEFT JOIN vendors v ON p.vendor_id = v.id
      LEFT JOIN branch_inventories bi ON p.id = bi.product_id ${
        targetBranchId ? 'AND bi.branch_id = $2' : ''
      }
      WHERE p.barcode = $1 AND p.is_active = TRUE
    `;

    const params = targetBranchId ? [barcode, targetBranchId] : [barcode];
    const result = await query(sql, params);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// GET /api/v1/products/:id — get single product details
router.get('/products/:id', async (req, res, next) => {
  try {
    const { id } = req.params;
    const { branchId } = req.query;
    const targetBranchId = await resolveBranchId(branchId);

    const sql = `
      SELECT 
        p.*,
        c.name AS category_name,
        s.name AS subcategory_name,
        v.name AS vendor_name,
        COALESCE(bi.stock_quantity, 0) AS stock_quantity,
        COALESCE(bi.min_alert_threshold, 5) AS min_alert_threshold
      FROM products p
      LEFT JOIN categories c ON p.category_id = c.id
      LEFT JOIN subcategories s ON p.subcategory_id = s.id
      LEFT JOIN vendors v ON p.vendor_id = v.id
      LEFT JOIN branch_inventories bi ON p.id = bi.product_id ${
        targetBranchId ? 'AND bi.branch_id = $2' : ''
      }
      WHERE p.id = $1
    `;

    const params = targetBranchId ? [id, targetBranchId] : [id];
    const result = await query(sql, params);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    res.json({ success: true, data: result.rows[0] });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/products — create product (manager/owner)
router.post('/products', authenticate, requireRole('owner', 'manager'), async (req, res, next) => {
  const client = await pool.connect();
  try {
    const {
      categoryId,
      subcategoryId,
      subcategory,
      name,
      sku,
      barcode,
      costPrice = 0,
      salePrice = 0,
      originType,
      sizeLabel,
      vendorId,
      vendor_id,
      expiryDate,
      unitOfMeasure = 'piece',
      attributes = {},
      imageUrl,
      initialStock = 0,
      stockBranchA,
      stockBranchB,
      branchStocks = {},
      branchId,
    } = req.body;

    if (!categoryId || !name || salePrice === undefined) {
      return res.status(400).json({
        success: false,
        message: 'categoryId, name, and salePrice are required',
      });
    }

    const resolvedCatId = await resolveCategoryUuid(categoryId);
    const normOrigin = normalizeOriginType(originType);
    const targetBranchId = await resolveBranchId(branchId);
    const rawVendorId = vendorId ?? vendor_id;
    const resolvedVendorId = rawVendorId && UUID_REGEX.test(rawVendorId) ? rawVendorId : null;

    let resolvedSubId = subcategoryId && UUID_REGEX.test(subcategoryId) ? subcategoryId : null;
    if (!resolvedSubId && (subcategory || subcategoryId)) {
      const subName = String(subcategory || subcategoryId).trim();
      if (subName && resolvedCatId) {
        const subRes = await query(
          'SELECT id FROM subcategories WHERE category_id = $1 AND name ILIKE $2 LIMIT 1',
          [resolvedCatId, subName]
        );
        resolvedSubId = subRes.rows[0]?.id || null;
      }
    }

    await client.query('BEGIN');

    const insertSql = `
      INSERT INTO products (
        category_id, subcategory_id, vendor_id, name, sku, barcode,
        cost_price, sale_price, origin_type, size_label,
        expiry_date, unit_of_measure, attributes, image_url
      ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
      RETURNING *
    `;

    const prodRes = await client.query(insertSql, [
      resolvedCatId,
      resolvedSubId,
      resolvedVendorId,
      name.trim(),
      sku || null,
      barcode || null,
      Number(costPrice) || 0,
      Number(salePrice) || 0,
      normOrigin,
      sizeLabel || null,
      expiryDate || null,
      unitOfMeasure,
      JSON.stringify(attributes),
      imageUrl || null,
    ]);

    const createdProduct = prodRes.rows[0];

    // Auto-create branch_inventories records for all active branches
    const branchRes = await client.query('SELECT id, name FROM branches WHERE is_active = TRUE ORDER BY created_at ASC, id ASC');
    for (let i = 0; i < branchRes.rows.length; i++) {
      const b = branchRes.rows[i];
      let stock = 0;
      if (branchStocks && typeof branchStocks === 'object') {
        const val = branchStocks[b.id] ?? branchStocks[b.name] ?? (i === 0 ? branchStocks['branch_a'] : (i === 1 ? branchStocks['branch_b'] : undefined));
        if (val !== undefined) {
          stock = Number(val) || 0;
        } else if (i === 0 && stockBranchA !== undefined) stock = Number(stockBranchA) || 0;
        else if (i === 1 && stockBranchB !== undefined) stock = Number(stockBranchB) || 0;
        else if (targetBranchId && b.id === targetBranchId) stock = Number(initialStock) || 0;
        else if (i === 0) stock = Number(initialStock) || 0;
      } else if (i === 0 && stockBranchA !== undefined) stock = Number(stockBranchA) || 0;
      else if (i === 1 && stockBranchB !== undefined) stock = Number(stockBranchB) || 0;
      else if (targetBranchId && b.id === targetBranchId) stock = Number(initialStock) || 0;
      else if (i === 0) stock = Number(initialStock) || 0;

      await client.query(
        `INSERT INTO branch_inventories (branch_id, product_id, stock_quantity, min_alert_threshold)
         VALUES ($1, $2, $3, 5)
         ON CONFLICT (branch_id, product_id) DO UPDATE SET stock_quantity = EXCLUDED.stock_quantity`,
        [b.id, createdProduct.id, stock]
      );
    }

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      data: createdProduct,
      message: 'Product created successfully',
    });
  } catch (err) {
    await client.query('ROLLBACK');
    if (err.code === '23505') {
      if (err.constraint && err.constraint.includes('barcode')) {
        return res.status(400).json({
          success: false,
          message: 'ဤ Barcode နံပါတ်သည် အခြားပစ္စည်းတစ်ခုတွင် သုံးထားပြီးဖြစ်ပါသည်။ အခြား Barcode ပြောင်းပေးပါ။',
        });
      }
      if (err.constraint && err.constraint.includes('sku')) {
        return res.status(400).json({
          success: false,
          message: 'ဤ SKU ကုဒ်သည် အခြားပစ္စည်းတစ်ခုတွင် သုံးထားပြီးဖြစ်ပါသည်။ အခြား SKU ပြောင်းပေးပါ။',
        });
      }
      return res.status(400).json({
        success: false,
        message: 'ဤအချက်အလက် (SKU သို့မဟုတ် Barcode) သည် အခြားပစ္စည်းတွင် ရှိနှင့်ပြီးဖြစ်ပါသည်',
      });
    }
    next(err);
  } finally {
    client.release();
  }
});

// PATCH /api/v1/products/:id — update product
router.patch('/products/:id', authenticate, requireRole('owner', 'manager'), async (req, res, next) => {
  try {
    const { id } = req.params;
    const {
      categoryId,
      subcategoryId,
      name,
      sku,
      barcode,
      costPrice,
      salePrice,
      originType,
      sizeLabel,
      expiryDate,
      unitOfMeasure,
      attributes,
      imageUrl,
      isActive,
    } = req.body;

    const fields = [];
    const values = [];

    let resolvedCatForSub = null;
    if (categoryId !== undefined) {
      const resolvedCat = await resolveCategoryUuid(categoryId);
      if (resolvedCat) {
        resolvedCatForSub = resolvedCat;
        values.push(resolvedCat);
        fields.push(`category_id = $${values.length}`);
      }
    }
    if (subcategoryId !== undefined || req.body.subcategory !== undefined) {
      const rawSub = subcategoryId ?? req.body.subcategory;
      let resolvedSub = rawSub && UUID_REGEX.test(rawSub) ? rawSub : null;
      if (!resolvedSub && rawSub) {
        const subName = String(rawSub).trim();
        if (subName) {
          const subRes = resolvedCatForSub
            ? await query(
                'SELECT id FROM subcategories WHERE category_id = $1 AND name ILIKE $2 LIMIT 1',
                [resolvedCatForSub, subName]
              )
            : await query(
                'SELECT id FROM subcategories WHERE name ILIKE $1 LIMIT 1',
                [subName]
              );
          resolvedSub = subRes.rows[0]?.id || null;
        }
      }
      values.push(resolvedSub);
      fields.push(`subcategory_id = $${values.length}`);
    }
    if (name !== undefined) {
      values.push(name.trim());
      fields.push(`name = $${values.length}`);
    }
    if (sku !== undefined) {
      values.push(sku || null);
      fields.push(`sku = $${values.length}`);
    }
    if (barcode !== undefined) {
      values.push(barcode || null);
      fields.push(`barcode = $${values.length}`);
    }
    if (costPrice !== undefined) {
      values.push(Number(costPrice) || 0);
      fields.push(`cost_price = $${values.length}`);
    }
    if (salePrice !== undefined) {
      values.push(Number(salePrice) || 0);
      fields.push(`sale_price = $${values.length}`);
    }
    if (originType !== undefined) {
      values.push(normalizeOriginType(originType));
      fields.push(`origin_type = $${values.length}`);
    }
    if (sizeLabel !== undefined) {
      values.push(sizeLabel || null);
      fields.push(`size_label = $${values.length}`);
    }
    if (req.body.vendorId !== undefined || req.body.vendor_id !== undefined) {
      const rawVendor = req.body.vendorId ?? req.body.vendor_id;
      const resolvedVendor = rawVendor && UUID_REGEX.test(rawVendor) ? rawVendor : null;
      values.push(resolvedVendor);
      fields.push(`vendor_id = $${values.length}`);
    }
    if (expiryDate !== undefined) {
      values.push(expiryDate || null);
      fields.push(`expiry_date = $${values.length}`);
    }
    if (unitOfMeasure !== undefined) {
      values.push(unitOfMeasure);
      fields.push(`unit_of_measure = $${values.length}`);
    }
    if (attributes !== undefined) {
      values.push(JSON.stringify(attributes));
      fields.push(`attributes = $${values.length}`);
    }
    if (imageUrl !== undefined) {
      values.push(imageUrl || null);
      fields.push(`image_url = $${values.length}`);
    }
    if (isActive !== undefined) {
      values.push(Boolean(isActive));
      fields.push(`is_active = $${values.length}`);
    }

    if (fields.length === 0) {
      return res.status(400).json({ success: false, message: 'No fields provided for update' });
    }

    values.push(id);
    const updateSql = `
      UPDATE products
      SET ${fields.join(', ')}, updated_at = NOW()
      WHERE id = $${values.length}
      RETURNING *
    `;

    const result = await query(updateSql, values);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    res.json({
      success: true,
      data: result.rows[0],
      message: 'Product updated successfully',
    });
  } catch (err) {
    if (err.code === '23505') {
      if (err.constraint && err.constraint.includes('barcode')) {
        return res.status(400).json({
          success: false,
          message: 'ဤ Barcode နံပါတ်သည် အခြားပစ္စည်းတစ်ခုတွင် သုံးထားပြီးဖြစ်ပါသည်။ အခြား Barcode ပြောင်းပေးပါ။',
        });
      }
      if (err.constraint && err.constraint.includes('sku')) {
        return res.status(400).json({
          success: false,
          message: 'ဤ SKU ကုဒ်သည် အခြားပစ္စည်းတစ်ခုတွင် သုံးထားပြီးဖြစ်ပါသည်။ အခြား SKU ပြောင်းပေးပါ။',
        });
      }
      return res.status(400).json({
        success: false,
        message: 'ဤအချက်အလက် (SKU သို့မဟုတ် Barcode) သည် အခြားပစ္စည်းတွင် ရှိနှင့်ပြီးဖြစ်ပါသည်',
      });
    }
    next(err);
  }
});

// DELETE /api/v1/products/:id — soft delete (requires delete_data permission or super admin)
router.delete('/products/:id', authenticate, requireDeletePermission, async (req, res, next) => {
  try {
    const { id } = req.params;
    const result = await query(
      `UPDATE products 
       SET is_active = FALSE,
           sku = CASE WHEN sku IS NOT NULL THEN sku || '_del_' || EXTRACT(EPOCH FROM NOW())::bigint ELSE NULL END,
           barcode = CASE WHEN barcode IS NOT NULL THEN barcode || '_del_' || EXTRACT(EPOCH FROM NOW())::bigint ELSE NULL END,
           updated_at = NOW() 
       WHERE id = $1 
       RETURNING id, name, is_active`,
      [id]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, message: 'Product not found' });
    }

    res.json({
      success: true,
      message: `Product '${result.rows[0].name}' deleted successfully`,
    });
  } catch (err) {
    next(err);
  }
});

// POST /api/v1/products/:id/image — upload product image
router.post(
  '/products/:id/image',
  authenticate,
  requireRole('owner', 'manager'),
  upload.single('image'),
  async (req, res, next) => {
    try {
      const { id } = req.params;

      if (!req.file) {
        return res.status(400).json({ success: false, message: 'No image file uploaded' });
      }

      const imageUrl = `/uploads/products/${req.file.filename}`;

      const result = await query(
        'UPDATE products SET image_url = $1, updated_at = NOW() WHERE id = $2 RETURNING id, name, image_url',
        [imageUrl, id]
      );

      if (result.rows.length === 0) {
        // Remove uploaded file if product not found
        fs.unlinkSync(req.file.path);
        return res.status(404).json({ success: false, message: 'Product not found' });
      }

      res.json({
        success: true,
        data: result.rows[0],
        message: 'Product image uploaded successfully',
      });
    } catch (err) {
      next(err);
    }
  }
);

export default router;
