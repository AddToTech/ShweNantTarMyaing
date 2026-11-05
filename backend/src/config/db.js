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
const isInternalHost =
  dbUrl.includes('localhost') ||
  dbUrl.includes('127.0.0.1') ||
  dbUrl.includes('@postgres:') ||
  dbUrl.includes('@postgres/');

const requiresSsl =
  dbUrl.includes('sslmode=require') ||
  process.env.PGSSLMODE === 'require' ||
  (isProduction && !isInternalHost);

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

  const bStr = branchId.toLowerCase().trim();

  // 1. Try matching by slug / legacy name keywords
  if (bStr === 'branch_a' || bStr.includes('branch a') || bStr.includes('လှိုင်')) {
    const res = await query("SELECT id FROM branches WHERE name ILIKE '%Branch A%' OR name ILIKE '%လှိုင်%' LIMIT 1");
    if (res.rows.length > 0) return res.rows[0].id;
  }
  if (bStr === 'branch_b' || bStr.includes('branch b') || bStr.includes('မြောက်ဒဂုံ')) {
    const res = await query("SELECT id FROM branches WHERE name ILIKE '%Branch B%' OR name ILIKE '%မြောက်ဒဂုံ%' LIMIT 1");
    if (res.rows.length > 0) return res.rows[0].id;
  }

  // 2. Try matching by exact or partial name
  try {
    const byName = await query("SELECT id FROM branches WHERE name ILIKE $1 LIMIT 1", [`%${bStr}%`]);
    if (byName.rows.length > 0) return byName.rows[0].id;
  } catch (_) {}

  // 3. Positional fallback: 'branch_a' -> 1st active branch, 'branch_b' -> 2nd active branch
  if (bStr === 'branch_a') {
    const firstBranch = await query("SELECT id FROM branches WHERE is_active = TRUE ORDER BY created_at ASC, id ASC LIMIT 1");
    if (firstBranch.rows.length > 0) return firstBranch.rows[0].id;
  }
  if (bStr === 'branch_b') {
    const secondBranch = await query("SELECT id FROM branches WHERE is_active = TRUE ORDER BY created_at ASC, id ASC OFFSET 1 LIMIT 1");
    if (secondBranch.rows.length > 0) return secondBranch.rows[0].id;
    const firstBranch = await query("SELECT id FROM branches WHERE is_active = TRUE ORDER BY created_at ASC, id ASC LIMIT 1");
    if (firstBranch.rows.length > 0) return firstBranch.rows[0].id;
  }

  // 4. Default fallback: first active branch in database
  const defaultBranch = await query("SELECT id FROM branches WHERE is_active = TRUE ORDER BY created_at ASC, id ASC LIMIT 1");
  if (defaultBranch.rows.length > 0) return defaultBranch.rows[0].id;

  // 5. If no branches exist, return null — NEVER return an invalid non-UUID string
  return null;
};

/**
 * Resolves product identifier (either UUID or SKU or legacy code) to UUID
 */
export const resolveProductId = async (productId) => {
  if (!productId) return null;
  if (UUID_REGEX.test(productId)) return productId;

  try {
    const res = await query(
      'SELECT id FROM products WHERE sku ILIKE $1 OR barcode ILIKE $1 OR name ILIKE $1 LIMIT 1',
      [productId]
    );
    if (res.rows.length > 0) return res.rows[0].id;
  } catch (_) {}
  return null;
};
