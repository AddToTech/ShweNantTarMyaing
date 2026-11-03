// backend/db/migrate.js
// ============================================================
// Automated PostgreSQL Database Migration & Seed Runner
// Tracks executed files in `schema_migrations` table
// ============================================================

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';
import pg from 'pg';
import dotenv from 'dotenv';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables
dotenv.config({ path: path.resolve(__dirname, '../.env') });
dotenv.config();

const { Client } = pg;

const dbUrl = process.env.DATABASE_URL || 'postgresql://postgres:password@localhost:5432/sitepyoe';
const isProduction = process.env.NODE_ENV === 'production';
const requiresSsl =
  dbUrl.includes('sslmode=require') ||
  process.env.PGSSLMODE === 'require' ||
  (isProduction && !dbUrl.includes('localhost') && !dbUrl.includes('127.0.0.1'));

console.log('🌿 SitePyoe Database Migration Runner');
console.log(`Connecting to: ${dbUrl.replace(/:[^:@]+@/, ':****@')}`);
console.log(`SSL Mode: ${requiresSsl ? 'Required ({ rejectUnauthorized: false })' : 'Disabled'}`);

const client = new Client({
  connectionString: dbUrl,
  ssl: requiresSsl ? { rejectUnauthorized: false } : false,
});

const migrationFiles = [
  '001_schema.sql',
  '002_vendors_purchases.sql',
  '003_employees_payroll.sql',
  '004_schema_fixes.sql',
];

// If '--seed' flag is passed or SEED_DB=true is set in env, include seed script
if (process.argv.includes('--seed') || process.env.SEED_DB === 'true') {
  migrationFiles.push('005_seed_catalog_and_data.sql');
}

async function runMigrations() {
  try {
    await client.connect();
    console.log('Connected to PostgreSQL successfully.\n');

    // Create migration tracking table
    await client.query(`
      CREATE TABLE IF NOT EXISTS schema_migrations (
        id SERIAL PRIMARY KEY,
        name VARCHAR(255) UNIQUE NOT NULL,
        applied_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
      );
    `);

    // Fetch already executed migrations
    const res = await client.query('SELECT name FROM schema_migrations');
    const appliedSet = new Set(res.rows.map((r) => r.name));

    // Also check if tables already exist from previous manual runs
    const checkBranches = await client.query(`
      SELECT EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_name = 'branches'
      );
    `);
    const tablesAlreadyExist = checkBranches.rows[0].exists;

    for (const file of migrationFiles) {
      const filePath = path.resolve(__dirname, file);
      if (!fs.existsSync(filePath)) {
        console.warn(`⚠️ Warning: Migration file not found: ${file}`);
        continue;
      }

      if (appliedSet.has(file)) {
        console.log(`⏩ [ALREADY APPLIED] Skipping ${file}`);
        continue;
      }

      // If database already had tables initialized before migration tracking existed,
      // record initial DDLs as applied
      if (tablesAlreadyExist && (file === '001_schema.sql' || file === '002_vendors_purchases.sql' || file === '003_employees_payroll.sql')) {
        console.log(`⏩ [EXISTING DB DETECTED] Recording ${file} as previously applied.`);
        await client.query(
          'INSERT INTO schema_migrations (name) VALUES ($1) ON CONFLICT DO NOTHING',
          [file]
        );
        continue;
      }

      console.log(`⏳ Executing ${file}...`);
      const sql = fs.readFileSync(filePath, 'utf-8');
      await client.query(sql);
      await client.query(
        'INSERT INTO schema_migrations (name) VALUES ($1) ON CONFLICT DO NOTHING',
        [file]
      );
      console.log(`✅ ${file} applied successfully.\n`);
    }

    console.log('🎉 All migrations completed successfully!');
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    if (err.position) {
      console.error(`Position: ${err.position}`);
    }
    process.exit(1);
  } finally {
    await client.end();
  }
}

runMigrations();
