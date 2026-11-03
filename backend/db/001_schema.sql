-- ============================================================
-- SitePyoe Nursery POS & Inventory System
-- PostgreSQL Schema — DDL v1.0
-- ============================================================

-- Enable UUID generation
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- UTILITY: Automatic updated_at trigger function
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Helper macro to attach the trigger to any table
CREATE OR REPLACE FUNCTION create_updated_at_trigger(tbl TEXT)
RETURNS VOID AS $$
BEGIN
  EXECUTE format(
    'CREATE TRIGGER trg_%s_updated_at
     BEFORE UPDATE ON %I
     FOR EACH ROW EXECUTE FUNCTION set_updated_at()',
    tbl, tbl
  );
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- 1. BRANCHES
-- ============================================================
CREATE TABLE branches (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(120) NOT NULL,
  address     TEXT,
  phone       VARCHAR(30),
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
SELECT create_updated_at_trigger('branches');

INSERT INTO branches (name, address) VALUES
  ('SitePyoe Branch A', 'Address A, Yangon'),
  ('SitePyoe Branch B', 'Address B, Yangon');


-- ============================================================
-- 2. ROLES & USERS
-- ============================================================
CREATE TYPE user_role AS ENUM ('owner', 'manager', 'cashier', 'stock_clerk');

CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id     UUID REFERENCES branches(id) ON DELETE SET NULL,
  name          VARCHAR(120) NOT NULL,
  email         VARCHAR(254) UNIQUE,
  phone         VARCHAR(30),
  password_hash TEXT NOT NULL,
  role          user_role NOT NULL DEFAULT 'cashier',
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  last_login_at TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_users_branch    ON users(branch_id);
CREATE INDEX idx_users_role      ON users(role);
CREATE INDEX idx_users_is_active ON users(is_active);
SELECT create_updated_at_trigger('users');


-- ============================================================
-- 3. CATEGORIES & SUBCATEGORIES
-- ============================================================
CREATE TABLE categories (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(80) NOT NULL UNIQUE,
  sort_order  SMALLINT NOT NULL DEFAULT 0,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
SELECT create_updated_at_trigger('categories');

CREATE TABLE subcategories (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id  UUID NOT NULL REFERENCES categories(id) ON DELETE CASCADE,
  name         VARCHAR(80) NOT NULL,
  sort_order   SMALLINT NOT NULL DEFAULT 0,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (category_id, name)
);
CREATE INDEX idx_subcategories_category ON subcategories(category_id);
SELECT create_updated_at_trigger('subcategories');

-- Seed: Categories
INSERT INTO categories (name, sort_order) VALUES
  ('Plants',          1),
  ('Pots',            2),
  ('Plant Chemicals', 3),
  ('Gardening Tools', 4),
  ('Others',          5);

-- Seed: Plant subcategories
WITH cat AS (SELECT id FROM categories WHERE name = 'Plants')
INSERT INTO subcategories (category_id, name, sort_order) VALUES
  ((SELECT id FROM cat), 'Perennial Ornamental', 1),
  ((SELECT id FROM cat), 'Perennial Fruit',      2),
  ((SELECT id FROM cat), 'Indoor',               3),
  ((SELECT id FROM cat), 'Orchid',               4),
  ((SELECT id FROM cat), 'Seed',                 5),
  ((SELECT id FROM cat), 'General',              6);

-- Seed: Pot subcategories
WITH cat AS (SELECT id FROM categories WHERE name = 'Pots')
INSERT INTO subcategories (category_id, name, sort_order) VALUES
  ((SELECT id FROM cat), 'Ceramic',  1),
  ((SELECT id FROM cat), 'Plastic',  2),
  ((SELECT id FROM cat), 'Bonsai',   3),
  ((SELECT id FROM cat), 'Concrete', 4),
  ((SELECT id FROM cat), 'Glazed',   5),
  ((SELECT id FROM cat), 'Clay',     6);


-- ============================================================
-- 4. PRODUCTS
-- ============================================================
CREATE TYPE origin_type AS ENUM ('thai_import', 'china_import', 'local');

CREATE TABLE products (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category_id      UUID NOT NULL REFERENCES categories(id),
  subcategory_id   UUID REFERENCES subcategories(id),

  name             VARCHAR(200) NOT NULL,
  sku              VARCHAR(60)  UNIQUE,
  barcode          VARCHAR(60)  UNIQUE,

  -- Pricing in MMK Kyat
  cost_price       NUMERIC(14,2) NOT NULL DEFAULT 0,
  sale_price       NUMERIC(14,2) NOT NULL DEFAULT 0,

  -- Plant-specific (null for other categories)
  origin_type      origin_type,
  size_label       VARCHAR(40),  -- e.g. "6 inch", "Small", "XL"

  -- Chemical-specific
  expiry_date      DATE,
  unit_of_measure  VARCHAR(30) NOT NULL DEFAULT 'piece',  -- piece, bag, litre, pot

  -- Flexible extra attributes (brand, colour, weight, NPK ratio, etc.)
  attributes       JSONB NOT NULL DEFAULT '{}',

  is_active        BOOLEAN NOT NULL DEFAULT TRUE,

  created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_products_category    ON products(category_id);
CREATE INDEX idx_products_subcategory ON products(subcategory_id);
CREATE INDEX idx_products_barcode     ON products(barcode);
CREATE INDEX idx_products_sku         ON products(sku);
CREATE INDEX idx_products_origin_type ON products(origin_type);
CREATE INDEX idx_products_is_active   ON products(is_active);
CREATE INDEX idx_products_attributes  ON products USING GIN(attributes);
SELECT create_updated_at_trigger('products');


-- ============================================================
-- 5. BRANCH INVENTORIES
-- ============================================================
CREATE TABLE branch_inventories (
  id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id           UUID NOT NULL REFERENCES branches(id) ON DELETE CASCADE,
  product_id          UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,

  stock_quantity      NUMERIC(10,2) NOT NULL DEFAULT 0,
  min_alert_threshold NUMERIC(10,2) NOT NULL DEFAULT 0,

  last_counted_at     TIMESTAMPTZ,
  last_counted_by     UUID REFERENCES users(id) ON DELETE SET NULL,

  updated_at          TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (branch_id, product_id)
);
CREATE INDEX idx_branch_inv_branch  ON branch_inventories(branch_id);
CREATE INDEX idx_branch_inv_product ON branch_inventories(product_id);
-- Partial index: fast low-stock alert queries
CREATE INDEX idx_branch_inv_low_stock
  ON branch_inventories(branch_id, product_id)
  WHERE stock_quantity <= min_alert_threshold;
SELECT create_updated_at_trigger('branch_inventories');


-- ============================================================
-- 6. SALES & SALE ITEMS
-- ============================================================
CREATE TYPE payment_method AS ENUM ('cash', 'kpay', 'banking', 'credit');
CREATE TYPE sale_status     AS ENUM ('completed', 'voided', 'refunded');

CREATE TABLE sales (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id       UUID NOT NULL REFERENCES branches(id),
  cashier_id      UUID REFERENCES users(id) ON DELETE SET NULL,

  -- Receipt reference (e.g. BRA-20261013-0001)
  receipt_no      VARCHAR(40) NOT NULL UNIQUE,

  subtotal        NUMERIC(14,2) NOT NULL DEFAULT 0,
  discount_amount NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_amount    NUMERIC(14,2) NOT NULL DEFAULT 0,

  payment_method  payment_method NOT NULL DEFAULT 'cash',
  amount_tendered NUMERIC(14,2),
  change_amount   NUMERIC(14,2),

  -- Credit / debt tracking
  customer_name   VARCHAR(120),
  customer_phone  VARCHAR(30),
  is_debt_cleared BOOLEAN NOT NULL DEFAULT TRUE,
  debt_cleared_at TIMESTAMPTZ,

  status          sale_status NOT NULL DEFAULT 'completed',
  notes           TEXT,

  sold_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_sales_branch     ON sales(branch_id);
CREATE INDEX idx_sales_cashier    ON sales(cashier_id);
CREATE INDEX idx_sales_sold_at    ON sales(sold_at DESC);
CREATE INDEX idx_sales_payment    ON sales(payment_method);
CREATE INDEX idx_sales_status     ON sales(status);
CREATE INDEX idx_sales_receipt_no ON sales(receipt_no);
SELECT create_updated_at_trigger('sales');

CREATE TABLE sale_items (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  sale_id      UUID NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id   UUID NOT NULL REFERENCES products(id),

  product_name VARCHAR(200) NOT NULL,   -- Snapshot at time of sale
  unit_price   NUMERIC(14,2) NOT NULL,
  quantity     NUMERIC(10,2) NOT NULL,
  discount_pct NUMERIC(5,2)  NOT NULL DEFAULT 0,
  line_total   NUMERIC(14,2) NOT NULL,

  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_sale_items_sale    ON sale_items(sale_id);
CREATE INDEX idx_sale_items_product ON sale_items(product_id);


-- ============================================================
-- 7. BRANCH TRANSFERS & TRANSFER ITEMS
-- ============================================================
CREATE TYPE transfer_status AS ENUM ('pending', 'in_transit', 'received', 'cancelled');

CREATE TABLE branch_transfers (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  from_branch_id  UUID NOT NULL REFERENCES branches(id),
  to_branch_id    UUID NOT NULL REFERENCES branches(id),

  reference_no    VARCHAR(40) NOT NULL UNIQUE,  -- e.g. TRF-20261013-0001
  status          transfer_status NOT NULL DEFAULT 'pending',
  notes           TEXT,

  initiated_by    UUID REFERENCES users(id) ON DELETE SET NULL,
  received_by     UUID REFERENCES users(id) ON DELETE SET NULL,

  dispatched_at   TIMESTAMPTZ,
  received_at     TIMESTAMPTZ,

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  CHECK (from_branch_id <> to_branch_id)
);
CREATE INDEX idx_transfers_from   ON branch_transfers(from_branch_id);
CREATE INDEX idx_transfers_to     ON branch_transfers(to_branch_id);
CREATE INDEX idx_transfers_status ON branch_transfers(status);
SELECT create_updated_at_trigger('branch_transfers');

CREATE TABLE branch_transfer_items (
  id                 UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transfer_id        UUID NOT NULL REFERENCES branch_transfers(id) ON DELETE CASCADE,
  product_id         UUID NOT NULL REFERENCES products(id),

  product_name       VARCHAR(200) NOT NULL,
  requested_quantity NUMERIC(10,2) NOT NULL,
  received_quantity  NUMERIC(10,2),   -- NULL until receiver confirms
  unit_cost          NUMERIC(14,2) NOT NULL DEFAULT 0,

  created_at         TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_transfer_items_transfer ON branch_transfer_items(transfer_id);
CREATE INDEX idx_transfer_items_product  ON branch_transfer_items(product_id);


-- ============================================================
-- 8. WASTAGE LOGS
-- ============================================================
CREATE TYPE wastage_reason AS ENUM (
  'mortality',      -- Plant died naturally
  'pest_disease',   -- Pest or disease damage
  'weather_damage', -- Sun-scorch, frost, storm
  'physical_damage',-- Breakage (pots, tools)
  'theft',
  'expiry',         -- Chemicals past expiry date
  'quality_reject', -- Returned / unsellable quality
  'other'
);

CREATE TABLE wastage_logs (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id       UUID NOT NULL REFERENCES branches(id),
  product_id      UUID NOT NULL REFERENCES products(id),

  product_name    VARCHAR(200) NOT NULL,
  quantity        NUMERIC(10,2) NOT NULL,
  unit_cost       NUMERIC(14,2) NOT NULL DEFAULT 0,
  -- GENERATED column: total monetary loss
  total_cost_loss NUMERIC(14,2) GENERATED ALWAYS AS (quantity * unit_cost) STORED,

  reason          wastage_reason NOT NULL DEFAULT 'other',
  description     TEXT,
  photo_url       TEXT,

  recorded_by     UUID REFERENCES users(id) ON DELETE SET NULL,
  recorded_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_wastage_branch   ON wastage_logs(branch_id);
CREATE INDEX idx_wastage_product  ON wastage_logs(product_id);
CREATE INDEX idx_wastage_reason   ON wastage_logs(reason);
CREATE INDEX idx_wastage_recorded ON wastage_logs(recorded_at DESC);
SELECT create_updated_at_trigger('wastage_logs');


-- ============================================================
-- 9. PRODUCT BATCHES (Barcode / batch tracking)
-- ============================================================
CREATE TABLE product_batches (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  product_id   UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  branch_id    UUID NOT NULL REFERENCES branches(id),

  batch_no     VARCHAR(60) NOT NULL,
  barcode      VARCHAR(60),
  quantity     NUMERIC(10,2) NOT NULL,
  cost_price   NUMERIC(14,2) NOT NULL DEFAULT 0,
  expiry_date  DATE,

  received_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  received_by  UUID REFERENCES users(id) ON DELETE SET NULL,
  notes        TEXT,

  created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at   TIMESTAMPTZ NOT NULL DEFAULT NOW(),

  UNIQUE (product_id, batch_no)
);
CREATE INDEX idx_batches_product ON product_batches(product_id);
CREATE INDEX idx_batches_branch  ON product_batches(branch_id);
CREATE INDEX idx_batches_barcode ON product_batches(barcode);
CREATE INDEX idx_batches_expiry  ON product_batches(expiry_date);
SELECT create_updated_at_trigger('product_batches');


-- ============================================================
-- 10. SYNC / AUDIT LOG (offline-first conflict resolution)
-- ============================================================
CREATE TABLE sync_audit_log (
  id          BIGSERIAL PRIMARY KEY,
  table_name  VARCHAR(60) NOT NULL,
  record_id   UUID NOT NULL,
  operation   CHAR(1) NOT NULL CHECK (operation IN ('I','U','D')),
  changed_by  UUID REFERENCES users(id) ON DELETE SET NULL,
  payload     JSONB,
  synced_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_sync_log_table     ON sync_audit_log(table_name);
CREATE INDEX idx_sync_log_record    ON sync_audit_log(record_id);
CREATE INDEX idx_sync_log_synced_at ON sync_audit_log(synced_at DESC);

-- ============================================================
-- END OF SCHEMA
-- ============================================================
