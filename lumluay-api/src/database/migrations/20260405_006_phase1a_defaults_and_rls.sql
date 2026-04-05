ALTER TABLE users
  ALTER COLUMN pin_code TYPE varchar(255);

ALTER TABLE users
  ALTER COLUMN locale SET DEFAULT 'lo';

ALTER TABLE tenants
  ALTER COLUMN default_currency SET DEFAULT 'LAK';

ALTER TABLE tenants
  ALTER COLUMN default_locale SET DEFAULT 'lo';

ALTER TABLE orders
  ALTER COLUMN currency SET DEFAULT 'LAK';

ALTER TABLE payments
  ALTER COLUMN currency SET DEFAULT 'LAK';

DROP POLICY IF EXISTS tenant_isolation ON order_items;
CREATE POLICY tenant_isolation ON order_items
  USING (tenant_id = current_setting('app.tenant_id', true)::uuid);