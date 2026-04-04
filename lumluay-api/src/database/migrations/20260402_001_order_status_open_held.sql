-- Align order_status enum with spec: open/held instead of draft/confirmed
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
    ALTER TYPE order_status RENAME TO order_status_old;
  END IF;

  IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
    CREATE TYPE order_status AS ENUM (
      'open',
      'held',
      'preparing',
      'ready',
      'served',
      'completed',
      'cancelled',
      'refunded'
    );
  END IF;
END $$;

ALTER TABLE orders
  ALTER COLUMN status DROP DEFAULT;

ALTER TABLE orders
  ALTER COLUMN status TYPE order_status
  USING (
    CASE status::text
      WHEN 'draft' THEN 'open'::order_status
      WHEN 'confirmed' THEN 'open'::order_status
      ELSE status::text::order_status
    END
  );

ALTER TABLE orders
  ALTER COLUMN status SET DEFAULT 'open'::order_status;

DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status_old') THEN
    DROP TYPE order_status_old;
  END IF;
END $$;
