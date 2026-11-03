-- ============================================================
-- SitePyoe Nursery POS & Inventory System
-- PostgreSQL Migration — v4.0 : Schema Fixes & Auth Tokens
-- Run this AFTER 001_schema.sql, 002_vendors_purchases.sql, 003_employees_payroll.sql
-- ============================================================

-- 1. PRODUCTS: Add image_url if not exists
ALTER TABLE products ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 2. SALES: Schema alignment with backend routes
ALTER TABLE sales ADD COLUMN IF NOT EXISTS tax_amount NUMERIC(14,2) NOT NULL DEFAULT 0;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS is_offline_created BOOLEAN NOT NULL DEFAULT FALSE;
ALTER TABLE sales ADD COLUMN IF NOT EXISTS tendered_amount NUMERIC(14,2);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'sales' AND column_name = 'amount_tendered'
  ) THEN
    UPDATE sales SET tendered_amount = amount_tendered WHERE tendered_amount IS NULL AND amount_tendered IS NOT NULL;
  END IF;
END $$;

-- 3. SALE ITEMS: Support discount_percent column alongside discount_pct
ALTER TABLE sale_items ADD COLUMN IF NOT EXISTS discount_percent NUMERIC(5,2) NOT NULL DEFAULT 0;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'sale_items' AND column_name = 'discount_pct'
  ) THEN
    UPDATE sale_items SET discount_percent = discount_pct WHERE discount_percent = 0 AND discount_pct > 0;
  END IF;
END $$;

-- 3B. WASTAGE LOGS: Add notes column if not present
ALTER TABLE wastage_logs ADD COLUMN IF NOT EXISTS notes TEXT;
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'wastage_logs' AND column_name = 'description'
  ) THEN
    UPDATE wastage_logs SET notes = description WHERE notes IS NULL AND description IS NOT NULL;
  END IF;
END $$;

-- 4. BRANCH TRANSFERS: Support transfer_no and requested_by aliases
ALTER TABLE branch_transfers ADD COLUMN IF NOT EXISTS transfer_no VARCHAR(40);
ALTER TABLE branch_transfers ADD COLUMN IF NOT EXISTS requested_by UUID REFERENCES users(id) ON DELETE SET NULL;

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branch_transfers' AND column_name = 'reference_no'
  ) THEN
    UPDATE branch_transfers SET transfer_no = reference_no WHERE transfer_no IS NULL AND reference_no IS NOT NULL;
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branch_transfers' AND column_name = 'initiated_by'
  ) THEN
    UPDATE branch_transfers SET requested_by = initiated_by WHERE requested_by IS NULL AND initiated_by IS NOT NULL;
  END IF;
END $$;

-- 5. BRANCH TRANSFER ITEMS: Support sent_quantity
ALTER TABLE branch_transfer_items ADD COLUMN IF NOT EXISTS sent_quantity NUMERIC(10,2);
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'branch_transfer_items' AND column_name = 'requested_quantity'
  ) THEN
    UPDATE branch_transfer_items SET sent_quantity = requested_quantity WHERE sent_quantity IS NULL AND requested_quantity IS NOT NULL;
  END IF;
END $$;

-- 6. SYNC AUDIT LOG: Schema fixes
ALTER TABLE sync_audit_log ADD COLUMN IF NOT EXISTS branch_id UUID REFERENCES branches(id) ON DELETE SET NULL;
ALTER TABLE sync_audit_log ADD COLUMN IF NOT EXISTS entity_name VARCHAR(60);

DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_name = 'sync_audit_log' AND column_name = 'table_name'
  ) THEN
    UPDATE sync_audit_log SET entity_name = table_name WHERE entity_name IS NULL;
  END IF;
END $$;

ALTER TABLE sync_audit_log DROP CONSTRAINT IF EXISTS sync_audit_log_operation_check;
ALTER TABLE sync_audit_log ALTER COLUMN operation TYPE VARCHAR(10);

-- 7. REFRESH TOKENS TABLE FOR JWT AUTH
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id          BIGSERIAL PRIMARY KEY,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  token_hash  TEXT NOT NULL UNIQUE,
  expires_at  TIMESTAMPTZ NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_hash ON refresh_tokens(token_hash);

-- 8. SEED INITIAL USERS (password123 for all demo accounts)
INSERT INTO users (name, email, phone, password_hash, role, is_active, branch_id)
SELECT 'Daw Hla', 'admin@sitepyoe.com', '09-790123456', '$2a$10$ctImshRTnCB5S6XV4TPfUuY/5Pr9aDpGq.EkYw6mhrE0gz7D3kcb.', 'owner'::user_role, TRUE, NULL
WHERE NOT EXISTS (SELECT 1 FROM users WHERE email = 'admin@sitepyoe.com');

INSERT INTO users (name, email, phone, password_hash, role, is_active, branch_id)
SELECT 'U Thant Zin', 'manager.a@sitepyoe.com', '09-450987654', '$2a$10$ctImshRTnCB5S6XV4TPfUuY/5Pr9aDpGq.EkYw6mhrE0gz7D3kcb.', 'manager'::user_role, TRUE, id
FROM branches WHERE name LIKE '%Branch A%' OR name LIKE '%လှိုင်%' LIMIT 1
ON CONFLICT (email) DO NOTHING;

INSERT INTO users (name, email, phone, password_hash, role, is_active, branch_id)
SELECT 'Maung Maung', 'cashier.a@sitepyoe.com', '09-250112233', '$2a$10$ctImshRTnCB5S6XV4TPfUuY/5Pr9aDpGq.EkYw6mhrE0gz7D3kcb.', 'cashier'::user_role, TRUE, id
FROM branches WHERE name LIKE '%Branch A%' OR name LIKE '%လှိုင်%' LIMIT 1
ON CONFLICT (email) DO NOTHING;

INSERT INTO users (name, email, phone, password_hash, role, is_active, branch_id)
SELECT 'Su Su Hlaing', 'cashier.b@sitepyoe.com', '09-970334455', '$2a$10$ctImshRTnCB5S6XV4TPfUuY/5Pr9aDpGq.EkYw6mhrE0gz7D3kcb.', 'cashier'::user_role, TRUE, id
FROM branches WHERE name LIKE '%Branch B%' OR name LIKE '%မြောက်ဒဂုံ%' LIMIT 1
ON CONFLICT (email) DO NOTHING;
