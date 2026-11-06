import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { pool } from './config/db.js';

import authRoutes from './routes/auth.routes.js';
import userRoutes from './routes/user.routes.js';
import branchRoutes from './routes/branch.routes.js';
import productRoutes from './routes/product.routes.js';
import saleRoutes from './routes/sale.routes.js';
import inventoryRoutes from './routes/inventory.routes.js';
import wastageRoutes from './routes/wastage.routes.js';
import transferRoutes from './routes/transfer.routes.js';
import vendorRoutes from './routes/vendor.routes.js';
import purchaseRoutes from './routes/purchase.routes.js';
import employeeRoutes from './routes/employee.routes.js';
import payrollRoutes from './routes/payroll.routes.js';
import reportRoutes from './routes/report.routes.js';
import syncRoutes from './routes/sync.routes.js';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load .env relative to server file and then cwd fallback
dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config();

const app = express();
// Default to 5001 to avoid macOS AirPlay Receiver occupying port 5000
const port = process.env.PORT || 5001;

// Middlewares
app.use(cors());
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Serve static uploaded files (both backend/uploads and cwd/uploads)
const uploadsDir = path.resolve(__dirname, '../uploads');
app.use('/uploads', express.static(uploadsDir));
app.use('/uploads', express.static(path.resolve('uploads')));

// Request logging in development
if (process.env.NODE_ENV !== 'production') {
  app.use((req, res, next) => {
    const fullUrl = req.originalUrl || req.url;
    res.on('finish', () => {
      console.log(`[${new Date().toISOString()}] ${req.method} ${fullUrl} -> ${res.statusCode}`);
    });
    next();
  });
}

// Health check
app.get('/health', async (req, res) => {
  try {
    await pool.query('SELECT 1');
    res.json({
      status: 'ok',
      service: 'sitepyoe-backend',
      database: 'connected',
      timestamp: new Date().toISOString(),
    });
  } catch (err) {
    res.status(500).json({
      status: 'error',
      service: 'sitepyoe-backend',
      database: 'disconnected',
      error: err.message,
    });
  }
});

// API Routes
app.use('/api/v1/auth', authRoutes);
app.use('/api/v1', branchRoutes);
app.use('/api/v1', userRoutes);
app.use('/api/v1', productRoutes);
app.use('/api/v1', saleRoutes);
app.use('/api/v1', inventoryRoutes);
app.use('/api/v1', wastageRoutes);
app.use('/api/v1', transferRoutes);
app.use('/api/v1', vendorRoutes);
app.use('/api/v1', purchaseRoutes);
app.use('/api/v1', employeeRoutes);
app.use('/api/v1', payrollRoutes);
app.use('/api/v1', reportRoutes);
app.use('/api/v1', syncRoutes);

// 404 Handler
app.use((req, res) => {
  res.status(404).json({
    success: false,
    message: `Endpoint ${req.method} ${req.path} not found`,
  });
});

// Global Error Handler
app.use((err, req, res, next) => {
  console.error('[Error]', err);
  res.status(err.status || 500).json({
    success: false,
    message: err.message || 'Internal Server Error',
    ...(process.env.NODE_ENV !== 'production' && { stack: err.stack }),
  });
});

// Start Server if executed directly
if (process.env.NODE_ENV !== 'test') {
  (async () => {
    const wastageReasons = [
      'mortality',
      'pest_disease',
      'transport_damage',
      'overwatering',
      'underwatering',
      'broken_pot',
      'expired_chemical',
      'other',
    ];
    for (const r of wastageReasons) {
      await pool
        .query(`ALTER TYPE wastage_reason ADD VALUE IF NOT EXISTS '${r}'`)
        .catch(() => {});
    }

    await pool
      .query(
        `DELETE FROM subcategories s
         WHERE NOT EXISTS (SELECT 1 FROM products p WHERE p.subcategory_id = s.id)
           AND s.name IN (
             'Orchids', 'Bonsai', 'Indoor Foliage', 'Fruit Saplings',
             'Ceramic', 'Terracotta', 'Plastic', 'Fertilizers',
             'Pesticides', 'Soil Mix', 'Pruning Shears', 'Watering Cans'
           )`
      )
      .catch(() => {});

    // Ensure products.subcategory_id foreign key constraint allows ON DELETE SET NULL
    await pool
      .query(
        `ALTER TABLE products DROP CONSTRAINT IF EXISTS products_subcategory_id_fkey;
         ALTER TABLE products ADD CONSTRAINT products_subcategory_id_fkey FOREIGN KEY (subcategory_id) REFERENCES subcategories(id) ON DELETE SET NULL;`
      )
      .catch((err) => console.error('Migration notice (products_subcategory_id_fkey):', err.message));

    // Ensure products table has vendor_id column referencing vendors table
    await pool
      .query(
        `ALTER TABLE products ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES vendors(id) ON DELETE SET NULL;
         CREATE INDEX IF NOT EXISTS idx_products_vendor ON products(vendor_id);`
      )
      .catch((err) => console.error('Migration notice (products_vendor_id):', err.message));

    // Ensure categories table supports burmese_name and emoji dynamically
    await pool
      .query(
        `ALTER TABLE categories
         ADD COLUMN IF NOT EXISTS burmese_name VARCHAR(150),
         ADD COLUMN IF NOT EXISTS emoji VARCHAR(32)`
      )
      .catch(() => {});

    // Populate default burmese_name and emoji for existing categories if not yet set
    await pool
      .query(
        `UPDATE categories
         SET burmese_name = CASE
               WHEN LOWER(name) LIKE '%chem%' THEN 'ဆေး/မြေသြဇာ'
               WHEN LOWER(name) LIKE '%plant%' THEN 'အပင်များ'
               WHEN LOWER(name) LIKE '%pot%' THEN 'ပန်းအိုးများ'
               WHEN LOWER(name) LIKE '%tool%' THEN 'ကိရိယာများ'
               WHEN LOWER(name) LIKE '%other%' THEN 'အခြား'
               ELSE name
             END,
             emoji = CASE
               WHEN LOWER(name) LIKE '%chem%' THEN '🧪'
               WHEN LOWER(name) LIKE '%plant%' THEN '🌱'
               WHEN LOWER(name) LIKE '%pot%' THEN '🪴'
               WHEN LOWER(name) LIKE '%tool%' THEN '✂️'
               WHEN LOWER(name) LIKE '%other%' THEN '📦'
               ELSE '🏷️'
             END
         WHERE burmese_name IS NULL OR emoji IS NULL`
      )
      .catch(() => {});

    // Ensure users table supports permission_group_id and custom_permissions
    await pool
      .query(
        `ALTER TABLE users
         ADD COLUMN IF NOT EXISTS permission_group_id VARCHAR(64),
         ADD COLUMN IF NOT EXISTS custom_permissions JSONB`
      )
      .catch(() => {});

    await pool
      .query(
        `UPDATE users
         SET permission_group_id = CASE
               WHEN role = 'owner' THEN 'pg_owner'
               WHEN role = 'manager' THEN 'pg_manager'
               WHEN role = 'stock_clerk' THEN 'pg_stock'
               ELSE 'pg_cashier'
             END
         WHERE permission_group_id IS NULL`
      )
      .catch(() => {});

    // Create and seed permission_groups table
    await pool
      .query(
        `CREATE TABLE IF NOT EXISTS permission_groups (
           id VARCHAR(64) PRIMARY KEY,
           name VARCHAR(150) NOT NULL,
           burmese_name VARCHAR(200) NOT NULL DEFAULT '',
           description TEXT NOT NULL DEFAULT '',
           icon VARCHAR(32) NOT NULL DEFAULT '🛡️',
           permissions JSONB NOT NULL DEFAULT '[]'::jsonb,
           is_built_in BOOLEAN NOT NULL DEFAULT FALSE,
           sort_order INT NOT NULL DEFAULT 0,
           created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
           updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
         )`
      )
      .catch(() => {});

    const defaultGroups = [
      {
        id: 'pg_owner',
        name: 'Super Admin / Owner',
        burmeseName: 'စူပါအက်ဒမင် (အရာရာစီမံခွင့်)',
        description:
          'ဘယ်ဘက် Menu အားလုံးနှင့် ဆက်တင်၊ ငွေစာရင်း၊ အသုံးပြုသူများကို အပြည့်အဝ စီမံခန့်ခွဲခွင့်',
        icon: '👑',
        permissions: [
          'pos',
          'orders',
          'stock',
          'transfer',
          'wastage',
          'reports',
          'settings',
          'purchases',
          'hr',
          'delete_data',
        ],
        sortOrder: 1,
      },
      {
        id: 'pg_manager',
        name: 'Branch Manager',
        burmeseName: 'ဆိုင်ခွဲမန်နေဂျာ',
        description:
          'အရောင်း၊ ဘောက်ချာ၊ ပစ္စည်းစာရင်း၊ လွှဲပြောင်း၊ ပျက်စီးစာရင်းနှင့် အစီရင်ခံစာများ ကြည့်ရှုခွင့်',
        icon: '🏢',
        permissions: [
          'pos',
          'orders',
          'stock',
          'transfer',
          'wastage',
          'reports',
          'purchases',
          'hr',
        ],
        sortOrder: 2,
      },
      {
        id: 'pg_cashier',
        name: 'Cashier / Sales Staff',
        burmeseName: 'ငွေကိုင် / အရောင်းဝန်ထမ်း',
        description:
          'နေ့စဉ် အရောင်းကောင်တာ (POS) နှင့် ယခင်ရောင်းချထားသော ဘောက်ချာများ (Orders) သာ ကြည့်ရှုအသုံးပြုခွင့်',
        icon: '💵',
        permissions: ['pos', 'orders'],
        sortOrder: 3,
      },
      {
        id: 'pg_stock',
        name: 'Inventory & Stock Clerk',
        burmeseName: 'ပစ္စည်းထိန်း / သိုလှောင်ရုံဝန်ထမ်း',
        description:
          'ပစ္စည်းစာရင်း စစ်ဆေးခြင်း (Stock)၊ ဆိုင်ခွဲလွှဲပြောင်း (Transfer) နှင့် အပင်ပျက်စီး/သေစာရင်း (Wastage) သာ သုံးစွဲခွင့်',
        icon: '📦',
        permissions: ['stock', 'transfer', 'wastage'],
        sortOrder: 4,
      },
    ];

    for (const g of defaultGroups) {
      await pool
        .query(
          `INSERT INTO permission_groups (id, name, burmese_name, description, icon, permissions, is_built_in, sort_order)
           VALUES ($1, $2, $3, $4, $5, $6::jsonb, TRUE, $7)
           ON CONFLICT (id) DO NOTHING`,
          [
            g.id,
            g.name,
            g.burmeseName,
            g.description,
            g.icon,
            JSON.stringify(g.permissions),
            g.sortOrder,
          ]
        )
        .catch(() => {});
    }

    // Ensure pg_owner has delete_data permission
    await pool
      .query(
        `UPDATE permission_groups
         SET permissions = permissions || '["delete_data"]'::jsonb
         WHERE id = 'pg_owner' AND NOT permissions @> '["delete_data"]'::jsonb`
      )
      .catch(() => {});
  })();

  app.listen(port, () => {
    console.log(`🌿 SitePyoe Backend running on port ${port}`);
    console.log(`📡 Healthcheck: http://localhost:${port}/health`);
  });
}

export default app;
