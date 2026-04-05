-- Migration: 20260402_003_composite_indexes
-- Purpose: Add composite and partial indexes for high-traffic query patterns
-- Task: 1.1.23

-- ─── Orders ───────────────────────────────────────────────────────────────────
-- Active orders per tenant (list view filter)
CREATE INDEX IF NOT EXISTS idx_orders_tenant_status
  ON orders (tenant_id, status)
  WHERE status NOT IN ('completed', 'cancelled', 'refunded');

-- Orders by tenant + table (used when loading table state)
CREATE INDEX IF NOT EXISTS idx_orders_tenant_table_status
  ON orders (tenant_id, table_id, status)
  WHERE table_id IS NOT NULL AND status NOT IN ('completed', 'cancelled', 'refunded');

-- Orders by receipt number search within tenant
CREATE INDEX IF NOT EXISTS idx_orders_tenant_receipt
  ON orders (tenant_id, receipt_number);

-- Orders by date range reporting
CREATE INDEX IF NOT EXISTS idx_orders_tenant_created_at
  ON orders (tenant_id, created_at DESC);

-- ─── Order Items ──────────────────────────────────────────────────────────────
-- Pending/preparing items per order (used in kitchen ticket creation)
CREATE INDEX IF NOT EXISTS idx_order_items_order_status
  ON order_items (order_id, status)
  WHERE status NOT IN ('served', 'cancelled');

-- ─── Kitchen Tickets ──────────────────────────────────────────────────────────
-- Active tickets per tenant + station (KDS main query)
CREATE INDEX IF NOT EXISTS idx_kitchen_tickets_tenant_status_station
  ON kitchen_tickets (tenant_id, status, station)
  WHERE status NOT IN ('served', 'cancelled');

-- Ticket lookup by order_item (join path from orders → kitchen)
CREATE INDEX IF NOT EXISTS idx_kitchen_tickets_order_item
  ON kitchen_tickets (order_item_id);

-- ─── Products ─────────────────────────────────────────────────────────────────
-- Active products per tenant + category (menu listing)
CREATE INDEX IF NOT EXISTS idx_products_tenant_active_category
  ON products (tenant_id, is_active, category_id)
  WHERE is_active = TRUE;

-- Full-text search on product name within tenant
CREATE INDEX IF NOT EXISTS idx_products_tenant_name
  ON products (tenant_id, name);

-- ─── Categories ───────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_categories_tenant_active
  ON categories (tenant_id, is_active, sort_order)
  WHERE is_active = TRUE;

-- ─── Payments ─────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_payments_tenant_created_at
  ON payments (tenant_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_payments_order_id
  ON payments (order_id);

-- ─── Audit Logs ───────────────────────────────────────────────────────────────
-- Tenant audit timeline (dashboard / compliance queries)
CREATE INDEX IF NOT EXISTS idx_audit_logs_tenant_created_at
  ON audit_logs (tenant_id, created_at DESC);

-- User-specific audit trail
CREATE INDEX IF NOT EXISTS idx_audit_logs_user_created_at
  ON audit_logs (user_id, created_at DESC)
  WHERE user_id IS NOT NULL;

-- ─── Stock Movements ──────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_stock_movements_product_created_at
  ON stock_movements (product_id, created_at DESC);

CREATE INDEX IF NOT EXISTS idx_stock_movements_tenant_created_at
  ON stock_movements (tenant_id, created_at DESC);

-- ─── Members ──────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_members_tenant_phone
  ON members (tenant_id, phone)
  WHERE phone IS NOT NULL;

-- ─── Tables ───────────────────────────────────────────────────────────────────
CREATE INDEX IF NOT EXISTS idx_tables_tenant_zone_active
  ON tables (tenant_id, zone_id, is_active)
  WHERE is_active = TRUE;
