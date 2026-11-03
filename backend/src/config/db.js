import pg from 'pg';
import dotenv from 'dotenv';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

dotenv.config({ path: path.resolve(__dirname, '../../.env') });
dotenv.config();

const { Pool } = pg;

const dbUrl = process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/sitepyoe';
const isProduction = process.env.NODE_ENV === 'production';
const requiresSsl =
  dbUrl.includes('sslmode=require') ||
  process.env.PGSSLMODE === 'require' ||
  (isProduction && !dbUrl.includes('localhost') && !dbUrl.includes('127.0.0.1'));

export const pool = new Pool({
  connectionString: dbUrl,
  max: 20,
  idleTimeoutMillis: 30000,
  connectionTimeoutMillis: 5000,
  ssl: requiresSsl ? { rejectUnauthorized: false } : false,
});

pool.on('error', (err) => {
  console.error('[PostgreSQL] Unexpected client error:', err);
});

export const query = (text, params) => pool.query(text, params);

const UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

/**
 * Resolves branch identifier (either UUID or slug like 'branch_a' / 'branch_b') to UUID
 */
export const resolveBranchId = async (branchId) => {
  if (!branchId || branchId === 'all') return null;
  if (UUID_REGEX.test(branchId)) return branchId;

  const bStr = branchId.toLowerCase();
  if (bStr === 'branch_a' || bStr.includes('branch a') || bStr.includes('လှိုင်')) {
    const res = await query("SELECT id FROM branches WHERE name LIKE '%Branch A%' OR name LIKE '%လှိုင်%' LIMIT 1");
    if (res.rows.length > 0) return res.rows[0].id;
  }
  if (bStr === 'branch_b' || bStr.includes('branch b') || bStr.includes('မြောက်ဒဂုံ')) {
    const res = await query("SELECT id FROM branches WHERE name LIKE '%Branch B%' OR name LIKE '%မြောက်ဒဂုံ%' LIMIT 1");
    if (res.rows.length > 0) return res.rows[0].id;
  }
  return branchId;
};

/**
 * Resolves product identifier (either UUID or SKU or legacy code) to UUID
 */
export const resolveProductId = async (productId) => {
  if (!productId) return null;
  if (UUID_REGEX.test(productId)) return productId;

  const res = await query(
    'SELECT id FROM products WHERE sku ILIKE $1 OR name ILIKE $1 LIMIT 1',
    [productId]
  );
  if (res.rows.length > 0) return res.rows[0].id;
  return productId;
};
