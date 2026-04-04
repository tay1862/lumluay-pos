-- Migration: Add unit_conversions table
-- Depends on: products table

CREATE TABLE IF NOT EXISTS "unit_conversions" (
  "id"               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  "tenant_id"        UUID NOT NULL REFERENCES "tenants"("id"),
  "product_id"       UUID NOT NULL REFERENCES "products"("id"),
  "from_unit"        VARCHAR(50) NOT NULL,
  "to_unit"          VARCHAR(50) NOT NULL,
  "conversion_rate"  NUMERIC(12,6) NOT NULL,
  "created_at"       TIMESTAMPTZ NOT NULL DEFAULT now(),
  "updated_at"       TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS "idx_unit_conversions_tenant"  ON "unit_conversions"("tenant_id");
CREATE INDEX IF NOT EXISTS "idx_unit_conversions_product" ON "unit_conversions"("product_id");
CREATE UNIQUE INDEX IF NOT EXISTS "uidx_unit_conversions_direction"
  ON "unit_conversions"("product_id","from_unit","to_unit");
