-- ============================================================
-- SitePyoe Nursery POS & Inventory System
-- PostgreSQL Migration — v2.0 : Vendors & Purchases
-- Run this AFTER 001_schema.sql
-- ============================================================

-- ============================================================
-- 11. VENDORS
-- ============================================================
CREATE TABLE vendors (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name        VARCHAR(150) NOT NULL,
  phone       VARCHAR(30),
  address     TEXT,
  notes       TEXT,
  is_active   BOOLEAN NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_vendors_name      ON vendors(name);
CREATE INDEX idx_vendors_is_active ON vendors(is_active);
SELECT create_updated_at_trigger('vendors');

-- Seed demo vendors
INSERT INTO vendors (name, phone, address) VALUES
  ('ကိုကိုမြိုင် သစ်ပင်ကုန်သည်',  '09-123-456-789', 'တောင်ဥက္ကလာ၊ ရန်ကုန်'),
  ('မြဝတီ ပြည်တွင်းပင် ပေါင်းစုံ', '09-987-654-321', 'မြဝတီ၊ ကရင်ပြည်နယ်'),
  ('Thai Green Import',              '+66-81-234-5678', 'မဲဆောက်၊ ထိုင်းနိုင်ငံ'),
  ('ရွှေဟောင်းနောင် ဆေးဝါးကုန်သည်', '09-500-111-222', 'မန္တလေး');


-- ============================================================
-- 12. PURCHASES (Purchase / Stock-In invoices)
-- ============================================================
CREATE TYPE purchase_payment_status AS ENUM ('paid', 'unpaid', 'partial');

CREATE TABLE purchases (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_no     VARCHAR(40) NOT NULL UNIQUE,  -- PO-YYYYMMDD-XXXX
  branch_id       UUID NOT NULL REFERENCES branches(id),
  vendor_id       UUID REFERENCES vendors(id) ON DELETE SET NULL,

  purchase_date   DATE NOT NULL DEFAULT CURRENT_DATE,

  subtotal        NUMERIC(14,2) NOT NULL DEFAULT 0,
  discount        NUMERIC(14,2) NOT NULL DEFAULT 0,
  total_amount    NUMERIC(14,2) NOT NULL DEFAULT 0,
  paid_amount     NUMERIC(14,2) NOT NULL DEFAULT 0,
  balance_due     NUMERIC(14,2) GENERATED ALWAYS AS (total_amount - paid_amount) STORED,

  payment_status  purchase_payment_status NOT NULL DEFAULT 'unpaid',
  notes           TEXT,

  created_by      UUID REFERENCES users(id) ON DELETE SET NULL,
  created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_purchases_branch        ON purchases(branch_id);
CREATE INDEX idx_purchases_vendor        ON purchases(vendor_id);
CREATE INDEX idx_purchases_date          ON purchases(purchase_date DESC);
CREATE INDEX idx_purchases_status        ON purchases(payment_status);
CREATE INDEX idx_purchases_purchase_no   ON purchases(purchase_no);
SELECT create_updated_at_trigger('purchases');


-- ============================================================
-- 13. PURCHASE ITEMS
-- ============================================================
CREATE TABLE purchase_items (
  id                    UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  purchase_id           UUID NOT NULL REFERENCES purchases(id) ON DELETE CASCADE,
  product_id            UUID NOT NULL REFERENCES products(id),

  -- Snapshot at time of purchase
  product_name_snapshot VARCHAR(200) NOT NULL,

  quantity              NUMERIC(10,2) NOT NULL,
  unit_cost             NUMERIC(14,2) NOT NULL,
  total_cost            NUMERIC(14,2) GENERATED ALWAYS AS (quantity * unit_cost) STORED,

  created_at            TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
CREATE INDEX idx_purchase_items_purchase ON purchase_items(purchase_id);
CREATE INDEX idx_purchase_items_product  ON purchase_items(product_id);


-- ============================================================
-- Business-logic helper function:
--   Called after purchase is confirmed to auto-increment stock
--   and update the product's cost_price to latest unit cost.
-- ============================================================
CREATE OR REPLACE FUNCTION apply_purchase_to_inventory(p_purchase_id UUID)
RETURNS VOID AS $$
DECLARE
  rec RECORD;
  p_branch_id UUID;
BEGIN
  SELECT branch_id INTO p_branch_id FROM purchases WHERE id = p_purchase_id;

  FOR rec IN
    SELECT pi.product_id, pi.quantity, pi.unit_cost
    FROM purchase_items pi
    WHERE pi.purchase_id = p_purchase_id
  LOOP
    -- Upsert branch inventory
    INSERT INTO branch_inventories (branch_id, product_id, stock_quantity)
    VALUES (p_branch_id, rec.product_id, rec.quantity)
    ON CONFLICT (branch_id, product_id)
    DO UPDATE SET
      stock_quantity = branch_inventories.stock_quantity + rec.quantity,
      updated_at     = NOW();

    -- Update product's default cost_price to latest invoice unit cost
    UPDATE products
    SET cost_price = rec.unit_cost,
        updated_at = NOW()
    WHERE id = rec.product_id;
  END LOOP;
END;
$$ LANGUAGE plpgsql;


-- ============================================================
-- VENDOR PAYABLES VIEW (outstanding vendor debts)
-- ============================================================
CREATE OR REPLACE VIEW vendor_outstanding_payables AS
  SELECT
    v.id          AS vendor_id,
    v.name        AS vendor_name,
    v.phone,
    COUNT(p.id)   AS total_invoices,
    SUM(p.total_amount) AS total_purchased,
    SUM(p.paid_amount)  AS total_paid,
    SUM(p.balance_due)  AS total_outstanding
  FROM vendors v
  LEFT JOIN purchases p ON p.vendor_id = v.id AND p.payment_status IN ('unpaid', 'partial')
  GROUP BY v.id, v.name, v.phone;

-- ============================================================
-- END OF MIGRATION v2.0
-- ============================================================
