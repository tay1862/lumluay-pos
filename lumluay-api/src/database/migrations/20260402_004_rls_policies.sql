-- Migration: 20260402_004_rls_policies
-- Purpose: Enable Row Level Security on all tenant-scoped tables
-- Task: 1.1.24
--
-- IMPORTANT: The application must execute the following before any tenant query:
--   SELECT set_config('app.tenant_id', '<uuid>', false);
-- This is done automatically by TenantRlsInterceptor.
--
-- The application DB role must NOT be a superuser (superusers bypass RLS).
-- Use a role created with: CREATE ROLE app_user LOGIN PASSWORD '...';
-- Grant table access to that role and run these migrations as a superuser/owner.

-- ─── Helper: create the app_user role if it doesn't exist ─────────────────────
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'app_user') THEN
    -- Password should be set via ALTER ROLE outside of migrations
    CREATE ROLE app_user LOGIN;
  END IF;
END
$$;

-- ─── Grant schema usage to app_user ───────────────────────────────────────────
GRANT USAGE ON SCHEMA public TO app_user;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO app_user;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_user;

-- ─── Enable RLS on tenant-scoped tables ───────────────────────────────────────
ALTER TABLE tenants                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE users                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE store_settings          ENABLE ROW LEVEL SECURITY;
ALTER TABLE categories              ENABLE ROW LEVEL SECURITY;
ALTER TABLE products                ENABLE ROW LEVEL SECURITY;
ALTER TABLE product_variants        ENABLE ROW LEVEL SECURITY;
ALTER TABLE modifier_groups         ENABLE ROW LEVEL SECURITY;
ALTER TABLE modifier_options        ENABLE ROW LEVEL SECURITY;
ALTER TABLE unit_conversions        ENABLE ROW LEVEL SECURITY;
ALTER TABLE "tables"                ENABLE ROW LEVEL SECURITY;
ALTER TABLE zones                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE orders                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE order_items             ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments                ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_levels            ENABLE ROW LEVEL SECURITY;
ALTER TABLE stock_movements         ENABLE ROW LEVEL SECURITY;
ALTER TABLE members                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE shifts                  ENABLE ROW LEVEL SECURITY;
ALTER TABLE coupons                 ENABLE ROW LEVEL SECURITY;
ALTER TABLE queue                   ENABLE ROW LEVEL SECURITY;
ALTER TABLE kitchen_tickets         ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs              ENABLE ROW LEVEL SECURITY;
ALTER TABLE sync_queue              ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications           ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions           ENABLE ROW LEVEL SECURITY;

-- ─── Tenants table: each tenant can only see itself ───────────────────────────
DROP POLICY IF EXISTS tenant_isolation ON tenants;
CREATE POLICY tenant_isolation ON tenants
  USING (id = current_setting('app.tenant_id', true)::uuid);

-- ─── Macro: policies for tables with a direct tenant_id column ────────────────
-- users
DROP POLICY IF EXISTS tenant_isolation ON users;
CREATE POLICY tenant_isolation ON users
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- store_settings
DROP POLICY IF EXISTS tenant_isolation ON store_settings;
CREATE POLICY tenant_isolation ON store_settings
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- categories
DROP POLICY IF EXISTS tenant_isolation ON categories;
CREATE POLICY tenant_isolation ON categories
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- products
DROP POLICY IF EXISTS tenant_isolation ON products;
CREATE POLICY tenant_isolation ON products
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- product_variants (join path through products)
DROP POLICY IF EXISTS tenant_isolation ON product_variants;
CREATE POLICY tenant_isolation ON product_variants
  USING (
    product_id IN (
      SELECT id FROM products
       WHERE tenant_id = current_setting('app.tenant_id', true)::uuid
    )
  );

-- modifier_groups
DROP POLICY IF EXISTS tenant_isolation ON modifier_groups;
CREATE POLICY tenant_isolation ON modifier_groups
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- modifier_options (join path through modifier_groups)
DROP POLICY IF EXISTS tenant_isolation ON modifier_options;
CREATE POLICY tenant_isolation ON modifier_options
  USING (
    group_id IN (
      SELECT id FROM modifier_groups
       WHERE tenant_id = current_setting('app.tenant_id', true)::uuid
    )
  );

-- unit_conversions (join path through products)
DROP POLICY IF EXISTS tenant_isolation ON unit_conversions;
CREATE POLICY tenant_isolation ON unit_conversions
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- tables
DROP POLICY IF EXISTS tenant_isolation ON "tables";
CREATE POLICY tenant_isolation ON "tables"
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- zones
DROP POLICY IF EXISTS tenant_isolation ON zones;
CREATE POLICY tenant_isolation ON zones
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- orders
DROP POLICY IF EXISTS tenant_isolation ON orders;
CREATE POLICY tenant_isolation ON orders
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- order_items (join path through orders)
DROP POLICY IF EXISTS tenant_isolation ON order_items;
CREATE POLICY tenant_isolation ON order_items
  USING (
    order_id IN (
      SELECT id FROM orders
       WHERE tenant_id = current_setting('app.tenant_id', true)::uuid
    )
  );

-- payments
DROP POLICY IF EXISTS tenant_isolation ON payments;
CREATE POLICY tenant_isolation ON payments
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- stock_levels
DROP POLICY IF EXISTS tenant_isolation ON stock_levels;
CREATE POLICY tenant_isolation ON stock_levels
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- stock_movements
DROP POLICY IF EXISTS tenant_isolation ON stock_movements;
CREATE POLICY tenant_isolation ON stock_movements
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- members
DROP POLICY IF EXISTS tenant_isolation ON members;
CREATE POLICY tenant_isolation ON members
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- shifts
DROP POLICY IF EXISTS tenant_isolation ON shifts;
CREATE POLICY tenant_isolation ON shifts
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- coupons
DROP POLICY IF EXISTS tenant_isolation ON coupons;
CREATE POLICY tenant_isolation ON coupons
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- queue
DROP POLICY IF EXISTS tenant_isolation ON queue;
CREATE POLICY tenant_isolation ON queue
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- kitchen_tickets
DROP POLICY IF EXISTS tenant_isolation ON kitchen_tickets;
CREATE POLICY tenant_isolation ON kitchen_tickets
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- audit_logs
DROP POLICY IF EXISTS tenant_isolation ON audit_logs;
CREATE POLICY tenant_isolation ON audit_logs
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- sync_queue
DROP POLICY IF EXISTS tenant_isolation ON sync_queue;
CREATE POLICY tenant_isolation ON sync_queue
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- notifications
DROP POLICY IF EXISTS tenant_isolation ON notifications;
CREATE POLICY tenant_isolation ON notifications
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- subscriptions
DROP POLICY IF EXISTS tenant_isolation ON subscriptions;
CREATE POLICY tenant_isolation ON subscriptions
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);

-- ─── Superuser / service-role bypass ─────────────────────────────────────────
-- Add BYPASSRLS to the migration user/admin role so Drizzle migrations work:
-- ALTER ROLE <migration_role> BYPASSRLS;  ← run manually by DBA
