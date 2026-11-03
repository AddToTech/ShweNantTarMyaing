-- ============================================================
-- SitePyoe Nursery POS & Inventory System
-- PostgreSQL Migration — v3.0 : Employee Management & Payroll
-- Run this AFTER 001_schema.sql and 002_vendors_purchases.sql
-- ============================================================

-- ============================================================
-- 14. EMPLOYEES
-- ============================================================
CREATE TABLE employees (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  branch_id     UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
  name          VARCHAR(120) NOT NULL,
  role          VARCHAR(50) NOT NULL, -- e.g. Manager, Cashier, Gardener, Delivery, Florist
  phone         VARCHAR(30),
  address       TEXT,
  basic_salary  NUMERIC(14,2) NOT NULL DEFAULT 0,
  join_date     DATE NOT NULL DEFAULT CURRENT_DATE,
  is_active     BOOLEAN NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_employees_branch     ON employees(branch_id);
CREATE INDEX idx_employees_role       ON employees(role);
CREATE INDEX idx_employees_name       ON employees(name);
CREATE INDEX idx_employees_is_active  ON employees(is_active);
SELECT create_updated_at_trigger('employees');

-- Seed demo employees
INSERT INTO employees (name, role, phone, address, basic_salary, join_date, is_active, branch_id)
SELECT
  'ဒေါ်အေးအေးဝင်း', 'Manager', '09-250-111-222', 'လှိုင်မြို့နယ်၊ ရန်ကုန်', 650000.00, '2024-03-01', TRUE, id
FROM branches WHERE name LIKE '%Branch A%' OR name LIKE '%လှိုင်%' LIMIT 1;

INSERT INTO employees (name, role, phone, address, basic_salary, join_date, is_active, branch_id)
SELECT
  'ဦးအောင်ကျော်', 'Gardener', '09-420-333-444', 'မရမ်းကုန်း၊ ရန်ကုန်', 380000.00, '2024-05-15', TRUE, id
FROM branches WHERE name LIKE '%Branch A%' OR name LIKE '%လှိုင်%' LIMIT 1;

INSERT INTO employees (name, role, phone, address, basic_salary, join_date, is_active, branch_id)
SELECT
  'မသီတာထွေး', 'Cashier', '09-790-555-666', 'ကမာရွတ်၊ ရန်ကုန်', 320000.00, '2025-01-10', TRUE, id
FROM branches WHERE name LIKE '%Branch A%' OR name LIKE '%လှိုင်%' LIMIT 1;

INSERT INTO employees (name, role, phone, address, basic_salary, join_date, is_active, branch_id)
SELECT
  'ကိုသန့်ဇင်', 'Delivery', '09-970-777-888', 'မြောက်ဒဂုံ၊ ရန်ကုန်', 350000.00, '2025-02-01', TRUE, id
FROM branches WHERE name LIKE '%Branch B%' OR name LIKE '%မြောက်ဒဂုံ%' LIMIT 1;

INSERT INTO employees (name, role, phone, address, basic_salary, join_date, is_active, branch_id)
SELECT
  'မစုစုလှိုင်', 'Florist', '09-450-999-000', 'တောင်ဒဂုံ၊ ရန်ကုန်', 330000.00, '2025-04-01', TRUE, id
FROM branches WHERE name LIKE '%Branch B%' OR name LIKE '%မြောက်ဒဂုံ%' LIMIT 1;


-- ============================================================
-- 15. PAYROLLS
-- ============================================================
-- payment_method is already defined in 001_schema.sql as ('cash', 'kpay', 'banking', 'credit')

CREATE TABLE payrolls (
  id                     UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  employee_id            UUID NOT NULL REFERENCES employees(id) ON DELETE CASCADE,
  branch_id              UUID NOT NULL REFERENCES branches(id) ON DELETE RESTRICT,
  payroll_period         VARCHAR(20) NOT NULL, -- e.g. '2026-10'
  basic_salary           NUMERIC(14,2) NOT NULL DEFAULT 0,
  bonus_amount           NUMERIC(14,2) NOT NULL DEFAULT 0,
  bonus_description      TEXT,
  deduction_amount       NUMERIC(14,2) NOT NULL DEFAULT 0,
  deduction_description  TEXT,
  net_salary             NUMERIC(14,2) GENERATED ALWAYS AS (basic_salary + bonus_amount - deduction_amount) STORED,
  payment_method         payment_method NOT NULL DEFAULT 'cash',
  payment_date           TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  paid_by                UUID REFERENCES users(id) ON DELETE SET NULL,
  notes                  TEXT,
  created_at             TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at             TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payrolls_employee ON payrolls(employee_id);
CREATE INDEX idx_payrolls_branch   ON payrolls(branch_id);
CREATE INDEX idx_payrolls_period   ON payrolls(payroll_period);
CREATE INDEX idx_payrolls_date     ON payrolls(payment_date DESC);
CREATE INDEX idx_payrolls_method   ON payrolls(payment_method);
SELECT create_updated_at_trigger('payrolls');

-- ============================================================
-- END OF MIGRATION v3.0
-- ============================================================

