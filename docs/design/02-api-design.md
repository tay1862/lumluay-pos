# LUMLUAY POS - API Design

> Node.js + TypeScript | RESTful API | JWT Auth
> Last Updated: 2026-04-02

---

## สารบัญ

1. [API Conventions](#1-api-conventions)
2. [Authentication](#2-authentication)
3. [Tenant / Store](#3-tenant--store)
4. [Users](#4-users)
5. [Categories](#5-categories)
6. [Products](#6-products)
7. [Tables & Zones](#7-tables--zones)
8. [Orders](#8-orders)
9. [Payments](#9-payments)
10. [Kitchen Display (KDS)](#10-kitchen-display-kds)
11. [Inventory / Stock](#11-inventory--stock)
12. [Members](#12-members)
13. [Shifts](#13-shifts)
14. [Coupons & Promotions](#14-coupons--promotions)
15. [Queue](#15-queue)
16. [Reports & Dashboard](#16-reports--dashboard)
17. [Notifications](#17-notifications)
18. [Sync (Offline)](#18-sync-offline)
19. [Settings](#19-settings)
20. [Super Admin](#20-super-admin)
21. [Import / Export](#21-import--export)
22. [QR Order (Public)](#22-qr-order-public)

---

## 1. API Conventions

### Base URL
```
Production:  https://api.lumluay.com/v1
Development: http://localhost:3000/v1
```

### Headers
```
Authorization: Bearer <JWT_TOKEN>
Content-Type: application/json
Accept-Language: th | en | lo
X-Tenant-ID: <TENANT_UUID>       ← ส่งทุก request (ยกเว้น super admin / auth)
X-Device-ID: <DEVICE_UUID>       ← สำหรับ offline sync
X-Timezone: Asia/Bangkok
```

### Response Format
```json
// Success
{
  "success": true,
  "data": { ... },
  "meta": {
    "page": 1,
    "per_page": 20,
    "total": 150,
    "total_pages": 8
  }
}

// Error
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Invalid input",
    "details": [
      { "field": "price", "message": "Price must be positive" }
    ]
  }
}
```

### Pagination
```
GET /products?page=1&per_page=20&sort=name&order=asc
```

### Filtering
```
GET /products?category_id=xxx&is_active=true&search=ข้าว
GET /orders?status=open&date_from=2026-04-01&date_to=2026-04-30
```

### HTTP Status Codes
| Code | Usage |
|------|-------|
| 200 | Success |
| 201 | Created |
| 204 | No Content (Delete success) |
| 400 | Bad Request / Validation Error |
| 401 | Unauthorized |
| 403 | Forbidden (ไม่มีสิทธิ์) |
| 404 | Not Found |
| 409 | Conflict (duplicate) |
| 422 | Unprocessable Entity |
| 429 | Too Many Requests |
| 500 | Internal Server Error |

### Error Codes
| Code | Description |
|------|-------------|
| `AUTH_INVALID` | Token ไม่ถูกต้อง |
| `AUTH_EXPIRED` | Token หมดอายุ |
| `AUTH_PIN_INVALID` | PIN ไม่ถูกต้อง |
| `PERMISSION_DENIED` | ไม่มีสิทธิ์ (role ไม่เพียงพอ) |
| `TENANT_INACTIVE` | ร้านถูกระงับ |
| `SUBSCRIPTION_EXPIRED` | แพลนหมดอายุ |
| `VALIDATION_ERROR` | ข้อมูล input ไม่ถูกต้อง |
| `RESOURCE_NOT_FOUND` | ไม่พบข้อมูล |
| `DUPLICATE_ENTRY` | ข้อมูลซ้ำ |
| `SHIFT_NOT_OPEN` | ยังไม่เปิดกะ |
| `INSUFFICIENT_STOCK` | สินค้าไม่พอ |
| `ORDER_ALREADY_PAID` | บิลชำระแล้ว |
| `VOID_NOT_ALLOWED` | ไม่มีสิทธิ์ Void |

---

## 2. Authentication

### 2.1 Login (Password)
```
POST /auth/login
```
```json
// Request
{
  "username": "admin",
  "password": "********",
  "tenant_slug": "somchai-restaurant",
  "device_id": "device-uuid",
  "device_name": "iPad Pro - เครื่อง 1"
}

// Response 200
{
  "success": true,
  "data": {
    "access_token": "eyJhbG...",
    "refresh_token": "eyJhbG...",
    "expires_in": 86400,
    "user": {
      "id": "uuid",
      "display_name": "สมชาย",
      "role": "owner",
      "avatar_url": null,
      "locale": "th"
    },
    "tenant": {
      "id": "uuid",
      "name": "ร้านสมชาย",
      "slug": "somchai-restaurant",
      "default_currency": "THB",
      "is_training_mode": false
    }
  }
}
```

### 2.2 Quick Login (PIN) — สลับพนักงาน
```
POST /auth/pin-login
```
```json
// Request
{
  "pin": "1234",
  "tenant_id": "uuid",
  "device_id": "device-uuid"
}

// Response 200 → เหมือน login ปกติ
```

### 2.3 Refresh Token
```
POST /auth/refresh
```
```json
{ "refresh_token": "eyJhbG..." }
```

### 2.4 Logout
```
POST /auth/logout
```

### 2.5 Change Password
```
PUT /auth/change-password
```
```json
{
  "current_password": "********",
  "new_password": "********"
}
```

### 2.6 Change PIN
```
PUT /auth/change-pin
```
```json
{
  "password": "********",
  "new_pin": "5678"
}
```

---

## 3. Tenant / Store

### 3.1 Get Current Tenant Info
```
GET /tenant
→ ข้อมูลร้านปัจจุบัน (จาก token)
```

### 3.2 Update Tenant
```
PUT /tenant
🔒 Role: owner
```
```json
{
  "name": "ร้านสมชาย updated",
  "phone": "0891234567",
  "address": "123 ถนนสุขุมวิท",
  "tax_id": "1234567890123",
  "default_currency": "LAK",
  "default_locale": "lo",
  "timezone": "Asia/Vientiane"
}
```

### 3.3 Upload Tenant Logo
```
POST /tenant/logo
Content-Type: multipart/form-data
🔒 Role: owner, manager
```

### 3.4 Toggle Training Mode
```
POST /tenant/training-mode
🔒 Role: owner
```
```json
{ "enabled": true }
```

---

## 4. Users

```
GET    /users                    ← รายการผู้ใช้ทั้งหมด  🔒 owner, manager
GET    /users/:id                ← รายละเอียดผู้ใช้
POST   /users                    ← สร้างผู้ใช้ใหม่        🔒 owner, manager
PUT    /users/:id                ← แก้ไขผู้ใช้             🔒 owner, manager
DELETE /users/:id                ← ลบผู้ใช้ (soft delete)  🔒 owner
PUT    /users/:id/toggle-active  ← เปิด/ปิดสถานะ          🔒 owner, manager
GET    /users/me                 ← ข้อมูลตัวเอง
PUT    /users/me                 ← แก้ไขข้อมูลตัวเอง
```

**Create User Request:**
```json
{
  "username": "cashier01",
  "password": "********",
  "pin_code": "1234",
  "display_name": "น้องแอน",
  "role": "cashier",
  "phone": "0891234567",
  "locale": "th",
  "auto_lock_minutes": 10
}
```

---

## 5. Categories

```
GET    /categories               ← รายการทั้งหมด (tree structure)
GET    /categories/:id           ← รายละเอียด
POST   /categories               ← สร้าง           🔒 owner, manager
PUT    /categories/:id           ← แก้ไข           🔒 owner, manager
DELETE /categories/:id           ← ลบ (soft)       🔒 owner, manager
PUT    /categories/reorder       ← เรียงลำดับใหม่   🔒 owner, manager
```

**Create Category Request:**
```json
{
  "parent_id": null,
  "name": { "th": "เครื่องดื่ม", "en": "Beverages", "lo": "ເຄື່ອງດື່ມ" },
  "image_url": "https://...",
  "color": "#2196F3",
  "sort_order": 1
}
```

**List Response (Tree):**
```json
{
  "data": [
    {
      "id": "uuid-1",
      "name": { "th": "อาหาร", "en": "Food", "lo": "ອາຫານ" },
      "parent_id": null,
      "children": [
        {
          "id": "uuid-2",
          "name": { "th": "อาหารจานเดียว", "en": "Single Dish", "lo": "..." },
          "parent_id": "uuid-1",
          "children": []
        }
      ]
    }
  ]
}
```

---

## 6. Products

### 6.1 CRUD
```
GET    /products                 ← รายการ (filter, search, paginate)
GET    /products/:id             ← รายละเอียด + variants + modifiers
POST   /products                 ← สร้าง            🔒 owner, manager
PUT    /products/:id             ← แก้ไข            🔒 owner, manager
DELETE /products/:id             ← ลบ (soft)        🔒 owner, manager
PUT    /products/reorder         ← เรียงลำดับ        🔒 owner, manager
POST   /products/:id/image       ← อัพโหลดรูป        🔒 owner, manager
```

**Query Params:**
```
GET /products?category_id=xxx&search=ข้าว&is_active=true&is_quick_key=true
    &type=standard&track_stock=true&page=1&per_page=50
    &sort=name&order=asc
```

**Create Product Request:**
```json
{
  "category_id": "uuid",
  "type": "variant",
  "name": { "th": "กาแฟเย็น", "en": "Iced Coffee", "lo": "ກາເຟເຢັນ" },
  "description": { "th": "กาแฟเย็นหอมกรุ่น", "en": "..." },
  "sku": "COF-001",
  "barcode": "8858998561234",
  "price": 45.00,
  "cost": 15.00,
  "currency": "THB",
  "track_stock": false,
  "is_quick_key": true,
  "allow_note": true,
  "print_to_kitchen": true,
  "kitchen_printer_name": "Kitchen",
  "tax_rate_id": "uuid",
  "variants": [
    { "name": { "th": "เล็ก", "en": "S" }, "price": 35.00, "sku": "COF-001-S" },
    { "name": { "th": "กลาง", "en": "M" }, "price": 45.00, "sku": "COF-001-M" },
    { "name": { "th": "ใหญ่", "en": "L" }, "price": 55.00, "sku": "COF-001-L" }
  ],
  "modifier_group_ids": ["uuid-sweetness", "uuid-topping"]
}
```

**Product Detail Response:**
```json
{
  "data": {
    "id": "uuid",
    "name": { "th": "กาแฟเย็น", "en": "Iced Coffee", "lo": "ກາເຟເຢັນ" },
    "type": "variant",
    "price": 45.00,
    "variants": [
      { "id": "v-uuid", "name": { "th": "เล็ก" }, "price": 35.00, "stock_quantity": null }
    ],
    "modifier_groups": [
      {
        "id": "mg-uuid",
        "name": { "th": "ความหวาน" },
        "min_select": 1,
        "max_select": 1,
        "is_required": true,
        "options": [
          { "id": "mo-uuid", "name": { "th": "หวานปกติ" }, "price_adjustment": 0 },
          { "id": "mo-uuid", "name": { "th": "หวานน้อย" }, "price_adjustment": 0 },
          { "id": "mo-uuid", "name": { "th": "ไม่หวาน" }, "price_adjustment": 0 }
        ]
      }
    ]
  }
}
```

### 6.2 Variants
```
POST   /products/:id/variants       ← เพิ่ม variant
PUT    /products/:id/variants/:vid   ← แก้ไข variant
DELETE /products/:id/variants/:vid   ← ลบ variant
```

### 6.3 Modifier Groups
```
GET    /modifier-groups              ← รายการ modifier groups
POST   /modifier-groups              ← สร้าง
PUT    /modifier-groups/:id          ← แก้ไข
DELETE /modifier-groups/:id          ← ลบ

POST   /modifier-groups/:id/options  ← เพิ่ม option
PUT    /modifier-groups/:id/options/:oid  ← แก้ไข option
DELETE /modifier-groups/:id/options/:oid  ← ลบ option
```

### 6.4 Barcode Lookup
```
GET /products/barcode/:barcode
→ คืนข้อมูลสินค้าจาก barcode
```

### 6.5 Quick Keys
```
GET /products/quick-keys
→ คืนสินค้าที่ is_quick_key = true (เรียงตาม sort_order)
```

---

## 7. Tables & Zones

### 7.1 Zones
```
GET    /zones                    ← รายการโซน + โต๊ะในโซน
POST   /zones                    🔒 owner, manager
PUT    /zones/:id                🔒 owner, manager
DELETE /zones/:id                🔒 owner, manager
```

### 7.2 Tables
```
GET    /tables                   ← รายการโต๊ะ (+ status)
GET    /tables/:id               ← รายละเอียด + current order (ถ้ามี)
POST   /tables                   🔒 owner, manager
PUT    /tables/:id               🔒 owner, manager
DELETE /tables/:id               🔒 owner, manager
```

### 7.3 Table Operations
```
POST /tables/:id/merge
🔒 Role: cashier+
```
```json
{
  "merge_table_ids": ["table-uuid-2", "table-uuid-3"]
}
```

```
POST /tables/:id/unmerge
🔒 Role: cashier+
```

```
POST /tables/:id/move
🔒 Role: cashier+
```
```json
{
  "target_table_id": "table-uuid-5"
}
```

```
POST /tables/:id/split
🔒 Role: cashier+
```
```json
{
  "target_table_id": "table-uuid-6",
  "order_item_ids": ["item-uuid-1", "item-uuid-2"]
}
```

### 7.4 Table Status Overview (สำหรับหน้า Floor Plan)
```
GET /tables/status-overview
```
```json
{
  "data": [
    {
      "id": "uuid",
      "name": "T1",
      "zone": { "th": "ชั้น 1" },
      "status": "occupied",
      "seats": 4,
      "current_order": {
        "id": "order-uuid",
        "order_number": "INV-042",
        "total": 450.00,
        "item_count": 5,
        "opened_at": "2026-04-02T12:30:00Z",
        "duration_minutes": 25
      }
    }
  ]
}
```

---

## 8. Orders

### 8.1 CRUD
```
GET    /orders                   ← รายการ (filter by status, date, table, waiter)
GET    /orders/:id               ← รายละเอียดเต็ม + items + payments
POST   /orders                   ← สร้างออเดอร์ใหม่
PUT    /orders/:id               ← อัพเดท (เพิ่มของ, แก้ note ฯลฯ)
```

**Query Params:**
```
GET /orders?status=open&table_id=xxx&cashier_id=xxx
    &date_from=2026-04-01&date_to=2026-04-02
    &order_type=dine_in&page=1&per_page=20
```

**Create Order Request:**
```json
{
  "order_type": "dine_in",
  "table_id": "table-uuid",
  "member_id": null,
  "customer_count": 3,
  "items": [
    {
      "product_id": "prod-uuid",
      "variant_id": "var-uuid",
      "quantity": 2,
      "note": "ไม่ใส่ผัก",
      "modifier_option_ids": ["mo-uuid-1", "mo-uuid-2"]
    },
    {
      "product_id": "prod-uuid-2",
      "quantity": 1,
      "is_open_price": true,
      "unit_price": 150.00
    }
  ]
}
```

**Order Detail Response:**
```json
{
  "data": {
    "id": "uuid",
    "order_number": "INV-042",
    "order_type": "dine_in",
    "status": "open",
    "table": { "id": "uuid", "name": "T1" },
    "cashier": { "id": "uuid", "display_name": "น้องแอน" },
    "waiter": { "id": "uuid", "display_name": "น้องบี" },
    "member": null,
    "currency": "THB",
    "subtotal": 580.00,
    "discount_amount": 50.00,
    "tax_amount": 37.10,
    "service_charge_amount": 53.00,
    "rounding_amount": 0.10,
    "total": 620.00,
    "customer_count": 3,
    "items": [
      {
        "id": "item-uuid",
        "product_name": { "th": "ข้าวผัด" },
        "variant_name": { "th": "ใหญ่" },
        "unit_price": 65.00,
        "quantity": 2,
        "discount_amount": 0,
        "subtotal": 130.00,
        "note": "ไม่ใส่ผัก",
        "status": "preparing",
        "modifiers": [
          { "name": { "th": "เผ็ดมาก" }, "price_adjustment": 0 }
        ]
      }
    ],
    "payments": [],
    "opened_at": "2026-04-02T12:30:00Z"
  }
}
```

### 8.2 Order Items (เพิ่ม/แก้/ลบ ของในบิล)
```
POST   /orders/:id/items            ← เพิ่มรายการ
PUT    /orders/:id/items/:itemId    ← แก้ไข (quantity, note)
DELETE /orders/:id/items/:itemId    ← ลบรายการ (ก่อนส่งครัว)
```

### 8.3 Send to Kitchen
```
POST /orders/:id/send-to-kitchen
```
```json
{
  "item_ids": ["item-uuid-1", "item-uuid-2"]
}
// ถ้าไม่ส่ง item_ids → ส่งทุกรายการที่ยังไม่ส่ง
```

### 8.4 Apply Discount to Order
```
POST /orders/:id/discount
```
```json
{
  "type": "percent",
  "value": 10
}
// หรือ
{
  "type": "amount",
  "value": 50.00
}
// หรือ
{
  "type": "coupon",
  "coupon_code": "SAVE20"
}
```

### 8.5 Apply Discount to Item
```
POST /orders/:id/items/:itemId/discount
```
```json
{
  "type": "percent",
  "value": 15
}
```

### 8.6 Hold / Unhold Order (พักบิล)
```
POST /orders/:id/hold
POST /orders/:id/unhold
```

### 8.7 Get Held Orders
```
GET /orders/held
```

### 8.8 Void Order
```
POST /orders/:id/void
🔒 Role: manager, owner
```
```json
{
  "reason": "ลูกค้ายกเลิก"
}
```

### 8.9 Void Single Item
```
POST /orders/:id/items/:itemId/void
🔒 Role: manager, owner
```
```json
{
  "reason": "สินค้าหมด"
}
```

### 8.10 Refund
```
POST /orders/:id/refund
🔒 Role: manager, owner
```
```json
{
  "type": "full",
  "reason": "อาหารไม่ตรงออเดอร์"
}
// หรือ
{
  "type": "partial",
  "amount": 100.00,
  "reason": "สินค้าไม่ครบ"
}
```

### 8.11 Complete Order (ปิดบิล)
```
POST /orders/:id/complete
→ ต้องชำระเงินครบก่อน
```

### 8.12 Reprint Receipt
```
POST /orders/:id/reprint
```

---

## 9. Payments

### 9.1 Add Payment to Order (รองรับ Split Bill / Multi-currency)
```
POST /orders/:id/payments
```
```json
// ชำระเงินสด (THB)
{
  "method": "cash",
  "amount": 300.00,
  "currency": "THB",
  "cash_received": 500.00
}

// ชำระ QR PromptPay
{
  "method": "qr_promptpay",
  "amount": 200.00,
  "currency": "THB",
  "reference_no": "202604021234567890"
}

// ชำระด้วยสกุลเงินอื่น (LAK)
{
  "method": "cash",
  "amount": 50000,
  "currency": "LAK",
  "cash_received": 50000,
  "exchange_rate": 0.0018
}
```

**Response:**
```json
{
  "data": {
    "payment": {
      "id": "pay-uuid",
      "method": "cash",
      "amount": 300.00,
      "currency": "THB",
      "cash_received": 500.00,
      "cash_change": 200.00,
      "amount_in_base": 300.00
    },
    "order_summary": {
      "total": 500.00,
      "total_paid": 300.00,
      "remaining": 200.00,
      "is_fully_paid": false
    }
  }
}
```

### 9.2 Delete Payment (ก่อนปิดบิล)
```
DELETE /orders/:id/payments/:paymentId
```

### 9.3 Get Exchange Rates
```
GET /exchange-rates
```
```json
{
  "data": {
    "base": "THB",
    "rates": {
      "LAK": 556.00,
      "USD": 0.028
    },
    "updated_at": "2026-04-02T00:00:00Z"
  }
}
```

### 9.4 Update Exchange Rates
```
PUT /exchange-rates
🔒 Role: owner, manager
```
```json
{
  "rates": {
    "LAK": 560.00,
    "USD": 0.029
  }
}
```

---

## 10. Kitchen Display (KDS)

### 10.1 Get Kitchen Orders
```
GET /kitchen/orders?status=new,preparing
```
```json
{
  "data": [
    {
      "id": "ko-uuid",
      "order_number": "INV-042",
      "table_name": "T1",
      "status": "new",
      "product_name": { "th": "ข้าวผัด" },
      "variant_name": { "th": "จานใหญ่" },
      "quantity": 2,
      "note": "ไม่ใส่ผัก",
      "modifiers": [
        { "name": { "th": "เผ็ดมาก" } }
      ],
      "sent_at": "2026-04-02T12:31:00Z",
      "elapsed_minutes": 5
    }
  ]
}
```

### 10.2 Update Kitchen Order Status
```
PUT /kitchen/orders/:id/status
🔒 Role: kitchen, manager, owner
```
```json
{ "status": "preparing" }
// หรือ
{ "status": "ready" }
// หรือ
{ "status": "served" }
```

### 10.3 Bulk Update (เสร็จหลายรายการพร้อมกัน)
```
POST /kitchen/orders/bulk-status
```
```json
{
  "ids": ["ko-uuid-1", "ko-uuid-2"],
  "status": "ready"
}
```

---

## 11. Inventory / Stock

### 11.1 Stock Overview
```
GET /stock?low_stock=true&category_id=xxx&search=xxx
```
```json
{
  "data": [
    {
      "product_id": "uuid",
      "product_name": { "th": "น้ำดื่ม" },
      "sku": "DRK-001",
      "stock_quantity": 5,
      "low_stock_alert": 10,
      "unit": { "th": "ขวด" },
      "is_low_stock": true
    }
  ]
}
```

### 11.2 Stock Adjustment (ปรับ +/-)
```
POST /stock/adjustments
🔒 Role: owner, manager
```
```json
{
  "items": [
    {
      "product_id": "uuid",
      "variant_id": null,
      "quantity": 50,
      "type": "purchase",
      "unit_cost": 8.00,
      "note": "รับของเข้าจากซัพพลายเออร์"
    },
    {
      "product_id": "uuid-2",
      "quantity": -3,
      "type": "adjustment",
      "note": "สินค้าเสียหาย"
    }
  ]
}
```

### 11.3 Stock Movement History
```
GET /stock/movements?product_id=xxx&type=sale&date_from=xxx&date_to=xxx
```

### 11.4 Stock Transfer (ถ้ามีหลาย location)
```
POST /stock/transfers
🔒 Role: owner, manager
```
```json
{
  "target_tenant_id": "uuid",
  "items": [
    { "product_id": "uuid", "quantity": 10, "note": "ส่งให้สาขา 2" }
  ]
}
```

---

## 12. Members

```
GET    /members                  ← รายการ (search by phone/name)
GET    /members/:id              ← รายละเอียด + ประวัติซื้อ
POST   /members                  ← สร้าง
PUT    /members/:id              ← แก้ไข
DELETE /members/:id              ← ลบ (soft)
```

**Create Member:**
```json
{
  "name": "คุณสมปอง",
  "phone": "0891234567",
  "email": "sompong@email.com",
  "note": "แพ้ถั่ว"
}
```

### 12.1 Member Lookup (ค้นหาตอนขาย)
```
GET /members/lookup?phone=089
→ ค้นหาเบอร์โทร (partial match)
```

### 12.2 Member Purchase History
```
GET /members/:id/orders?page=1&per_page=20
```

---

## 13. Shifts

### 13.1 Open Shift
```
POST /shifts/open
🔒 Role: cashier+
```
```json
{
  "opening_cash": 2000.00,
  "currency": "THB",
  "note": "เปิดกะเช้า"
}
```

### 13.2 Get Current Shift
```
GET /shifts/current
```

### 13.3 Close Shift
```
POST /shifts/close
🔒 Role: cashier+
```
```json
{
  "closing_cash": 15500.00,
  "note": "ปิดกะเช้า"
}
```

**Response:**
```json
{
  "data": {
    "id": "shift-uuid",
    "opening_cash": 2000.00,
    "closing_cash": 15500.00,
    "expected_cash": 15200.00,
    "difference": 300.00,
    "total_sales": 18500.00,
    "total_orders": 45,
    "total_refunds": 200.00,
    "total_voids": 2,
    "sales_by_method": {
      "cash": 13200.00,
      "qr_promptpay": 4000.00,
      "transfer": 1300.00
    },
    "opened_at": "2026-04-02T08:00:00Z",
    "closed_at": "2026-04-02T16:00:00Z"
  }
}
```

### 13.4 Shift History
```
GET /shifts?date_from=xxx&date_to=xxx&page=1
```

---

## 14. Coupons & Promotions

```
GET    /coupons                  🔒 owner, manager
GET    /coupons/:id
POST   /coupons                  🔒 owner, manager
PUT    /coupons/:id              🔒 owner, manager
DELETE /coupons/:id              🔒 owner, manager
```

**Create Coupon:**
```json
{
  "code": "SAVE20",
  "name": { "th": "ลด 20%", "en": "20% off" },
  "type": "percent",
  "value": 20,
  "min_order_amount": 200.00,
  "max_discount": 100.00,
  "max_uses": 100,
  "starts_at": "2026-04-01T00:00:00Z",
  "expires_at": "2026-04-30T23:59:59Z"
}
```

### 14.1 Validate Coupon (ตอนขาย)
```
POST /coupons/validate
```
```json
{
  "code": "SAVE20",
  "order_total": 500.00,
  "member_id": null
}
```
```json
// Response
{
  "data": {
    "valid": true,
    "discount_amount": 100.00,
    "coupon": { "id": "uuid", "name": { "th": "ลด 20%" }, "type": "percent", "value": 20 }
  }
}
```

---

## 15. Queue

```
GET    /queue                    ← คิววันนี้ (filter by status)
POST   /queue                    ← ออกคิวใหม่
PUT    /queue/:id/call           ← เรียกคิว
PUT    /queue/:id/serve          ← กำลังให้บริการ
PUT    /queue/:id/complete       ← เสร็จ
PUT    /queue/:id/cancel         ← ยกเลิก
```

**Create Queue:**
```json
{
  "customer_name": "คุณสมชาย",
  "customer_phone": "0891234567",
  "party_size": 4,
  "note": "ต้องการโต๊ะริมหน้าต่าง"
}
```

**Response:**
```json
{
  "data": {
    "id": "uuid",
    "ticket_number": "Q-015",
    "status": "waiting",
    "position": 3,
    "estimated_wait_minutes": 15
  }
}
```

---

## 16. Reports & Dashboard

### 16.1 Dashboard Summary
```
GET /reports/dashboard?date=2026-04-02
🔒 Role: owner, manager
```
```json
{
  "data": {
    "today": {
      "total_sales": 25000.00,
      "total_orders": 65,
      "average_order": 384.62,
      "total_customers": 80,
      "top_products": [
        { "name": { "th": "ข้าวผัด" }, "quantity_sold": 25, "revenue": 3250.00 }
      ],
      "sales_by_hour": [
        { "hour": 11, "sales": 3500.00, "orders": 8 },
        { "hour": 12, "sales": 6200.00, "orders": 15 }
      ],
      "sales_by_method": {
        "cash": 15000.00,
        "qr_promptpay": 7000.00,
        "transfer": 3000.00
      }
    }
  }
}
```

### 16.2 Sales Report
```
GET /reports/sales?period=daily&date_from=2026-04-01&date_to=2026-04-30
GET /reports/sales?period=monthly&year=2026
GET /reports/sales?period=yearly
🔒 Role: owner, manager
```

### 16.3 Product Sales Report
```
GET /reports/products?date_from=xxx&date_to=xxx&sort=quantity&order=desc&limit=20
🔒 Role: owner, manager
```

### 16.4 Profit & Loss Report
```
GET /reports/profit-loss?date_from=xxx&date_to=xxx
🔒 Role: owner
```
```json
{
  "data": {
    "revenue": 250000.00,
    "cost_of_goods": 100000.00,
    "gross_profit": 150000.00,
    "gross_margin_percent": 60.0,
    "tax_collected": 17500.00,
    "service_charge_collected": 25000.00,
    "discounts_given": 8000.00,
    "refunds": 2000.00,
    "net_sales": 240000.00
  }
}
```

### 16.5 Export Report
```
GET /reports/sales/export?format=excel&date_from=xxx&date_to=xxx
GET /reports/sales/export?format=pdf&date_from=xxx&date_to=xxx
→ Returns file download
```

---

## 17. Notifications

```
GET    /notifications            ← รายการแจ้งเตือน (unread first)
PUT    /notifications/:id/read   ← อ่านแล้ว
PUT    /notifications/read-all   ← อ่านทั้งหมด
GET    /notifications/unread-count ← จำนวนยังไม่อ่าน
```

---

## 18. Sync (Offline)

### 18.1 Push Offline Changes
```
POST /sync/push
```
```json
{
  "device_id": "device-uuid",
  "changes": [
    {
      "entity_type": "order",
      "entity_id": "local-uuid",
      "action": "create",
      "payload": { ... },
      "queued_at": "2026-04-02T12:30:00Z"
    },
    {
      "entity_type": "payment",
      "entity_id": "local-uuid-2",
      "action": "create",
      "payload": { ... },
      "queued_at": "2026-04-02T12:31:00Z"
    }
  ]
}
```

**Response:**
```json
{
  "data": {
    "processed": 2,
    "succeeded": 2,
    "failed": 0,
    "results": [
      { "entity_id": "local-uuid", "status": "success", "server_id": "server-uuid" },
      { "entity_id": "local-uuid-2", "status": "success", "server_id": "server-uuid-2" }
    ]
  }
}
```

### 18.2 Pull Server Changes (เครื่อง sync ข้อมูลมาอัพเดท local)
```
GET /sync/pull?since=2026-04-02T12:00:00Z&entities=products,categories,members
```
```json
{
  "data": {
    "products": {
      "created": [ ... ],
      "updated": [ ... ],
      "deleted": ["uuid-1", "uuid-2"]
    },
    "categories": { ... },
    "members": { ... },
    "server_time": "2026-04-02T12:35:00Z"
  }
}
```

### 18.3 Sync Status
```
GET /sync/status?device_id=xxx
→ สถานะ sync ของเครื่อง
```

---

## 19. Settings

### 19.1 Get Store Settings
```
GET /settings
```

### 19.2 Update Store Settings
```
PUT /settings
🔒 Role: owner, manager
```
```json
{
  "tax_enabled": true,
  "tax_rate": 7.00,
  "tax_inclusive": true,
  "service_charge_enabled": true,
  "service_charge_rate": 10.00,
  "receipt_header": { "th": "ยินดีต้อนรับ", "en": "Welcome", "lo": "ຍິນດີຕ້ອນຮັບ" },
  "receipt_footer": { "th": "ขอบคุณครับ", "en": "Thank you", "lo": "ຂອບໃຈ" },
  "receipt_width": "80mm",
  "receipt_prefix": "INV",
  "auto_open_cash_drawer": true,
  "sound_enabled": true,
  "auto_lock_minutes": 15,
  "default_order_type": "dine_in",
  "currencies_enabled": ["THB", "LAK", "USD"]
}
```

### 19.3 Tax Rates
```
GET    /settings/tax-rates
POST   /settings/tax-rates       🔒 owner
PUT    /settings/tax-rates/:id   🔒 owner
DELETE /settings/tax-rates/:id   🔒 owner
```

### 19.4 Printers
```
GET    /settings/printers
PUT    /settings/printers        🔒 owner, manager
POST   /settings/printers/test   ← ทดสอบพิมพ์
```

### 19.5 Upload Receipt Logo
```
POST /settings/receipt-logo
Content-Type: multipart/form-data
🔒 Role: owner, manager
```

### 19.6 Backup
```
POST /settings/backup/export     🔒 owner
→ Returns downloadable backup file

POST /settings/backup/restore    🔒 owner
Content-Type: multipart/form-data
→ Restore from backup file
```

---

## 20. Super Admin

> เฉพาะ role `super_admin` เท่านั้น — ใช้จัดการระบบ SaaS ทั้งหมด

### 20.1 Tenants Management
```
GET    /admin/tenants                ← รายการร้านทั้งหมด
GET    /admin/tenants/:id            ← รายละเอียดร้าน
POST   /admin/tenants                ← สร้างร้านใหม่
PUT    /admin/tenants/:id            ← แก้ไข
PUT    /admin/tenants/:id/activate   ← เปิดใช้งาน
PUT    /admin/tenants/:id/deactivate ← ระงับ
DELETE /admin/tenants/:id            ← ลบ
```

### 20.2 Subscription Plans
```
GET    /admin/plans
POST   /admin/plans
PUT    /admin/plans/:id
DELETE /admin/plans/:id
```

### 20.3 Assign Subscription to Tenant
```
POST /admin/tenants/:id/subscription
```
```json
{
  "plan_id": "plan-uuid",
  "license_type": "subscription",
  "starts_at": "2026-04-01T00:00:00Z",
  "expires_at": "2026-05-01T00:00:00Z",
  "amount_paid": 999.00,
  "payment_reference": "TXN-12345"
}
```

### 20.4 Admin Dashboard
```
GET /admin/dashboard
```
```json
{
  "data": {
    "total_tenants": 150,
    "active_tenants": 120,
    "total_users": 580,
    "total_orders_today": 3500,
    "monthly_revenue": 120000.00,
    "subscriptions_expiring_soon": 8,
    "new_tenants_this_month": 12
  }
}
```

### 20.5 Admin Audit Logs
```
GET /admin/audit-logs?tenant_id=xxx&action=xxx&date_from=xxx
```

---

## 21. Import / Export

### 21.1 Import Products from CSV/Excel
```
POST /import/products
Content-Type: multipart/form-data
🔒 Role: owner, manager
```
```
file: products.csv
```

**Response:**
```json
{
  "data": {
    "total_rows": 150,
    "imported": 145,
    "skipped": 3,
    "errors": [
      { "row": 12, "message": "Barcode already exists" },
      { "row": 45, "message": "Invalid price format" },
      { "row": 89, "message": "Category not found" }
    ]
  }
}
```

### 21.2 Download Import Template
```
GET /import/products/template?format=csv
GET /import/products/template?format=xlsx
→ Returns template file with headers and example data
```

### 21.3 Export Products
```
GET /export/products?format=csv&category_id=xxx
GET /export/products?format=xlsx
→ Returns file download
```

---

## 22. QR Order (Public — ไม่ต้อง Auth)

> สำหรับลูกค้าสแกน QR สั่งอาหารผ่านมือถือ

### 22.1 Get E-Menu
```
GET /public/menu/:tenant_slug?table=T1&lang=th
→ ไม่ต้อง auth
```
```json
{
  "data": {
    "store_name": { "th": "ร้านสมชาย" },
    "store_logo": "https://...",
    "table_name": "T1",
    "categories": [
      {
        "id": "uuid",
        "name": { "th": "อาหาร" },
        "children": [
          { "id": "uuid", "name": { "th": "อาหารจานเดียว" } }
        ]
      }
    ],
    "products": [
      {
        "id": "uuid",
        "name": { "th": "ข้าวผัด" },
        "price": 65.00,
        "image_url": "https://...",
        "category_id": "uuid",
        "variants": [ ... ],
        "modifier_groups": [ ... ]
      }
    ]
  }
}
```

### 22.2 Submit QR Order
```
POST /public/orders/:tenant_slug
```
```json
{
  "table_id": "table-uuid",
  "customer_name": "สมชาย",
  "items": [
    {
      "product_id": "uuid",
      "variant_id": "uuid",
      "quantity": 1,
      "note": "ไม่เผ็ด",
      "modifier_option_ids": ["mo-uuid"]
    }
  ]
}
```

### 22.3 Track QR Order Status
```
GET /public/orders/:tenant_slug/:order_id/status
```

---

## WebSocket Events (Real-time)

สำหรับ KDS, อัพเดทโต๊ะ, แจ้งเตือน real-time:

```
WS /ws?token=<JWT>&tenant_id=<UUID>
```

### Event Channels:
| Channel | Description | ตัวอย่าง Event |
|---------|-------------|---------------|
| `orders` | ออเดอร์ใหม่/อัพเดท | `order.created`, `order.updated`, `order.completed`, `order.voided` |
| `kitchen` | KDS updates | `kitchen.new_order`, `kitchen.status_changed` |
| `tables` | สถานะโต๊ะ | `table.occupied`, `table.available`, `table.merged` |
| `queue` | คิว | `queue.called`, `queue.completed` |
| `notifications` | แจ้งเตือน | `notification.low_stock`, `notification.new_order` |
| `sync` | Sync status | `sync.completed`, `sync.conflict` |

**Event Format:**
```json
{
  "channel": "orders",
  "event": "order.created",
  "data": {
    "id": "uuid",
    "order_number": "INV-042",
    "table_name": "T1",
    "total": 450.00
  },
  "timestamp": "2026-04-02T12:30:00Z"
}
```

---

## Rate Limiting

| Endpoint Group | Rate Limit |
|---------------|------------|
| Auth (login) | 10 requests / minute |
| Public (QR menu) | 60 requests / minute |
| API (authenticated) | 200 requests / minute |
| Admin | 100 requests / minute |
| Import/Export | 5 requests / minute |
| Sync | 30 requests / minute |

---

## API Summary

| กลุ่ม | Endpoints | Methods |
|-------|-----------|---------|
| Auth | 6 | POST, PUT |
| Tenant | 4 | GET, PUT, POST |
| Users | 8 | GET, POST, PUT, DELETE |
| Categories | 6 | GET, POST, PUT, DELETE |
| Products | 12 | GET, POST, PUT, DELETE |
| Modifier Groups | 6 | GET, POST, PUT, DELETE |
| Tables & Zones | 11 | GET, POST, PUT, DELETE |
| Orders | 14 | GET, POST, PUT, DELETE |
| Payments | 4 | GET, POST, DELETE |
| Kitchen (KDS) | 3 | GET, PUT, POST |
| Stock | 4 | GET, POST |
| Members | 7 | GET, POST, PUT, DELETE |
| Shifts | 4 | GET, POST |
| Coupons | 6 | GET, POST, PUT, DELETE |
| Queue | 6 | GET, POST, PUT |
| Reports | 6 | GET |
| Notifications | 4 | GET, PUT |
| Sync | 3 | GET, POST |
| Settings | 9 | GET, PUT, POST, DELETE |
| Super Admin | 10 | GET, POST, PUT, DELETE |
| Import/Export | 4 | GET, POST |
| QR Public | 3 | GET, POST |
| **รวม** | **~140 endpoints** | |
