# LUMLUAY POS - Database Schema Design

> PostgreSQL | Multi-tenant (tenant_id) | Shared Database
> Last Updated: 2026-04-02

---

## สารบัญ

1. [Tenant & Authentication](#1-tenant--authentication)
2. [Store Settings](#2-store-settings)
3. [Products & Categories](#3-products--categories)
4. [Tables & Zones](#4-tables--zones)
5. [Orders & Payments](#5-orders--payments)
6. [Inventory & Stock](#6-inventory--stock)
7. [Members & Customers](#7-members--customers)
8. [Shifts & Cash Management](#8-shifts--cash-management)
9. [Promotions & Discounts](#9-promotions--discounts)
10. [Queue System](#10-queue-system)
11. [Kitchen Display (KDS)](#11-kitchen-display-kds)
12. [Audit Log](#12-audit-log)
13. [Subscription & Licensing](#13-subscription--licensing)
14. [Sync Queue (Offline)](#14-sync-queue-offline)
15. [Notifications](#15-notifications)

---

## หลักการออกแบบ

- ทุกตาราง tenant-scoped มี `tenant_id` เป็น FK → `tenants.id`
- ใช้ `UUID` เป็น Primary Key ทุกตาราง (เพื่อ offline sync ไม่ชนกัน)
- Soft delete ด้วย `deleted_at` (ไม่ลบข้อมูลจริง)
- `created_at`, `updated_at` ทุกตาราง
- ชื่อฟิลด์ที่ต้องแปลใช้ `JSONB` → `{"th": "...", "en": "...", "lo": "..."}`
- ราคาเก็บเป็น `DECIMAL(18,4)` รองรับทุกสกุลเงิน
- Enum ใช้ PostgreSQL ENUM type

---

## 1. Tenant & Authentication

### 1.1 `tenants` — ร้านค้า/Tenant หลัก
```sql
CREATE TABLE tenants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255) NOT NULL,
    slug            VARCHAR(100) UNIQUE NOT NULL,
    logo_url        TEXT,
    owner_name      VARCHAR(255),
    phone           VARCHAR(50),
    email           VARCHAR(255),
    address         TEXT,
    tax_id          VARCHAR(50),
    default_currency VARCHAR(3) NOT NULL DEFAULT 'THB',
    default_locale  VARCHAR(5) NOT NULL DEFAULT 'th',
    timezone        VARCHAR(50) NOT NULL DEFAULT 'Asia/Bangkok',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    is_training_mode BOOLEAN NOT NULL DEFAULT false,
    subscription_plan VARCHAR(50),
    subscription_expires_at TIMESTAMPTZ,
    license_type    VARCHAR(20), -- 'subscription' | 'perpetual'
    settings        JSONB NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_tenants_slug ON tenants(slug);
CREATE INDEX idx_tenants_active ON tenants(is_active) WHERE deleted_at IS NULL;
```

### 1.2 `users` — ผู้ใช้งานทุก Role
```sql
CREATE TYPE user_role AS ENUM (
    'super_admin', 'owner', 'manager', 'cashier', 'waiter', 'kitchen'
);

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID REFERENCES tenants(id),
    username        VARCHAR(100) NOT NULL,
    email           VARCHAR(255),
    phone           VARCHAR(50),
    password_hash   VARCHAR(255) NOT NULL,
    pin_code        VARCHAR(10),  -- hashed PIN สำหรับ quick login
    display_name    VARCHAR(255) NOT NULL,
    avatar_url      TEXT,
    role            user_role NOT NULL DEFAULT 'cashier',
    is_active       BOOLEAN NOT NULL DEFAULT true,
    last_login_at   TIMESTAMPTZ,
    auto_lock_minutes INT DEFAULT 15,
    locale          VARCHAR(5) DEFAULT 'th',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    UNIQUE(tenant_id, username)
);

CREATE INDEX idx_users_tenant ON users(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_role ON users(tenant_id, role) WHERE deleted_at IS NULL;
```

### 1.3 `user_sessions` — Session / Token
```sql
CREATE TABLE user_sessions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    device_id       VARCHAR(255),
    device_name     VARCHAR(255),
    token_hash      VARCHAR(255) NOT NULL,
    refresh_token_hash VARCHAR(255),
    ip_address      INET,
    expires_at      TIMESTAMPTZ NOT NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sessions_user ON user_sessions(user_id);
CREATE INDEX idx_sessions_token ON user_sessions(token_hash);
```

---

## 2. Store Settings

### 2.1 `store_settings` — ตั้งค่าร้านค้า
```sql
CREATE TABLE store_settings (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL UNIQUE REFERENCES tenants(id),

    -- ข้อมูลร้าน
    store_name      JSONB NOT NULL DEFAULT '{}',  -- {"th":"ร้าน...","en":"...","lo":"..."}
    store_address   JSONB NOT NULL DEFAULT '{}',
    store_phone     VARCHAR(50),
    store_email     VARCHAR(255),

    -- Tax
    tax_enabled     BOOLEAN NOT NULL DEFAULT false,
    tax_rate        DECIMAL(5,2) DEFAULT 0,
    tax_inclusive    BOOLEAN NOT NULL DEFAULT true, -- VAT รวมในราคา
    tax_label       JSONB DEFAULT '{"th":"VAT","en":"VAT","lo":"VAT"}',

    -- Service Charge
    service_charge_enabled BOOLEAN NOT NULL DEFAULT false,
    service_charge_rate    DECIMAL(5,2) DEFAULT 0,

    -- Receipt
    receipt_header  JSONB DEFAULT '{}',
    receipt_footer  JSONB DEFAULT '{}',
    receipt_logo_url TEXT,
    receipt_width   VARCHAR(10) DEFAULT '80mm', -- '58mm' | '80mm'
    receipt_show_logo BOOLEAN DEFAULT true,

    -- Receipt Number Format
    receipt_prefix  VARCHAR(20) DEFAULT 'INV',
    receipt_running_number INT NOT NULL DEFAULT 0,

    -- Currency
    currencies_enabled JSONB NOT NULL DEFAULT '["THB"]',
    exchange_rates  JSONB DEFAULT '{}', -- {"LAK_THB": 0.0018, "USD_THB": 35.5}

    -- Operations
    auto_open_cash_drawer BOOLEAN DEFAULT true,
    sound_enabled   BOOLEAN DEFAULT true,
    auto_lock_minutes INT DEFAULT 15,
    default_order_type VARCHAR(20) DEFAULT 'dine_in',

    -- Printers
    printers_config JSONB DEFAULT '[]',
    /*
    [
      {"name":"Receipt","type":"thermal","connection":"bluetooth","address":"XX:XX","width":"80mm","is_default":true},
      {"name":"Kitchen","type":"thermal","connection":"wifi","ip":"192.168.1.100","width":"80mm","print_categories":["food"]}
    ]
    */

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 2.2 `tax_rates` — อัตราภาษีหลายอัตรา
```sql
CREATE TABLE tax_rates (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    name            JSONB NOT NULL, -- {"th":"VAT 7%","en":"VAT 7%","lo":"..."}
    rate            DECIMAL(5,2) NOT NULL,
    is_inclusive    BOOLEAN NOT NULL DEFAULT true,
    is_default     BOOLEAN NOT NULL DEFAULT false,
    is_active      BOOLEAN NOT NULL DEFAULT true,
    sort_order     INT DEFAULT 0,
    created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at     TIMESTAMPTZ
);

CREATE INDEX idx_tax_rates_tenant ON tax_rates(tenant_id) WHERE deleted_at IS NULL;
```

---

## 3. Products & Categories

### 3.1 `categories` — หมวดหมู่ 2 ชั้น
```sql
CREATE TABLE categories (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    parent_id       UUID REFERENCES categories(id),
    name            JSONB NOT NULL,  -- {"th":"อาหาร","en":"Food","lo":"ອາຫານ"}
    image_url       TEXT,
    color           VARCHAR(7),  -- hex color #FF5733
    sort_order      INT DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_categories_tenant ON categories(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_categories_parent ON categories(tenant_id, parent_id) WHERE deleted_at IS NULL;
```

### 3.2 `products` — สินค้า/เมนู
```sql
CREATE TYPE product_type AS ENUM ('standard', 'variant', 'open_price', 'bundle');

CREATE TABLE products (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    category_id     UUID REFERENCES categories(id),
    type            product_type NOT NULL DEFAULT 'standard',
    name            JSONB NOT NULL,  -- {"th":"ข้าวผัด","en":"Fried Rice","lo":"..."}
    description     JSONB DEFAULT '{}',
    sku             VARCHAR(100),
    barcode         VARCHAR(100),
    image_url       TEXT,
    price           DECIMAL(18,4) NOT NULL DEFAULT 0,
    cost            DECIMAL(18,4) DEFAULT 0,
    currency        VARCHAR(3) NOT NULL DEFAULT 'THB',

    -- Stock
    track_stock     BOOLEAN NOT NULL DEFAULT false,
    stock_quantity  DECIMAL(18,4) DEFAULT 0,
    low_stock_alert DECIMAL(18,4) DEFAULT 0,
    unit            JSONB DEFAULT '{"th":"ชิ้น","en":"pc","lo":"ອັນ"}',

    -- Flags
    is_active       BOOLEAN NOT NULL DEFAULT true,
    is_quick_key    BOOLEAN NOT NULL DEFAULT false, -- ปุ่มลัดหน้าขาย
    is_featured     BOOLEAN NOT NULL DEFAULT false,
    allow_note      BOOLEAN NOT NULL DEFAULT true,  -- อนุญาตพิมพ์โน้ต

    -- Tax
    tax_rate_id     UUID REFERENCES tax_rates(id),

    -- Kitchen
    print_to_kitchen BOOLEAN NOT NULL DEFAULT false,
    kitchen_printer_name VARCHAR(100),

    sort_order      INT DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_products_tenant ON products(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_category ON products(tenant_id, category_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_barcode ON products(tenant_id, barcode) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_sku ON products(tenant_id, sku) WHERE deleted_at IS NULL;
CREATE INDEX idx_products_quick_key ON products(tenant_id) WHERE is_quick_key = true AND deleted_at IS NULL;
```

### 3.3 `product_variants` — Variant สินค้า (S/M/L, ระดับความเผ็ด, สี)
```sql
CREATE TABLE product_variants (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    name            JSONB NOT NULL,  -- {"th":"ใหญ่","en":"Large","lo":"ໃຫຍ່"}
    sku             VARCHAR(100),
    barcode         VARCHAR(100),
    price           DECIMAL(18,4) NOT NULL,
    cost            DECIMAL(18,4) DEFAULT 0,
    stock_quantity  DECIMAL(18,4) DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    sort_order      INT DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_variants_product ON product_variants(product_id) WHERE deleted_at IS NULL;
```

### 3.4 `modifier_groups` — กลุ่มตัวเลือกเสริม
```sql
CREATE TABLE modifier_groups (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    name            JSONB NOT NULL,  -- {"th":"ระดับความหวาน","en":"Sweetness Level"}
    min_select      INT NOT NULL DEFAULT 0,
    max_select      INT NOT NULL DEFAULT 1,
    is_required     BOOLEAN NOT NULL DEFAULT false,
    sort_order      INT DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_modifier_groups_tenant ON modifier_groups(tenant_id) WHERE deleted_at IS NULL;
```

### 3.5 `modifier_options` — ตัวเลือกใน Group
```sql
CREATE TABLE modifier_options (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    group_id        UUID NOT NULL REFERENCES modifier_groups(id) ON DELETE CASCADE,
    name            JSONB NOT NULL,  -- {"th":"หวานน้อย","en":"Less Sweet"}
    price_adjustment DECIMAL(18,4) NOT NULL DEFAULT 0,
    is_default      BOOLEAN NOT NULL DEFAULT false,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    sort_order      INT DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_modifier_options_group ON modifier_options(group_id) WHERE deleted_at IS NULL;
```

### 3.6 `product_modifier_groups` — เชื่อม Product ↔ Modifier Group
```sql
CREATE TABLE product_modifier_groups (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    modifier_group_id UUID NOT NULL REFERENCES modifier_groups(id) ON DELETE CASCADE,
    sort_order      INT DEFAULT 0,

    UNIQUE(product_id, modifier_group_id)
);

CREATE INDEX idx_pmg_product ON product_modifier_groups(product_id);
```

### 3.7 `unit_conversions` — หน่วยนับสินค้า
```sql
CREATE TABLE unit_conversions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    product_id      UUID NOT NULL REFERENCES products(id) ON DELETE CASCADE,
    from_unit       JSONB NOT NULL, -- {"th":"กล่อง","en":"Box"}
    to_unit         JSONB NOT NULL, -- {"th":"ชิ้น","en":"Piece"}
    conversion_rate DECIMAL(18,4) NOT NULL, -- 1 กล่อง = 12 ชิ้น → 12
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_unit_conv_product ON unit_conversions(product_id);
```

---

## 4. Tables & Zones

### 4.1 `zones` — โซนพื้นที่
```sql
CREATE TABLE zones (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    name            JSONB NOT NULL,  -- {"th":"ชั้น 1","en":"Floor 1"}
    sort_order      INT DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_zones_tenant ON zones(tenant_id) WHERE deleted_at IS NULL;
```

### 4.2 `tables` — โต๊ะ
```sql
CREATE TYPE table_status AS ENUM ('available', 'occupied', 'reserved', 'merged');

CREATE TABLE tables (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    zone_id         UUID REFERENCES zones(id),
    name            VARCHAR(50) NOT NULL,  -- "T1", "A01"
    seats           INT DEFAULT 4,
    status          table_status NOT NULL DEFAULT 'available',
    merged_into_id  UUID REFERENCES tables(id), -- ถ้าถูกรวมเข้าโต๊ะอื่น
    qr_code         TEXT,  -- QR code สำหรับสั่งอาหาร
    sort_order      INT DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ
);

CREATE INDEX idx_tables_tenant ON tables(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tables_zone ON tables(tenant_id, zone_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_tables_status ON tables(tenant_id, status) WHERE deleted_at IS NULL;
```

---

## 5. Orders & Payments

### 5.1 `orders` — ออเดอร์/บิลหลัก
```sql
CREATE TYPE order_status AS ENUM (
    'draft', 'open', 'completed', 'voided', 'held', 'refunded'
);
CREATE TYPE order_type AS ENUM ('dine_in', 'takeaway');

CREATE TABLE orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_number    VARCHAR(50) NOT NULL,  -- INV-001
    order_type      order_type NOT NULL DEFAULT 'dine_in',
    status          order_status NOT NULL DEFAULT 'draft',

    -- Table
    table_id        UUID REFERENCES tables(id),

    -- Staff
    cashier_id      UUID REFERENCES users(id),
    waiter_id       UUID REFERENCES users(id),
    shift_id        UUID, -- FK เพิ่มทีหลัง

    -- Customer/Member
    member_id       UUID, -- FK → members

    -- Amounts (สกุลเงินหลักของร้าน)
    currency        VARCHAR(3) NOT NULL DEFAULT 'THB',
    subtotal        DECIMAL(18,4) NOT NULL DEFAULT 0,
    discount_amount DECIMAL(18,4) NOT NULL DEFAULT 0,
    tax_amount      DECIMAL(18,4) NOT NULL DEFAULT 0,
    service_charge_amount DECIMAL(18,4) NOT NULL DEFAULT 0,
    total           DECIMAL(18,4) NOT NULL DEFAULT 0,
    rounding_amount DECIMAL(18,4) NOT NULL DEFAULT 0,

    -- Discount info
    discount_type   VARCHAR(20),  -- 'percent' | 'amount' | 'coupon'
    discount_value  DECIMAL(18,4) DEFAULT 0,
    coupon_id       UUID, -- FK → coupons

    -- Notes
    note            TEXT,
    customer_count  INT DEFAULT 1,

    -- Void/Cancel
    voided_by       UUID REFERENCES users(id),
    voided_at       TIMESTAMPTZ,
    void_reason     TEXT,

    -- Refund
    refund_of       UUID REFERENCES orders(id), -- ถ้าเป็น Refund order ชี้ไปที่ original
    refunded_amount DECIMAL(18,4) DEFAULT 0,

    -- Timestamps
    opened_at       TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    is_training     BOOLEAN NOT NULL DEFAULT false
);

CREATE INDEX idx_orders_tenant ON orders(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_status ON orders(tenant_id, status) WHERE deleted_at IS NULL;
CREATE INDEX idx_orders_number ON orders(tenant_id, order_number);
CREATE INDEX idx_orders_table ON orders(tenant_id, table_id) WHERE status IN ('draft','open');
CREATE INDEX idx_orders_date ON orders(tenant_id, created_at);
CREATE INDEX idx_orders_shift ON orders(tenant_id, shift_id);
CREATE INDEX idx_orders_member ON orders(tenant_id, member_id);
CREATE INDEX idx_orders_training ON orders(tenant_id) WHERE is_training = true;
```

### 5.2 `order_items` — รายการสินค้าในออเดอร์
```sql
CREATE TYPE order_item_status AS ENUM (
    'pending', 'preparing', 'ready', 'served', 'voided'
);

CREATE TABLE order_items (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    product_id      UUID REFERENCES products(id),
    variant_id      UUID REFERENCES product_variants(id),
    status          order_item_status NOT NULL DEFAULT 'pending',

    -- Item info (snapshot ณ เวลาสั่ง)
    product_name    JSONB NOT NULL,
    variant_name    JSONB,
    sku             VARCHAR(100),

    -- Pricing
    unit_price      DECIMAL(18,4) NOT NULL,
    quantity        DECIMAL(18,4) NOT NULL DEFAULT 1,
    discount_amount DECIMAL(18,4) NOT NULL DEFAULT 0,
    tax_amount      DECIMAL(18,4) NOT NULL DEFAULT 0,
    subtotal        DECIMAL(18,4) NOT NULL DEFAULT 0, -- (unit_price * qty) - discount

    -- Note & Modifiers
    note            TEXT,  -- free-text note
    is_open_price   BOOLEAN NOT NULL DEFAULT false,

    -- Void
    voided_by       UUID REFERENCES users(id),
    voided_at       TIMESTAMPTZ,
    void_reason     TEXT,

    -- Kitchen
    sent_to_kitchen_at TIMESTAMPTZ,
    prepared_at     TIMESTAMPTZ,
    served_at       TIMESTAMPTZ,

    sort_order      INT DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_status ON order_items(tenant_id, status)
    WHERE status IN ('pending','preparing');
CREATE INDEX idx_order_items_product ON order_items(tenant_id, product_id);
```

### 5.3 `order_item_modifiers` — Modifier ที่เลือกต่อรายการ
```sql
CREATE TABLE order_item_modifiers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    order_item_id   UUID NOT NULL REFERENCES order_items(id) ON DELETE CASCADE,
    modifier_option_id UUID NOT NULL REFERENCES modifier_options(id),
    modifier_name   JSONB NOT NULL,  -- snapshot
    option_name     JSONB NOT NULL,  -- snapshot
    price_adjustment DECIMAL(18,4) NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_oim_item ON order_item_modifiers(order_item_id);
```

### 5.4 `payments` — การชำระเงิน (รองรับ Multi-currency, Split Bill)
```sql
CREATE TYPE payment_method AS ENUM (
    'cash', 'qr_promptpay', 'transfer', 'other'
);
CREATE TYPE payment_status AS ENUM ('pending', 'completed', 'refunded');

CREATE TABLE payments (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES orders(id),
    method          payment_method NOT NULL,
    status          payment_status NOT NULL DEFAULT 'pending',

    -- Amount
    amount          DECIMAL(18,4) NOT NULL,
    currency        VARCHAR(3) NOT NULL DEFAULT 'THB',
    exchange_rate   DECIMAL(18,6) DEFAULT 1.0,
    amount_in_base  DECIMAL(18,4) NOT NULL, -- จำนวนเงินแปลงเป็นสกุลหลัก

    -- Cash
    cash_received   DECIMAL(18,4),
    cash_change     DECIMAL(18,4),

    -- Reference
    reference_no    VARCHAR(255),  -- เลขอ้างอิง QR/Transfer
    note            TEXT,

    paid_at         TIMESTAMPTZ,
    refunded_at     TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_payments_order ON payments(order_id);
CREATE INDEX idx_payments_tenant_date ON payments(tenant_id, created_at);
```

---

## 6. Inventory & Stock

### 6.1 `stock_movements` — ประวัติเคลื่อนไหวสต็อก
```sql
CREATE TYPE stock_movement_type AS ENUM (
    'sale', 'purchase', 'adjustment', 'transfer_in', 'transfer_out',
    'return', 'void', 'initial', 'import'
);

CREATE TABLE stock_movements (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    product_id      UUID NOT NULL REFERENCES products(id),
    variant_id      UUID REFERENCES product_variants(id),
    type            stock_movement_type NOT NULL,
    quantity        DECIMAL(18,4) NOT NULL, -- + เข้า, - ออก
    quantity_before DECIMAL(18,4) NOT NULL,
    quantity_after  DECIMAL(18,4) NOT NULL,
    unit_cost       DECIMAL(18,4),
    reference_type  VARCHAR(50),  -- 'order', 'adjustment', 'transfer'
    reference_id    UUID,
    note            TEXT,
    performed_by    UUID REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_stock_movements_product ON stock_movements(tenant_id, product_id);
CREATE INDEX idx_stock_movements_date ON stock_movements(tenant_id, created_at);
CREATE INDEX idx_stock_movements_type ON stock_movements(tenant_id, type);
```

---

## 7. Members & Customers

### 7.1 `members` — สมาชิก/ลูกค้า
```sql
CREATE TABLE members (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    name            VARCHAR(255) NOT NULL,
    phone           VARCHAR(50),
    email           VARCHAR(255),
    note            TEXT,
    total_spent     DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_visits    INT NOT NULL DEFAULT 0,
    is_active       BOOLEAN NOT NULL DEFAULT true,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    UNIQUE(tenant_id, phone)
);

CREATE INDEX idx_members_tenant ON members(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_members_phone ON members(tenant_id, phone) WHERE deleted_at IS NULL;
```

---

## 8. Shifts & Cash Management

### 8.1 `shifts` — กะการทำงาน
```sql
CREATE TYPE shift_status AS ENUM ('open', 'closed');

CREATE TABLE shifts (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    opened_by       UUID NOT NULL REFERENCES users(id),
    closed_by       UUID REFERENCES users(id),
    status          shift_status NOT NULL DEFAULT 'open',

    -- Cash Count
    opening_cash    DECIMAL(18,4) NOT NULL DEFAULT 0,
    closing_cash    DECIMAL(18,4),
    expected_cash   DECIMAL(18,4),  -- คำนวณจากระบบ
    difference      DECIMAL(18,4),  -- closing - expected

    -- Summary
    total_sales     DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_orders    INT NOT NULL DEFAULT 0,
    total_refunds   DECIMAL(18,4) NOT NULL DEFAULT 0,
    total_voids     INT NOT NULL DEFAULT 0,

    -- Details per payment method
    sales_by_method JSONB DEFAULT '{}',
    /*
    {
      "cash": 15000,
      "qr_promptpay": 8000,
      "transfer": 3000
    }
    */

    currency        VARCHAR(3) NOT NULL DEFAULT 'THB',
    note            TEXT,
    opened_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    closed_at       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_shifts_tenant ON shifts(tenant_id);
CREATE INDEX idx_shifts_status ON shifts(tenant_id, status);
CREATE INDEX idx_shifts_date ON shifts(tenant_id, opened_at);
```

เพิ่ม FK ที่ orders:
```sql
ALTER TABLE orders ADD CONSTRAINT fk_orders_shift
    FOREIGN KEY (shift_id) REFERENCES shifts(id);
ALTER TABLE orders ADD CONSTRAINT fk_orders_member
    FOREIGN KEY (member_id) REFERENCES members(id);
```

---

## 9. Promotions & Discounts

### 9.1 `coupons` — คูปอง/โค้ดส่วนลด
```sql
CREATE TYPE coupon_type AS ENUM ('percent', 'fixed_amount', 'buy_x_get_y');

CREATE TABLE coupons (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    code            VARCHAR(50) NOT NULL,
    name            JSONB NOT NULL,
    type            coupon_type NOT NULL,
    value           DECIMAL(18,4) NOT NULL, -- % หรือจำนวนเงิน
    min_order_amount DECIMAL(18,4) DEFAULT 0,
    max_discount    DECIMAL(18,4),  -- จำกัดส่วนลดสูงสุด

    -- Buy X Get Y
    buy_product_id  UUID REFERENCES products(id),
    buy_quantity    INT,
    get_product_id  UUID REFERENCES products(id),
    get_quantity    INT,

    -- Limits
    max_uses        INT,
    used_count      INT NOT NULL DEFAULT 0,
    max_uses_per_member INT,

    -- Validity
    starts_at       TIMESTAMPTZ,
    expires_at      TIMESTAMPTZ,
    is_active       BOOLEAN NOT NULL DEFAULT true,

    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ,

    UNIQUE(tenant_id, code)
);

CREATE INDEX idx_coupons_tenant ON coupons(tenant_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_coupons_code ON coupons(tenant_id, code) WHERE deleted_at IS NULL;
```

---

## 10. Queue System

### 10.1 `queue_tickets` — คิวรอรับ
```sql
CREATE TYPE queue_status AS ENUM ('waiting', 'called', 'serving', 'completed', 'cancelled');

CREATE TABLE queue_tickets (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    ticket_number   VARCHAR(20) NOT NULL,  -- Q-001
    status          queue_status NOT NULL DEFAULT 'waiting',
    customer_name   VARCHAR(255),
    customer_phone  VARCHAR(50),
    party_size      INT DEFAULT 1,
    note            TEXT,
    order_id        UUID REFERENCES orders(id),
    called_at       TIMESTAMPTZ,
    completed_at    TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_queue_tenant ON queue_tickets(tenant_id, status);
CREATE INDEX idx_queue_date ON queue_tickets(tenant_id, created_at);
```

---

## 11. Kitchen Display (KDS)

### 11.1 `kitchen_orders` — ออเดอร์ที่ส่งเข้าครัว
```sql
CREATE TYPE kitchen_status AS ENUM ('new', 'preparing', 'ready', 'served');

CREATE TABLE kitchen_orders (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    order_id        UUID NOT NULL REFERENCES orders(id),
    order_item_id   UUID NOT NULL REFERENCES order_items(id),
    status          kitchen_status NOT NULL DEFAULT 'new',
    printer_name    VARCHAR(100),
    table_name      VARCHAR(50),
    product_name    JSONB NOT NULL,  -- snapshot
    variant_name    JSONB,
    quantity        DECIMAL(18,4) NOT NULL,
    note            TEXT,
    modifiers       JSONB, -- snapshot ของ modifier ที่เลือก
    priority        INT DEFAULT 0,
    sent_at         TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    accepted_at     TIMESTAMPTZ,
    ready_at        TIMESTAMPTZ,
    served_at       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_kitchen_orders_tenant ON kitchen_orders(tenant_id, status);
CREATE INDEX idx_kitchen_orders_order ON kitchen_orders(order_id);
```

---

## 12. Audit Log

### 12.1 `audit_logs` — ประวัติการใช้งาน
```sql
CREATE TABLE audit_logs (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    user_id         UUID REFERENCES users(id),
    action          VARCHAR(100) NOT NULL, -- 'order.void', 'product.update', 'shift.close'
    entity_type     VARCHAR(50),  -- 'order', 'product', 'user', 'shift'
    entity_id       UUID,
    old_values      JSONB,
    new_values      JSONB,
    ip_address      INET,
    device_info     VARCHAR(255),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_tenant ON audit_logs(tenant_id, created_at);
CREATE INDEX idx_audit_user ON audit_logs(tenant_id, user_id);
CREATE INDEX idx_audit_action ON audit_logs(tenant_id, action);
CREATE INDEX idx_audit_entity ON audit_logs(tenant_id, entity_type, entity_id);
```

---

## 13. Subscription & Licensing

### 13.1 `subscription_plans` — แพลนสมัคร (Super Admin จัดการ)
```sql
CREATE TABLE subscription_plans (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            JSONB NOT NULL, -- {"th":"Basic","en":"Basic","lo":"Basic"}
    description     JSONB,
    price_monthly   DECIMAL(18,4) NOT NULL,
    price_yearly    DECIMAL(18,4),
    currency        VARCHAR(3) NOT NULL DEFAULT 'THB',
    max_products    INT,   -- NULL = unlimited
    max_users       INT,
    max_orders_per_month INT,
    features        JSONB NOT NULL DEFAULT '[]', -- ["kds","qr_order","multi_currency"]
    is_active       BOOLEAN NOT NULL DEFAULT true,
    sort_order      INT DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
```

### 13.2 `tenant_subscriptions` — ประวัติสมัคร/ต่ออายุ
```sql
CREATE TYPE sub_status AS ENUM ('active', 'expired', 'cancelled', 'trial');

CREATE TABLE tenant_subscriptions (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    plan_id         UUID NOT NULL REFERENCES subscription_plans(id),
    status          sub_status NOT NULL DEFAULT 'trial',
    license_type    VARCHAR(20) NOT NULL DEFAULT 'subscription', -- 'subscription' | 'perpetual'
    starts_at       TIMESTAMPTZ NOT NULL,
    expires_at      TIMESTAMPTZ,
    amount_paid     DECIMAL(18,4),
    currency        VARCHAR(3) DEFAULT 'THB',
    payment_reference VARCHAR(255),
    note            TEXT,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tenant_subs ON tenant_subscriptions(tenant_id, status);
```

---

## 14. Sync Queue (Offline)

### 14.1 `sync_queue` — คิว Sync ข้อมูล Offline → Server
```sql
CREATE TYPE sync_status AS ENUM ('pending', 'syncing', 'completed', 'failed');

CREATE TABLE sync_queue (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    device_id       VARCHAR(255) NOT NULL,
    entity_type     VARCHAR(50) NOT NULL,   -- 'order', 'payment', 'stock_movement'
    entity_id       UUID NOT NULL,
    action          VARCHAR(20) NOT NULL,   -- 'create', 'update', 'delete'
    payload         JSONB NOT NULL,
    status          sync_status NOT NULL DEFAULT 'pending',
    attempts        INT NOT NULL DEFAULT 0,
    error_message   TEXT,
    queued_at       TIMESTAMPTZ NOT NULL,   -- เวลาที่ทำ offline
    synced_at       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_sync_queue_status ON sync_queue(tenant_id, status);
CREATE INDEX idx_sync_queue_device ON sync_queue(tenant_id, device_id);
```

---

## 15. Notifications

### 15.1 `notifications` — การแจ้งเตือน
```sql
CREATE TYPE notification_type AS ENUM (
    'low_stock', 'new_order', 'order_ready', 'shift_reminder',
    'subscription_expiring', 'system'
);

CREATE TABLE notifications (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tenant_id       UUID NOT NULL REFERENCES tenants(id),
    user_id         UUID REFERENCES users(id), -- NULL = broadcast ทุกคนในร้าน
    type            notification_type NOT NULL,
    title           JSONB NOT NULL,
    body            JSONB NOT NULL,
    data            JSONB,  -- payload เสริม
    is_read         BOOLEAN NOT NULL DEFAULT false,
    read_at         TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(tenant_id, user_id, is_read);
CREATE INDEX idx_notifications_date ON notifications(tenant_id, created_at);
```

---

## ER Diagram Summary

```
tenants ─┬──< users ──< user_sessions
         ├──< store_settings
         ├──< tax_rates
         ├──< categories ──< categories (parent)
         ├──< products ─┬──< product_variants
         │              ├──< product_modifier_groups ──< modifier_groups ──< modifier_options
         │              └──< unit_conversions
         ├──< zones ──< tables
         ├──< orders ─┬──< order_items ──< order_item_modifiers
         │            └──< payments
         ├──< shifts
         ├──< members
         ├──< coupons
         ├──< queue_tickets
         ├──< kitchen_orders
         ├──< stock_movements
         ├──< audit_logs
         ├──< notifications
         ├──< sync_queue
         └──< tenant_subscriptions ──< subscription_plans
```

---

## Row Level Security (RLS) Policy

ทุกตาราง tenant-scoped ควรมี RLS เพื่อป้องกันข้อมูลข้ามร้าน:

```sql
-- ตัวอย่าง Products table
ALTER TABLE products ENABLE ROW LEVEL SECURITY;

CREATE POLICY products_tenant_isolation ON products
    USING (tenant_id = current_setting('app.current_tenant_id')::UUID);

CREATE POLICY products_insert_policy ON products
    FOR INSERT WITH CHECK (tenant_id = current_setting('app.current_tenant_id')::UUID);
```

---

## สรุปจำนวนตาราง: **25 ตาราง**

| กลุ่ม | ตาราง | จำนวน |
|-------|-------|-------|
| Auth & Tenant | tenants, users, user_sessions | 3 |
| Settings | store_settings, tax_rates | 2 |
| Products | categories, products, product_variants, modifier_groups, modifier_options, product_modifier_groups, unit_conversions | 7 |
| Tables | zones, tables | 2 |
| Orders | orders, order_items, order_item_modifiers, payments | 4 |
| Inventory | stock_movements | 1 |
| Members | members | 1 |
| Operations | shifts, coupons, queue_tickets, kitchen_orders | 4 |
| System | audit_logs, sync_queue, notifications, subscription_plans, tenant_subscriptions | 5 |