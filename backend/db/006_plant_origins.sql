-- ============================================================
-- SitePyoe Nursery POS & Inventory System
-- PostgreSQL Migration — v6.0 : Dynamic Plant Origins
-- ============================================================

-- 1. Create plant_origins table
CREATE TABLE IF NOT EXISTS plant_origins (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name VARCHAR(100) NOT NULL UNIQUE,
  code VARCHAR(50),
  sort_order SMALLINT NOT NULL DEFAULT 0,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_plant_origins_is_active ON plant_origins(is_active);

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_trigger WHERE tgname = 'trg_plant_origins_updated_at'
  ) THEN
    PERFORM create_updated_at_trigger('plant_origins');
  END IF;
END $$;

-- 2. Seed initial default plant origins
INSERT INTO plant_origins (name, code, sort_order, is_active)
VALUES
  ('ယိုးဒယား Import', 'thai_import', 1, TRUE),
  ('တရုတ် Import', 'china_import', 2, TRUE),
  ('ပြည်တွင်း', 'local', 3, TRUE)
ON CONFLICT (name) DO UPDATE SET code = EXCLUDED.code;

-- 3. Convert products.origin_type to VARCHAR(100)
ALTER TABLE products ALTER COLUMN origin_type TYPE VARCHAR(100) USING origin_type::text;

-- 4. Add origin_id foreign key column to products
ALTER TABLE products ADD COLUMN IF NOT EXISTS origin_id UUID REFERENCES plant_origins(id) ON DELETE SET NULL;
CREATE INDEX IF NOT EXISTS idx_products_origin_id ON products(origin_id);

-- 5. Backfill existing products to link with plant_origins
UPDATE products p
SET origin_id = po.id
FROM plant_origins po
WHERE p.origin_id IS NULL AND (
  p.origin_type = po.code 
  OR p.origin_type = po.name
  OR (p.origin_type = 'thai_import' AND po.code = 'thai_import')
  OR (p.origin_type = 'china_import' AND po.code = 'china_import')
  OR (p.origin_type = 'local' AND po.code = 'local')
);

