-- ============================================================
-- 005_seed_catalog_and_data.sql
-- Seed complete 26-product catalog, categories, subcategories,
-- branch inventories, and initial transactions into PostgreSQL
-- ============================================================

DO $$
DECLARE
  v_branch_a UUID;
  v_branch_b UUID;
  v_cat_plants UUID;
  v_cat_pots UUID;
  v_cat_chem UUID;
  v_cat_tools UUID;
  v_cat_others UUID;

  -- Subcategories
  v_sub_thitkwa UUID;
  v_sub_indoor UUID;
  v_sub_hnit_hla UUID;
  v_sub_hnit_thee UUID;
  v_sub_myosei UUID;
  v_sub_general UUID;

  v_sub_kywe UUID;
  v_sub_mye UUID;
  v_sub_bonsai UUID;
  v_sub_sint UUID;
  v_sub_kaw UUID;
  v_sub_concrete UUID;

  v_sub_npk UUID;
  v_sub_root UUID;
  v_sub_bloom UUID;

  v_sub_shear UUID;
  v_sub_watering UUID;
  v_sub_spade UUID;
  v_sub_knife UUID;

  v_sub_compost UUID;
  v_sub_gravel UUID;
BEGIN
  -- 1. Fetch Branches
  SELECT id INTO v_branch_a FROM branches WHERE name LIKE '%Branch A%' LIMIT 1;
  SELECT id INTO v_branch_b FROM branches WHERE name LIKE '%Branch B%' LIMIT 1;

  -- 2. Ensure Categories
  INSERT INTO categories (name, sort_order)
  VALUES 
    ('Plants', 1),
    ('Pots', 2),
    ('Plant Chemicals', 3),
    ('Gardening Tools', 4),
    ('Others', 5)
  ON CONFLICT (name) DO UPDATE SET sort_order = EXCLUDED.sort_order;

  SELECT id INTO v_cat_plants FROM categories WHERE name = 'Plants';
  SELECT id INTO v_cat_pots FROM categories WHERE name = 'Pots';
  SELECT id INTO v_cat_chem FROM categories WHERE name = 'Plant Chemicals';
  SELECT id INTO v_cat_tools FROM categories WHERE name = 'Gardening Tools';
  SELECT id INTO v_cat_others FROM categories WHERE name = 'Others';

  -- 3. Ensure Subcategories
  INSERT INTO subcategories (category_id, name, sort_order) VALUES
    (v_cat_plants, 'သစ်ခွ', 1),
    (v_cat_plants, 'Indoor ပင်', 2),
    (v_cat_plants, 'နှစ်ရှည်အလှပင်', 3),
    (v_cat_plants, 'နှစ်ရှည်အသီးပင်', 4),
    (v_cat_plants, 'မျိုးစေ့', 5),
    (v_cat_plants, 'အထွေထွေ', 6),
    (v_cat_pots, 'ကြွေအိုး', 1),
    (v_cat_pots, 'မြေအိုး', 2),
    (v_cat_pots, 'ဘွန်စိုင်း', 3),
    (v_cat_pots, 'စဥ့်အိုး', 4),
    (v_cat_pots, 'ကော်အိုး', 5),
    (v_cat_pots, 'ကွန်ကရစ်', 6),
    (v_cat_chem, '၁၅-၁၆ ပတ်လည်', 1),
    (v_cat_chem, 'အမြစ်ဆေး', 2),
    (v_cat_chem, 'အပွင့်ဆေး', 3),
    (v_cat_tools, 'ကိုင်းညှပ်', 1),
    (v_cat_tools, 'ရေလောင်း', 2),
    (v_cat_tools, 'မြေတူး', 3),
    (v_cat_tools, 'ဓား', 4),
    (v_cat_others, 'မြေဆွေး', 1),
    (v_cat_others, 'ကျောက်စရစ်', 2)
  ON CONFLICT DO NOTHING;

  SELECT id INTO v_sub_thitkwa FROM subcategories WHERE category_id = v_cat_plants AND name = 'သစ်ခွ' LIMIT 1;
  SELECT id INTO v_sub_indoor FROM subcategories WHERE category_id = v_cat_plants AND name = 'Indoor ပင်' LIMIT 1;
  SELECT id INTO v_sub_hnit_hla FROM subcategories WHERE category_id = v_cat_plants AND name = 'နှစ်ရှည်အလှပင်' LIMIT 1;
  SELECT id INTO v_sub_hnit_thee FROM subcategories WHERE category_id = v_cat_plants AND name = 'နှစ်ရှည်အသီးပင်' LIMIT 1;
  SELECT id INTO v_sub_myosei FROM subcategories WHERE category_id = v_cat_plants AND name = 'မျိုးစေ့' LIMIT 1;
  SELECT id INTO v_sub_general FROM subcategories WHERE category_id = v_cat_plants AND name = 'အထွေထွေ' LIMIT 1;

  SELECT id INTO v_sub_kywe FROM subcategories WHERE category_id = v_cat_pots AND name = 'ကြွေအိုး' LIMIT 1;
  SELECT id INTO v_sub_mye FROM subcategories WHERE category_id = v_cat_pots AND name = 'မြေအိုး' LIMIT 1;
  SELECT id INTO v_sub_bonsai FROM subcategories WHERE category_id = v_cat_pots AND name = 'ဘွန်စိုင်း' LIMIT 1;
  SELECT id INTO v_sub_sint FROM subcategories WHERE category_id = v_cat_pots AND name = 'စဥ့်အိုး' LIMIT 1;
  SELECT id INTO v_sub_kaw FROM subcategories WHERE category_id = v_cat_pots AND name = 'ကော်အိုး' LIMIT 1;
  SELECT id INTO v_sub_concrete FROM subcategories WHERE category_id = v_cat_pots AND name = 'ကွန်ကရစ်' LIMIT 1;

  SELECT id INTO v_sub_npk FROM subcategories WHERE category_id = v_cat_chem AND name = '၁၅-၁၆ ပတ်လည်' LIMIT 1;
  SELECT id INTO v_sub_root FROM subcategories WHERE category_id = v_cat_chem AND name = 'အမြစ်ဆေး' LIMIT 1;
  SELECT id INTO v_sub_bloom FROM subcategories WHERE category_id = v_cat_chem AND name = 'အပွင့်ဆေး' LIMIT 1;

  SELECT id INTO v_sub_shear FROM subcategories WHERE category_id = v_cat_tools AND name = 'ကိုင်းညှပ်' LIMIT 1;
  SELECT id INTO v_sub_watering FROM subcategories WHERE category_id = v_cat_tools AND name = 'ရေလောင်း' LIMIT 1;
  SELECT id INTO v_sub_spade FROM subcategories WHERE category_id = v_cat_tools AND name = 'မြေတူး' LIMIT 1;
  SELECT id INTO v_sub_knife FROM subcategories WHERE category_id = v_cat_tools AND name = 'ဓား' LIMIT 1;

  SELECT id INTO v_sub_compost FROM subcategories WHERE category_id = v_cat_others AND name = 'မြေဆွေး' LIMIT 1;
  SELECT id INTO v_sub_gravel FROM subcategories WHERE category_id = v_cat_others AND name = 'ကျောက်စရစ်' LIMIT 1;

  -- 4. Helper temporary table to insert products and inventories
  CREATE TEMP TABLE temp_seed_products (
    id UUID,
    category_id UUID,
    subcategory_id UUID,
    name VARCHAR(200),
    sku VARCHAR(60),
    barcode VARCHAR(60),
    cost_price NUMERIC(14,2),
    sale_price NUMERIC(14,2),
    origin_type origin_type,
    size_label VARCHAR(40),
    emoji VARCHAR(20),
    stock_a NUMERIC(10,2),
    stock_b NUMERIC(10,2),
    min_stock NUMERIC(10,2)
  ) ON COMMIT DROP;

  -- Insert 26 products
  INSERT INTO temp_seed_products VALUES
    ('00000000-0000-0000-0000-000000000001'::uuid, v_cat_plants, v_sub_thitkwa, 'လိပ်ပြာသစ်ခွ', 'PLT-001', '1234567890', 15000, 25000, 'thai_import', '4 inch', '🌸', 12, 6, 5),
    ('00000000-0000-0000-0000-000000000002'::uuid, v_cat_plants, v_sub_indoor, 'ရွှေငွေကျောက်မျက်ပင်', 'PLT-002', '1234567891', 10000, 18000, 'china_import', '6 inch', '🌳', 8, 4, 5),
    ('00000000-0000-0000-0000-000000000003'::uuid, v_cat_plants, v_sub_hnit_hla, 'စက္ကူပန်းပင်', 'PLT-003', '1234567892', 4500, 8000, 'local', 'Medium', '🌺', 25, 15, 5),
    ('00000000-0000-0000-0000-000000000004'::uuid, v_cat_plants, v_sub_hnit_thee, 'စိန်တစ်လုံး သရက်ကိုင်းဆက်', 'PLT-004', '1234567893', 9000, 15000, 'local', 'Small', '🥭', 15, 8, 5),
    ('00000000-0000-0000-0000-000000000005'::uuid, v_cat_plants, v_sub_indoor, 'ငြိမ်းချမ်းရေး နှင်းပန်း', 'PLT-005', '1234567894', 7000, 12000, 'thai_import', '5 inch', '🌼', 4, 2, 5),
    ('00000000-0000-0000-0000-000000000006'::uuid, v_cat_plants, v_sub_myosei, 'စံပယ်မျိုးစေ့ (၅၀ ဂရမ်)', 'PLT-006', '1234567895', 2000, 3500, 'local', NULL, '🌱', 40, 20, 10),
    ('00000000-0000-0000-0000-000000000007'::uuid, v_cat_plants, v_sub_hnit_hla, 'သဲကန္တာရနှင်းဆီ', 'PLT-007', '1234567896', 13000, 22000, 'thai_import', 'Large', '🌹', 7, 3, 5),
    ('00000000-0000-0000-0000-000000000008'::uuid, v_cat_plants, v_sub_indoor, 'ကံကောင်းခြင်း ဝါးပင်', 'PLT-008', '1234567897', 5500, 9500, 'china_import', '3-tier', '🎋', 3, 5, 5),
    ('00000000-0000-0000-0000-000000000009'::uuid, v_cat_plants, v_sub_hnit_hla, 'ထိုင်းနှင်းဆီနီပင်', 'PLT-009', '1234567898', 20000, 35000, 'thai_import', 'XL', '🌷', 5, 2, 3),
    ('00000000-0000-0000-0000-000000000010'::uuid, v_cat_plants, v_sub_general, 'ညောင်ဘွန်ဆိုင်းပင်', 'PLT-010', '1234567899', 28000, 45000, 'local', '8 inch', '🌲', 0, 1, 2),

    ('00000000-0000-0000-0000-000000000011'::uuid, v_cat_pots, v_sub_kywe, 'အပြာရောင် ကြွေပန်းအိုး', 'POT-001', '2234567890', 7500, 12000, NULL, '8 inch', '🏺', 20, 10, 5),
    ('00000000-0000-0000-0000-000000000012'::uuid, v_cat_pots, v_sub_mye, 'မြေနီပန်းအိုး', 'POT-002', '2234567891', 2500, 4500, NULL, '6 inch', '🪴', 50, 30, 10),
    ('00000000-0000-0000-0000-000000000013'::uuid, v_cat_pots, v_sub_bonsai, 'ဘွန်ဆိုင်းစိုက် ပန်းအိုး', 'POT-003', '2234567892', 11000, 18000, NULL, '10 inch', '🎍', 8, 4, 3),
    ('00000000-0000-0000-0000-000000000014'::uuid, v_cat_pots, v_sub_sint, 'ကြွေရောင်စုံ အဝိုင်းပန်းအိုး', 'POT-004', '2234567893', 9000, 15000, NULL, '9 inch', '🏺', 12, 6, 4),
    ('00000000-0000-0000-0000-000000000015'::uuid, v_cat_pots, v_sub_kaw, 'ပျိုးပင်စိုက် ပလတ်စတစ်အိုး (၁၀ လုံးတွဲ)', 'POT-005', '2234567894', 2000, 3500, NULL, '4 inch', '🪣', 100, 50, 20),
    ('00000000-0000-0000-0000-000000000016'::uuid, v_cat_pots, v_sub_concrete, 'ကွန်ကရစ် လေးထောင့်ပန်းအိုး', 'POT-006', '2234567895', 22000, 35000, NULL, '12 inch', '🧱', 5, 3, 2),

    ('00000000-0000-0000-0000-000000000017'::uuid, v_cat_chem, v_sub_npk, 'NPK ၁၅-၁၅-၁၅ ဓာတ်မြေသြဇာ (၁ ကီလို)', 'CHM-001', '9876543210', 4000, 6500, NULL, NULL, '🧪', 35, 18, 10),
    ('00000000-0000-0000-0000-000000000018'::uuid, v_cat_chem, v_sub_root, 'အမြစ်အားဆေးရည် (၅၀၀ မီလီ)', 'CHM-002', '3234567891', 7500, 12000, NULL, NULL, '💧', 20, 10, 5),
    ('00000000-0000-0000-0000-000000000019'::uuid, v_cat_chem, v_sub_bloom, 'အပွင့်အားဆေးရည် (၂၅၀ မီလီ)', 'CHM-003', '3234567892', 6000, 9500, NULL, NULL, '🌸', 18, 8, 5),
    ('00000000-0000-0000-0000-000000000020'::uuid, v_cat_chem, v_sub_npk, 'NPK ၁၆-၁၆-၁၆ ပတ်လည် မြေသြဇာ (၁ ကီလို)', 'CHM-004', '3234567893', 9000, 15000, NULL, NULL, '🧴', 10, 5, 4),

    ('00000000-0000-0000-0000-000000000021'::uuid, v_cat_tools, v_sub_shear, 'အပင်ကိုင်းညှပ် ကတ်ကြေး', 'TL-001', '4234567890', 13000, 22000, NULL, NULL, '✂️', 15, 6, 4),
    ('00000000-0000-0000-0000-000000000022'::uuid, v_cat_tools, v_sub_watering, 'ရေလောင်းကရား (၅ လီတာ)', 'TL-002', '4234567891', 11000, 18000, NULL, NULL, '🚿', 8, 4, 3),
    ('00000000-0000-0000-0000-000000000023'::uuid, v_cat_tools, v_sub_spade, 'ဥယျာဉ် မြေတူးဂေါ်ပြားတွဲ', 'TL-003', '4234567892', 7000, 12000, NULL, NULL, '⛏️', 20, 12, 5),
    ('00000000-0000-0000-0000-000000000024'::uuid, v_cat_tools, v_sub_knife, 'ကိုင်းဆက် ဓားမ', 'TL-004', '4234567893', 5000, 8500, NULL, NULL, '🔪', 25, 10, 5),

    ('00000000-0000-0000-0000-000000000025'::uuid, v_cat_others, v_sub_compost, 'အပင်စိုက်မြေဆွေး (၅ လီတာ)', 'OTH-001', '5234567890', 5000, 8000, NULL, NULL, '🌍', 45, 25, 10),
    ('00000000-0000-0000-0000-000000000026'::uuid, v_cat_others, v_sub_gravel, 'အလှဆင် ကျောက်စရစ်ခဲ (၁ ကီလို)', 'OTH-002', '5234567891', 2500, 4500, NULL, NULL, '🪨', 30, 15, 10);

  -- Upsert products into products table
  INSERT INTO products (
    id, category_id, subcategory_id, name, sku, barcode, cost_price, sale_price,
    origin_type, size_label, unit_of_measure, attributes, is_active
  )
  SELECT
    t.id, t.category_id, t.subcategory_id, t.name, t.sku, t.barcode, t.cost_price, t.sale_price,
    t.origin_type, t.size_label, 'piece', jsonb_build_object('imageEmoji', t.emoji), TRUE
  FROM temp_seed_products t
  ON CONFLICT (id) DO UPDATE SET
    name = EXCLUDED.name,
    cost_price = EXCLUDED.cost_price,
    sale_price = EXCLUDED.sale_price,
    origin_type = EXCLUDED.origin_type,
    size_label = EXCLUDED.size_label,
    attributes = EXCLUDED.attributes;

  -- Upsert inventories for Branch A
  INSERT INTO branch_inventories (branch_id, product_id, stock_quantity, min_alert_threshold)
  SELECT v_branch_a, t.id, t.stock_a, t.min_stock
  FROM temp_seed_products t
  WHERE v_branch_a IS NOT NULL
  ON CONFLICT (branch_id, product_id) DO UPDATE SET
    stock_quantity = EXCLUDED.stock_quantity,
    min_alert_threshold = EXCLUDED.min_alert_threshold;

  -- Upsert inventories for Branch B
  INSERT INTO branch_inventories (branch_id, product_id, stock_quantity, min_alert_threshold)
  SELECT v_branch_b, t.id, t.stock_b, t.min_stock
  FROM temp_seed_products t
  WHERE v_branch_b IS NOT NULL
  ON CONFLICT (branch_id, product_id) DO UPDATE SET
    stock_quantity = EXCLUDED.stock_quantity,
    min_alert_threshold = EXCLUDED.min_alert_threshold;

END $$;

