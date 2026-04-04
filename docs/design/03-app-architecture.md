# LUMLUAY POS - App Architecture

> Flutter + Dart (Frontend) | Node.js + TypeScript (Backend) | PostgreSQL + SQLite
> Last Updated: 2026-04-02

---

## สารบัญ

1. [System Overview](#1-system-overview)
2. [Backend Architecture](#2-backend-architecture)
3. [Flutter App Architecture](#3-flutter-app-architecture)
4. [Offline-First Strategy](#4-offline-first-strategy)
5. [Project Structure — Backend](#5-project-structure--backend)
6. [Project Structure — Flutter](#6-project-structure--flutter)
7. [State Management](#7-state-management)
8. [Authentication Flow](#8-authentication-flow)
9. [Sync Engine](#9-sync-engine)
10. [Printing Architecture](#10-printing-architecture)
11. [Hardware Integration](#11-hardware-integration)
12. [Multi-language (i18n)](#12-multi-language-i18n)
13. [Theming System](#13-theming-system)
14. [WebSocket Architecture](#14-websocket-architecture)
15. [Security](#15-security)
16. [Deployment Architecture](#16-deployment-architecture)
17. [Tech Stack Summary](#17-tech-stack-summary)

---

## 1. System Overview

```
┌─────────────────────────────────────────────────────────────────────┐
│                        LUMLUAY POS System                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                     │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐              │
│  │  Android APK │  │   iOS App    │  │   Web App    │              │
│  │  (POS/Phone) │  │ (iPad/iPhone)│  │  (Browser)   │              │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘              │
│         │                 │                 │                       │
│         └────────────┬────┴────┬────────────┘                       │
│                      │         │                                    │
│              ┌───────▼─────────▼───────┐                           │
│              │    Flutter App (Dart)   │                           │
│              │  ┌───────────────────┐  │                           │
│              │  │   SQLite (Local)  │  │  ← Offline Data          │
│              │  └───────────────────┘  │                           │
│              └────────────┬────────────┘                           │
│                           │                                        │
│                    HTTPS + WebSocket                               │
│                           │                                        │
│              ┌────────────▼────────────┐                           │
│              │   Nginx (Reverse Proxy) │                           │
│              └────────────┬────────────┘                           │
│                           │                                        │
│              ┌────────────▼────────────┐                           │
│              │  Node.js + TypeScript   │                           │
│              │  (NestJS / Fastify)     │                           │
│              │  REST API + WebSocket   │                           │
│              └──────┬───────┬──────────┘                           │
│                     │       │                                      │
│              ┌──────▼──┐ ┌──▼──────────┐                          │
│              │PostgreSQL│ │    Redis    │                          │
│              │  (Main)  │ │(Cache/Queue)│                          │
│              └─────────┘ └─────────────┘                          │
│                                                                     │
│  ┌──────────────────────┐  ┌──────────────────────┐               │
│  │ Public QR Menu (Web) │  │  Super Admin Panel   │               │
│  │  (Flutter Web / SPA) │  │  (ภายในแอปเดียวกัน)   │               │
│  └──────────────────────┘  └──────────────────────┘               │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

### Platform Targets
| Platform | Build Target | Primary Use |
|----------|-------------|-------------|
| Android APK | `.apk` / `.aab` | เครื่อง POS Android, มือถือ, แท็บเล็ต |
| iOS | `.ipa` | iPad, iPhone |
| Web | PWA | เปิดผ่าน Browser บน PC/Mac |
| macOS | `.dmg` (Optional) | Mac desktop |
| Windows | `.exe` (Optional) | Windows POS machine |

---

## 2. Backend Architecture

### 2.1 Architecture Pattern: **Layered + Modular**

```
┌─────────────────────────────────────────────┐
│              Presentation Layer              │
│  (Controllers / Routes / WebSocket Gateway)  │
├─────────────────────────────────────────────┤
│              Application Layer               │
│  (Services / Use Cases / Business Logic)     │
├─────────────────────────────────────────────┤
│               Domain Layer                   │
│  (Entities / Interfaces / Value Objects)     │
├─────────────────────────────────────────────┤
│            Infrastructure Layer              │
│  (Repositories / DB / External Services)     │
└─────────────────────────────────────────────┘
```

### 2.2 Key Backend Components

```
┌──────────────────────────────────────────────────────┐
│                    API Gateway                        │
│  (Rate Limiting, Auth Middleware, Tenant Resolution)  │
├────────┬────────┬────────┬────────┬─────────┬────────┤
│  Auth  │Products│ Orders │ Stock  │ Reports │ Admin  │
│ Module │ Module │ Module │ Module │ Module  │ Module │
├────────┴────────┴────────┴────────┴─────────┴────────┤
│                  Shared Services                      │
│  (Tenant, Notification, Audit, Printer, Sync)        │
├──────────────────────────────────────────────────────┤
│               Data Access Layer                       │
│  (PostgreSQL via Prisma/Drizzle ORM + Redis Cache)   │
└──────────────────────────────────────────────────────┘
```

### 2.3 Middleware Pipeline

```
Request → Rate Limiter → CORS → Auth JWT → Tenant Resolver
  → Role Guard → Validation → Controller → Service → Response
```

| Middleware | Description |
|-----------|-------------|
| `RateLimiter` | จำกัดจำนวน request ต่อนาที |
| `CorsMiddleware` | อนุญาต cross-origin สำหรับ Web/QR |
| `AuthMiddleware` | ตรวจ JWT token, ดึง user info |
| `TenantMiddleware` | Resolve tenant จาก `X-Tenant-ID` header + token |
| `RoleGuard` | ตรวจสิทธิ์ตาม role ของ endpoint |
| `ValidationPipe` | Validate request body ด้วย Zod/class-validator |
| `AuditInterceptor` | บันทึก audit log อัตโนมัติ |
| `TrainingInterceptor` | แยก training mode data |

### 2.4 Database Strategy

```
PostgreSQL (Server)
├── Connection Pool: pgBouncer (max 100 connections)
├── ORM: Drizzle ORM (type-safe, lightweight)
├── Migrations: Drizzle Kit
├── Row Level Security: tenant_id isolation
└── Indexes: Optimized per query pattern

Redis (Cache + Queue)
├── Session cache
├── Exchange rates cache
├── Rate limiting counters
├── WebSocket pub/sub
└── Background job queue (BullMQ)
```

### 2.5 Background Jobs (BullMQ + Redis)

| Job | Schedule/Trigger | Description |
|-----|-----------------|-------------|
| `backup-daily` | Cron: 03:00 daily | Auto backup PostgreSQL |
| `subscription-check` | Cron: 00:00 daily | ตรวจ subscription หมดอายุ |
| `low-stock-alert` | After each sale | เช็คสต็อกต่ำ → notification |
| `report-generate` | On-demand | สร้างรายงาน Excel/PDF |
| `sync-process` | On push | ประมวลผล offline sync queue |
| `cleanup-training` | Cron: weekly | ล้างข้อมูล training mode |

---

## 3. Flutter App Architecture

### 3.1 Architecture Pattern: **Clean Architecture + BLoC**

```
┌─────────────────────────────────────────────────────┐
│                 Presentation Layer                    │
│  ┌────────┐  ┌────────┐  ┌─────────────┐           │
│  │ Screens│  │Widgets │  │   BLoCs /   │           │
│  │ (Pages)│  │(Reuse) │  │   Cubits    │           │
│  └────────┘  └────────┘  └─────────────┘           │
├─────────────────────────────────────────────────────┤
│                  Domain Layer                        │
│  ┌──────────┐  ┌────────────┐  ┌────────────┐      │
│  │ Entities │  │ Use Cases  │  │ Repository │      │
│  │ (Models) │  │(Business)  │  │ Interfaces │      │
│  └──────────┘  └────────────┘  └────────────┘      │
├─────────────────────────────────────────────────────┤
│                   Data Layer                         │
│  ┌──────────┐  ┌────────────┐  ┌────────────┐      │
│  │   API    │  │  SQLite    │  │   Sync     │      │
│  │ Client   │  │  (Local)   │  │  Engine    │      │
│  └──────────┘  └────────────┘  └────────────┘      │
├─────────────────────────────────────────────────────┤
│                 Platform Layer                        │
│  ┌──────────┐  ┌────────────┐  ┌────────────┐      │
│  │ Printer  │  │  Barcode   │  │   Cash     │      │
│  │ Service  │  │  Scanner   │  │  Drawer    │      │
│  └──────────┘  └────────────┘  └────────────┘      │
└─────────────────────────────────────────────────────┘
```

### 3.2 Data Flow

```
UI (Widget)
  ↓ event
BLoC / Cubit
  ↓ call
Use Case
  ↓ call
Repository (Interface)
  ↓ implements
Repository (Implementation)
  ├── Online → API Client → Server
  └── Offline → SQLite → SyncQueue
```

### 3.3 BLoC Pattern (แต่ละ Feature)

```
feature/
├── bloc/
│   ├── feature_bloc.dart        ← Business logic
│   ├── feature_event.dart       ← Input events
│   └── feature_state.dart       ← Output states
├── data/
│   ├── models/                  ← Data models (JSON serializable)
│   ├── datasources/
│   │   ├── feature_remote_ds.dart   ← API calls
│   │   └── feature_local_ds.dart    ← SQLite queries
│   └── repositories/
│       └── feature_repository_impl.dart
├── domain/
│   ├── entities/                ← Clean entities
│   ├── repositories/
│   │   └── feature_repository.dart  ← Interface
│   └── usecases/
│       ├── get_features.dart
│       └── create_feature.dart
└── presentation/
    ├── screens/
    │   └── feature_screen.dart
    └── widgets/
        └── feature_widget.dart
```

---

## 4. Offline-First Strategy

### 4.1 Data Categories

| Category | Offline Read | Offline Write | Sync Priority |
|----------|-------------|---------------|---------------|
| Products/Categories | ✅ Cache | ❌ Read-only | Medium |
| Orders | ✅ Local | ✅ Create/Update | **High** |
| Payments | ✅ Local | ✅ Create | **High** |
| Members | ✅ Cache | ❌ Read-only | Low |
| Stock | ✅ Cache | ✅ Auto-deduct | Medium |
| Settings | ✅ Cache | ❌ Read-only | Low |
| Shifts | ✅ Local | ✅ Open/Close | **High** |
| Kitchen Orders | ✅ Local | ✅ Status update | **High** |
| Audit Logs | ✅ Local | ✅ Create | Low |

### 4.2 Sync Architecture

```
┌─────────────────────────────────────────────────┐
│                 Flutter App                      │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │            Repository Layer               │   │
│  │                                           │   │
│  │   ┌─────────────┐  ┌─────────────────┐   │   │
│  │   │ Online Mode │  │  Offline Mode   │   │   │
│  │   │ API Client  │  │  SQLite + Queue │   │   │
│  │   └──────┬──────┘  └────────┬────────┘   │   │
│  │          │                  │              │   │
│  │   ┌──────▼──────────────────▼──────┐      │   │
│  │   │     Connectivity Monitor       │      │   │
│  │   │  (auto-switch online/offline)  │      │   │
│  │   └────────────────────────────────┘      │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │             Sync Engine                   │   │
│  │                                           │   │
│  │  ┌──────────┐  ┌──────────┐  ┌────────┐ │   │
│  │  │  Queue   │  │ Conflict │  │ Retry  │ │   │
│  │  │ Manager  │  │ Resolver │  │ Logic  │ │   │
│  │  └──────────┘  └──────────┘  └────────┘ │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  ┌──────────────────────────────────────────┐   │
│  │          Local Database (SQLite)          │   │
│  │                                           │   │
│  │  ┌────────┐ ┌─────────┐ ┌─────────────┐ │   │
│  │  │Products│ │ Orders  │ │ Sync Queue  │ │   │
│  │  │ Cache  │ │ (Local) │ │ (Pending)   │ │   │
│  │  └────────┘ └─────────┘ └─────────────┘ │   │
│  └──────────────────────────────────────────┘   │
└─────────────────────────────────────────────────┘
```

### 4.3 Sync Flow

```
1. App ทำงาน Offline:
   Order สร้าง → SQLite (orders table)
                → SQLite (sync_queue: action=create, status=pending)

2. กลับมา Online:
   Sync Engine ตรวจจับ connectivity
     → ดึง sync_queue ที่ status=pending เรียงตาม queued_at
     → POST /sync/push (batch ส่งทีละ 50 records)
     → สำเร็จ → update sync_queue status=completed
     → ล้มเหลว → increment attempts, retry (max 5)

3. Pull ข้อมูลใหม่จาก Server:
   GET /sync/pull?since=<last_sync_time>
     → อัพเดท local cache (products, categories, members)
     → บันทึก last_sync_time
```

### 4.4 Conflict Resolution Strategy

| Scenario | Resolution |
|----------|-----------|
| Same order edited on 2 devices | **Last-write-wins** by `updated_at` |
| Order created offline, dup order_number | Server re-assigns new order_number |
| Product price changed while offline | Use price from local snapshot (ราคา ณ เวลาขาย) |
| Stock quantity conflict | Server recalculates from movement history |

### 4.5 Local Database Schema (SQLite — ย่อ)

```sql
-- Mirror จาก Server (cache, read-heavy)
CREATE TABLE local_products ( ... เหมือน server + last_synced_at );
CREATE TABLE local_categories ( ... );
CREATE TABLE local_members ( ... );
CREATE TABLE local_settings ( ... );

-- Local-first (write-heavy)
CREATE TABLE local_orders ( ... + sync_status TEXT DEFAULT 'pending' );
CREATE TABLE local_order_items ( ... );
CREATE TABLE local_payments ( ... );
CREATE TABLE local_shifts ( ... );

-- Sync management
CREATE TABLE sync_queue (
    id TEXT PRIMARY KEY,
    entity_type TEXT NOT NULL,
    entity_id TEXT NOT NULL,
    action TEXT NOT NULL,      -- 'create','update','delete'
    payload TEXT NOT NULL,     -- JSON
    status TEXT DEFAULT 'pending',
    attempts INTEGER DEFAULT 0,
    queued_at TEXT NOT NULL,
    synced_at TEXT,
    error TEXT
);

CREATE TABLE sync_metadata (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL         -- เช่น last_sync_time
);
```

---

## 5. Project Structure — Backend

```
lumluay-api/
├── docker-compose.yml
├── Dockerfile
├── package.json
├── tsconfig.json
├── .env.example
├── drizzle.config.ts
│
├── src/
│   ├── main.ts                          ← Entry point
│   ├── app.module.ts                    ← Root module
│   │
│   ├── config/
│   │   ├── database.config.ts
│   │   ├── redis.config.ts
│   │   ├── jwt.config.ts
│   │   └── app.config.ts
│   │
│   ├── common/
│   │   ├── decorators/
│   │   │   ├── roles.decorator.ts       ← @Roles('owner','manager')
│   │   │   ├── tenant.decorator.ts      ← @CurrentTenant()
│   │   │   └── user.decorator.ts        ← @CurrentUser()
│   │   ├── guards/
│   │   │   ├── jwt-auth.guard.ts
│   │   │   ├── role.guard.ts
│   │   │   └── tenant.guard.ts
│   │   ├── interceptors/
│   │   │   ├── audit.interceptor.ts
│   │   │   ├── training.interceptor.ts
│   │   │   └── transform.interceptor.ts
│   │   ├── middleware/
│   │   │   ├── tenant.middleware.ts
│   │   │   └── rate-limit.middleware.ts
│   │   ├── filters/
│   │   │   └── http-exception.filter.ts
│   │   ├── pipes/
│   │   │   └── validation.pipe.ts
│   │   ├── dto/
│   │   │   └── pagination.dto.ts
│   │   └── utils/
│   │       ├── crypto.util.ts
│   │       ├── receipt-number.util.ts
│   │       └── currency.util.ts
│   │
│   ├── database/
│   │   ├── schema/                      ← Drizzle schema files
│   │   │   ├── tenants.ts
│   │   │   ├── users.ts
│   │   │   ├── products.ts
│   │   │   ├── orders.ts
│   │   │   └── ... (ทุกตาราง)
│   │   ├── migrations/
│   │   ├── seeds/
│   │   │   ├── sample-data.seed.ts      ← ข้อมูลตัวอย่าง onboarding
│   │   │   └── subscription-plans.seed.ts
│   │   └── database.module.ts
│   │
│   ├── modules/
│   │   ├── auth/
│   │   │   ├── auth.controller.ts
│   │   │   ├── auth.service.ts
│   │   │   ├── auth.module.ts
│   │   │   ├── dto/
│   │   │   │   ├── login.dto.ts
│   │   │   │   ├── pin-login.dto.ts
│   │   │   │   └── refresh-token.dto.ts
│   │   │   └── strategies/
│   │   │       └── jwt.strategy.ts
│   │   │
│   │   ├── tenant/
│   │   │   ├── tenant.controller.ts
│   │   │   ├── tenant.service.ts
│   │   │   └── tenant.module.ts
│   │   │
│   │   ├── users/
│   │   │   ├── users.controller.ts
│   │   │   ├── users.service.ts
│   │   │   └── dto/
│   │   │
│   │   ├── categories/
│   │   │   ├── categories.controller.ts
│   │   │   ├── categories.service.ts
│   │   │   └── dto/
│   │   │
│   │   ├── products/
│   │   │   ├── products.controller.ts
│   │   │   ├── products.service.ts
│   │   │   ├── variants.controller.ts
│   │   │   ├── modifiers.controller.ts
│   │   │   └── dto/
│   │   │
│   │   ├── tables/
│   │   │   ├── tables.controller.ts
│   │   │   ├── tables.service.ts
│   │   │   ├── zones.controller.ts
│   │   │   └── dto/
│   │   │
│   │   ├── orders/
│   │   │   ├── orders.controller.ts
│   │   │   ├── orders.service.ts
│   │   │   ├── order-items.service.ts
│   │   │   ├── order-calculation.service.ts  ← คำนวณราคา/ภาษี/ส่วนลด
│   │   │   └── dto/
│   │   │
│   │   ├── payments/
│   │   │   ├── payments.controller.ts
│   │   │   ├── payments.service.ts
│   │   │   ├── exchange-rate.service.ts
│   │   │   └── dto/
│   │   │
│   │   ├── kitchen/
│   │   │   ├── kitchen.controller.ts
│   │   │   ├── kitchen.service.ts
│   │   │   └── kitchen.gateway.ts           ← WebSocket
│   │   │
│   │   ├── stock/
│   │   │   ├── stock.controller.ts
│   │   │   ├── stock.service.ts
│   │   │   └── dto/
│   │   │
│   │   ├── members/
│   │   │   ├── members.controller.ts
│   │   │   ├── members.service.ts
│   │   │   └── dto/
│   │   │
│   │   ├── shifts/
│   │   │   ├── shifts.controller.ts
│   │   │   ├── shifts.service.ts
│   │   │   └── dto/
│   │   │
│   │   ├── coupons/
│   │   │   ├── coupons.controller.ts
│   │   │   ├── coupons.service.ts
│   │   │   └── dto/
│   │   │
│   │   ├── queue/
│   │   │   ├── queue.controller.ts
│   │   │   ├── queue.service.ts
│   │   │   └── dto/
│   │   │
│   │   ├── reports/
│   │   │   ├── reports.controller.ts
│   │   │   ├── reports.service.ts
│   │   │   ├── dashboard.service.ts
│   │   │   └── export.service.ts            ← Excel/PDF
│   │   │
│   │   ├── notifications/
│   │   │   ├── notifications.controller.ts
│   │   │   ├── notifications.service.ts
│   │   │   ├── notifications.gateway.ts     ← WebSocket
│   │   │   └── push.service.ts              ← FCM/APNs
│   │   │
│   │   ├── sync/
│   │   │   ├── sync.controller.ts
│   │   │   ├── sync.service.ts
│   │   │   └── conflict-resolver.service.ts
│   │   │
│   │   ├── settings/
│   │   │   ├── settings.controller.ts
│   │   │   ├── settings.service.ts
│   │   │   └── backup.service.ts
│   │   │
│   │   ├── import-export/
│   │   │   ├── import.controller.ts
│   │   │   ├── import.service.ts
│   │   │   ├── export.service.ts
│   │   │   └── templates/
│   │   │
│   │   ├── public/                          ← QR Menu (ไม่ต้อง auth)
│   │   │   ├── public-menu.controller.ts
│   │   │   ├── public-order.controller.ts
│   │   │   └── public.service.ts
│   │   │
│   │   └── admin/                           ← Super Admin
│   │       ├── admin-tenants.controller.ts
│   │       ├── admin-plans.controller.ts
│   │       ├── admin-dashboard.controller.ts
│   │       └── admin.service.ts
│   │
│   ├── websocket/
│   │   ├── ws.gateway.ts                    ← Main WebSocket gateway
│   │   └── ws-auth.guard.ts
│   │
│   └── jobs/
│       ├── backup.job.ts
│       ├── subscription-check.job.ts
│       ├── low-stock-alert.job.ts
│       └── cleanup-training.job.ts
│
├── test/
│   ├── unit/
│   ├── integration/
│   └── e2e/
│
└── scripts/
    ├── seed.ts
    └── migrate.ts
```

---

## 6. Project Structure — Flutter

```
lumluay_pos/
├── android/
├── ios/
├── web/
├── macos/
├── windows/
├── linux/
│
├── pubspec.yaml
├── analysis_options.yaml
├── l10n.yaml                              ← i18n config
│
├── assets/
│   ├── images/
│   │   ├── logo.png
│   │   └── placeholder_product.png
│   ├── fonts/
│   │   ├── NotoSansThai/
│   │   ├── NotoSansLao/
│   │   └── Inter/
│   ├── sounds/
│   │   ├── new_order.mp3
│   │   ├── kitchen_ready.mp3
│   │   └── notification.mp3
│   └── templates/
│       └── products_import_template.csv
│
├── lib/
│   ├── main.dart                          ← Entry point
│   ├── app.dart                           ← MaterialApp + Router + Providers
│   ├── injection.dart                     ← Dependency Injection (get_it)
│   │
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart         ← Base URL, endpoints
│   │   │   ├── app_constants.dart         ← App-wide constants
│   │   │   ├── storage_keys.dart          ← SharedPreferences keys
│   │   │   └── asset_paths.dart
│   │   │
│   │   ├── error/
│   │   │   ├── failures.dart              ← Failure classes
│   │   │   └── exceptions.dart
│   │   │
│   │   ├── network/
│   │   │   ├── api_client.dart            ← Dio HTTP client
│   │   │   ├── api_interceptors.dart      ← Auth, tenant, error interceptors
│   │   │   ├── connectivity_service.dart  ← Online/Offline monitor
│   │   │   └── websocket_client.dart      ← WebSocket connection
│   │   │
│   │   ├── database/
│   │   │   ├── app_database.dart          ← SQLite (drift/sqflite)
│   │   │   ├── tables/                    ← Local table definitions
│   │   │   │   ├── local_products.dart
│   │   │   │   ├── local_orders.dart
│   │   │   │   ├── local_sync_queue.dart
│   │   │   │   └── ...
│   │   │   └── daos/                      ← Data Access Objects
│   │   │       ├── product_dao.dart
│   │   │       ├── order_dao.dart
│   │   │       └── sync_dao.dart
│   │   │
│   │   ├── theme/
│   │   │   ├── app_theme.dart             ← Light/Dark themes
│   │   │   ├── app_colors.dart            ← Color palette
│   │   │   ├── app_text_styles.dart
│   │   │   └── app_dimensions.dart        ← Responsive breakpoints
│   │   │
│   │   ├── i18n/
│   │   │   ├── app_th.arb                 ← Thai
│   │   │   ├── app_en.arb                 ← English
│   │   │   └── app_lo.arb                 ← Lao
│   │   │
│   │   ├── router/
│   │   │   ├── app_router.dart            ← GoRouter config
│   │   │   ├── route_names.dart
│   │   │   └── auth_guard.dart
│   │   │
│   │   ├── utils/
│   │   │   ├── currency_formatter.dart    ← Format THB/LAK/USD
│   │   │   ├── date_formatter.dart
│   │   │   ├── validators.dart
│   │   │   ├── receipt_builder.dart       ← สร้างข้อมูลใบเสร็จ
│   │   │   └── sound_player.dart
│   │   │
│   │   └── services/
│   │       ├── auth_service.dart          ← Token management
│   │       ├── sync_engine.dart           ← Offline sync logic
│   │       ├── print_service.dart         ← Printer abstraction
│   │       ├── barcode_service.dart       ← Camera + USB scanner
│   │       ├── cash_drawer_service.dart
│   │       └── notification_service.dart  ← FCM + Local
│   │
│   ├── features/
│   │   ├── auth/
│   │   │   ├── data/
│   │   │   │   ├── models/
│   │   │   │   │   ├── login_request.dart
│   │   │   │   │   ├── login_response.dart
│   │   │   │   │   └── user_model.dart
│   │   │   │   ├── datasources/
│   │   │   │   │   ├── auth_remote_ds.dart
│   │   │   │   │   └── auth_local_ds.dart
│   │   │   │   └── repositories/
│   │   │   │       └── auth_repository_impl.dart
│   │   │   ├── domain/
│   │   │   │   ├── entities/
│   │   │   │   │   └── user.dart
│   │   │   │   ├── repositories/
│   │   │   │   │   └── auth_repository.dart
│   │   │   │   └── usecases/
│   │   │   │       ├── login.dart
│   │   │   │       ├── pin_login.dart
│   │   │   │       └── logout.dart
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── auth_bloc.dart
│   │   │       │   ├── auth_event.dart
│   │   │       │   └── auth_state.dart
│   │   │       ├── screens/
│   │   │       │   ├── login_screen.dart
│   │   │       │   └── pin_screen.dart
│   │   │       └── widgets/
│   │   │           ├── pin_pad.dart
│   │   │           └── tenant_selector.dart
│   │   │
│   │   ├── pos/                           ← ★ หน้าขายหลัก
│   │   │   ├── data/ ...
│   │   │   ├── domain/ ...
│   │   │   └── presentation/
│   │   │       ├── bloc/
│   │   │       │   ├── cart_bloc.dart     ← ตะกร้าสินค้า
│   │   │       │   ├── product_list_bloc.dart
│   │   │       │   └── order_bloc.dart
│   │   │       ├── screens/
│   │   │       │   └── pos_screen.dart    ← หน้าจอขายหลัก
│   │   │       └── widgets/
│   │   │           ├── product_grid.dart
│   │   │           ├── product_list_view.dart
│   │   │           ├── cart_panel.dart
│   │   │           ├── category_bar.dart
│   │   │           ├── search_bar.dart
│   │   │           ├── numpad.dart
│   │   │           ├── modifier_dialog.dart
│   │   │           ├── note_dialog.dart
│   │   │           ├── discount_dialog.dart
│   │   │           └── quick_keys_bar.dart
│   │   │
│   │   ├── checkout/                      ← ★ หน้าชำระเงิน
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── checkout_screen.dart
│   │   │       └── widgets/
│   │   │           ├── payment_method_selector.dart
│   │   │           ├── cash_input.dart
│   │   │           ├── multi_currency_input.dart
│   │   │           ├── split_bill_panel.dart
│   │   │           └── change_display.dart
│   │   │
│   │   ├── tables/                        ← จัดการโต๊ะ
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── floor_plan_screen.dart
│   │   │       └── widgets/
│   │   │           ├── table_card.dart
│   │   │           ├── zone_tabs.dart
│   │   │           └── table_action_sheet.dart
│   │   │
│   │   ├── kitchen/                       ← KDS หน้าจอครัว
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── kitchen_display_screen.dart
│   │   │       └── widgets/
│   │   │           ├── kitchen_order_card.dart
│   │   │           └── kitchen_timer.dart
│   │   │
│   │   ├── orders/                        ← ประวัติออเดอร์
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── order_list_screen.dart
│   │   │       │   └── order_detail_screen.dart
│   │   │       └── widgets/
│   │   │           └── order_card.dart
│   │   │
│   │   ├── products/                      ← จัดการสินค้า
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── product_list_screen.dart
│   │   │       │   └── product_form_screen.dart
│   │   │       └── widgets/
│   │   │
│   │   ├── inventory/                     ← สต็อก
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   ├── stock_overview_screen.dart
│   │   │       │   └── stock_adjustment_screen.dart
│   │   │       └── widgets/
│   │   │
│   │   ├── members/                       ← สมาชิก
│   │   ├── shifts/                        ← กะการทำงาน
│   │   ├── queue/                         ← ระบบคิว
│   │   ├── coupons/                       ← คูปอง
│   │   ├── reports/                       ← รายงาน/Dashboard
│   │   ├── settings/                      ← ตั้งค่าร้าน
│   │   ├── notifications/                 ← แจ้งเตือน
│   │   ├── qr_menu/                       ← E-Menu (QR สำหรับลูกค้า)
│   │   │
│   │   └── admin/                         ← Super Admin (ภายในแอป)
│   │       └── presentation/
│   │           ├── screens/
│   │           │   ├── admin_dashboard_screen.dart
│   │           │   ├── tenant_list_screen.dart
│   │           │   └── plan_management_screen.dart
│   │           └── widgets/
│   │
│   └── shared/
│       └── widgets/
│           ├── app_scaffold.dart           ← Base layout (side nav + content)
│           ├── responsive_layout.dart      ← Phone vs Tablet vs Desktop
│           ├── loading_indicator.dart
│           ├── error_widget.dart
│           ├── empty_state.dart
│           ├── confirm_dialog.dart
│           ├── numpad_widget.dart           ← Shared numpad
│           ├── barcode_scanner_widget.dart
│           ├── language_switcher.dart
│           ├── currency_text.dart           ← แสดงราคาตาม currency
│           └── locale_text.dart             ← แสดงข้อความตาม locale
│
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
│
└── scripts/
    └── build_apk.sh
```

---

## 7. State Management

### 7.1 BLoC + Cubit Strategy

| Scope | Pattern | ใช้ตรงไหน |
|-------|---------|----------|
| **Global** | BLoC (via MultiBlocProvider) | Auth, Theme, Locale, Connectivity, Sync |
| **Feature** | BLoC | Orders, Cart, Products, Kitchen, Reports |
| **Simple** | Cubit | Dialogs, Form state, Toggle (grid/list) |
| **Ephemeral** | setState / ValueNotifier | Animation, UI-only state |

### 7.2 Global Providers

```dart
// app.dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => AuthBloc(...)..add(CheckAuth())),
    BlocProvider(create: (_) => ThemeCubit()),
    BlocProvider(create: (_) => LocaleCubit()),
    BlocProvider(create: (_) => ConnectivityBloc()),
    BlocProvider(create: (_) => SyncBloc()),
    BlocProvider(create: (_) => NotificationBloc()),
    BlocProvider(create: (_) => ShiftBloc()),
  ],
  child: MaterialApp.router(...),
)
```

### 7.3 Dependency Injection (get_it)

```dart
// injection.dart
final sl = GetIt.instance;

void init() {
  // ─── Core ───
  sl.registerLazySingleton(() => Dio());
  sl.registerLazySingleton(() => ApiClient(sl()));
  sl.registerLazySingleton(() => AppDatabase());
  sl.registerLazySingleton(() => WebSocketClient());
  sl.registerLazySingleton(() => ConnectivityService());
  sl.registerLazySingleton(() => SyncEngine(sl(), sl()));
  sl.registerLazySingleton(() => PrintService());
  sl.registerLazySingleton(() => BarcodeService());
  sl.registerLazySingleton(() => SoundPlayer());

  // ─── Auth ───
  sl.registerLazySingleton(() => AuthRemoteDataSource(sl()));
  sl.registerLazySingleton(() => AuthLocalDataSource(sl()));
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl(), sl()),
  );
  sl.registerFactory(() => AuthBloc(sl()));

  // ─── Products ───
  sl.registerLazySingleton(() => ProductRemoteDataSource(sl()));
  sl.registerLazySingleton(() => ProductLocalDataSource(sl()));
  sl.registerLazySingleton<ProductRepository>(
    () => ProductRepositoryImpl(sl(), sl(), sl()),
  );

  // ... (ทุก feature เหมือนกัน)
}
```

---

## 8. Authentication Flow

```
┌─────────────────────────────────────────────┐
│                 App Start                    │
│                    │                         │
│         ┌──────────▼──────────┐              │
│         │  Check stored token │              │
│         └──────────┬──────────┘              │
│                    │                         │
│         ┌──yes─────┴─────no──┐               │
│         │                    │               │
│    ┌────▼────┐         ┌────▼─────┐         │
│    │  Valid? │         │  Login   │         │
│    │ Refresh │         │  Screen  │         │
│    └────┬────┘         └────┬─────┘         │
│         │                   │               │
│    ┌──yes┴──no──┐    ┌──────▼──────┐        │
│    │            │    │  Username + │        │
│    │            │    │  Password   │        │
│    │     ┌──────▼┐   │  + Tenant   │        │
│    │     │Login  │   └──────┬──────┘        │
│    │     │Screen │          │               │
│    │     └───────┘   ┌──────▼──────┐        │
│    │                 │ Store Token │        │
│    ▼                 │ + User Info │        │
│ ┌──────┐             └──────┬──────┘        │
│ │ PIN  │                    │               │
│ │Screen│◄───────────────────┘               │
│ │(Lock)│                                    │
│ └──┬───┘                                    │
│    │ PIN correct                            │
│    ▼                                        │
│ ┌──────────┐                                │
│ │ POS Home │ ← ตรวจ Shift ก่อน             │
│ └──────────┘   (ถ้ายังไม่เปิดกะ → Open Shift)│
└─────────────────────────────────────────────┘
```

### Token Storage
| Platform | Storage |
|----------|---------|
| Mobile (Android/iOS) | `flutter_secure_storage` (Keychain/Keystore) |
| Web | `HttpOnly cookie` (จัดการฝั่ง server) |
| Desktop | `flutter_secure_storage` |

---

## 9. Sync Engine

### 9.1 Sync Flow Diagram

```
┌─────────────────────────────────────────────┐
│              Sync Engine                     │
│                                              │
│  ┌────────────────────────────────────┐      │
│  │      Connectivity Monitor          │      │
│  │  (stream: online / offline)        │      │
│  └──────────┬─────────────────────────┘      │
│             │                                │
│       ┌─────▼─────┐                          │
│       │  Online?  │                          │
│       └─────┬─────┘                          │
│             │ yes                             │
│       ┌─────▼──────────────────────────┐     │
│       │  1. Push pending queue         │     │
│       │     POST /sync/push            │     │
│       │     (batch 50, retry 3x)       │     │
│       └─────┬──────────────────────────┘     │
│             │                                │
│       ┌─────▼──────────────────────────┐     │
│       │  2. Pull server changes        │     │
│       │     GET /sync/pull?since=xxx   │     │
│       │     (products, categories, etc)│     │
│       └─────┬──────────────────────────┘     │
│             │                                │
│       ┌─────▼──────────────────────────┐     │
│       │  3. Resolve conflicts          │     │
│       │     (last-write-wins / manual) │     │
│       └─────┬──────────────────────────┘     │
│             │                                │
│       ┌─────▼──────────────────────────┐     │
│       │  4. Update local DB            │     │
│       │     + Update last_sync_time    │     │
│       └────────────────────────────────┘     │
│                                              │
│  Auto-sync: ทุก 30 วินาทีเมื่อ online       │
│  Manual-sync: กดปุ่ม sync ในแอป             │
│  On-reconnect: sync ทันทีเมื่อกลับ online   │
└─────────────────────────────────────────────┘
```

### 9.2 UUID Generation (Offline-safe)

```dart
// ใช้ UUID v4 ที่สร้างจาก client
// ทำให้ข้อมูลไม่ซ้ำกับเครื่องอื่น แม้ offline
import 'package:uuid/uuid.dart';
final uuid = Uuid();
String newId = uuid.v4(); // "550e8400-e29b-41d4-a716-446655440000"
```

---

## 10. Printing Architecture

```
┌─────────────────────────────────────────┐
│             Print Service                │
│  (Abstract layer จัดการพิมพ์ทุกแบบ)      │
│                                          │
│  ┌───────────────────────────────────┐   │
│  │         Receipt Builder           │   │
│  │  (สร้าง ESC/POS commands)         │   │
│  │  - Logo                           │   │
│  │  - Header (store name, address)   │   │
│  │  - Items + modifiers + notes      │   │
│  │  - Subtotal / Discount / Tax      │   │
│  │  - Total                          │   │
│  │  - Payment info                   │   │
│  │  - Footer (custom text)           │   │
│  │  - QR Code                        │   │
│  └────────────┬──────────────────────┘   │
│               │                          │
│    ┌──────────▼──────────────────┐       │
│    │    Printer Adapter          │       │
│    │                             │       │
│    │  ┌─────────┐ ┌──────────┐  │       │
│    │  │Bluetooth│ │USB (OTG) │  │       │
│    │  │ Printer │ │ Printer  │  │       │
│    │  └─────────┘ └──────────┘  │       │
│    │  ┌─────────┐ ┌──────────┐  │       │
│    │  │  WiFi/  │ │ Browser  │  │       │
│    │  │  LAN    │ │  Print   │  │       │
│    │  └─────────┘ └──────────┘  │       │
│    └─────────────────────────────┘       │
│                                          │
│  Print Jobs:                             │
│  ├── Receipt (ใบเสร็จลูกค้า)              │
│  ├── Kitchen Ticket (สั่งเข้าครัว)        │
│  ├── Reprint (พิมพ์ซ้ำ)                   │
│  └── Report (รายงานกะ)                   │
└──────────────────────────────────────────┘
```

### Key Packages
| Package | Use |
|---------|-----|
| `esc_pos_utils` | สร้าง ESC/POS commands |
| `esc_pos_bluetooth` | พิมพ์ผ่าน Bluetooth |
| `flutter_usb_printer` | พิมพ์ผ่าน USB |
| `esc_pos_printer` | พิมพ์ผ่าน WiFi/LAN |
| `printing` | พิมพ์ผ่าน Browser (PDF) |

---

## 11. Hardware Integration

### 11.1 Barcode Scanner

```
┌─────────────────────────────────┐
│        Barcode Service          │
│                                  │
│  ┌─────────────┐ ┌───────────┐  │
│  │   Camera    │ │ USB/BT    │  │
│  │  Scanner    │ │ Scanner   │  │
│  │  (mobile)   │ │ (HID)     │  │
│  └──────┬──────┘ └─────┬─────┘  │
│         │              │         │
│    mobile_scanner   RawKeyboard  │
│    package         Listener      │
│         │              │         │
│         └──────┬───────┘         │
│                │                 │
│         ┌──────▼───────┐         │
│         │ onBarcodeRead│         │
│         │  callback    │         │
│         └──────────────┘         │
└─────────────────────────────────┘
```

### 11.2 Cash Drawer

```dart
// Cash Drawer เปิดผ่าน Printer (Kick command)
// ESC/POS command: \x1B\x70\x00\x19\xFA
class CashDrawerService {
  Future<void> open() async {
    final printer = await PrintService.getDefaultPrinter();
    await printer.sendRaw([0x1B, 0x70, 0x00, 0x19, 0xFA]);
  }
}
```

### 11.3 Customer Display (Dual Screen)

```
┌─────────────────────────────────────────┐
│  Presentation API (Android)             │
│                                          │
│  Screen 1 (Cashier)     Screen 2 (Customer)
│  ┌──────────────┐       ┌──────────────┐│
│  │   POS App    │       │   Customer   ││
│  │   (Main)     │       │   Display    ││
│  │              │       │   Widget     ││
│  └──────────────┘       └──────────────┘│
│                                          │
│  ใช้ flutter_presentation_display       │
│  หรือ Android Presentation API           │
│  ผ่าน platform channel                   │
└─────────────────────────────────────────┘
```

---

## 12. Multi-language (i18n)

### 12.1 App UI Translations (ARB files)

```
lib/core/i18n/
├── app_th.arb    ← ไทย (default)
├── app_en.arb    ← English
└── app_lo.arb    ← ລາວ
```

```json
// app_th.arb
{
  "@@locale": "th",
  "appTitle": "LUMLUAY POS",
  "login": "เข้าสู่ระบบ",
  "username": "ชื่อผู้ใช้",
  "password": "รหัสผ่าน",
  "enterPin": "กรุณาใส่ PIN",
  "pos": "หน้าขาย",
  "orders": "ออเดอร์",
  "products": "สินค้า",
  "tables": "โต๊ะ",
  "kitchen": "ครัว",
  "reports": "รายงาน",
  "settings": "ตั้งค่า",
  "total": "รวมทั้งหมด",
  "subtotal": "ยอดรวม",
  "discount": "ส่วนลด",
  "tax": "ภาษี",
  "serviceCharge": "ค่าบริการ",
  "cash": "เงินสด",
  "change": "เงินทอน",
  "pay": "ชำระเงิน",
  "printReceipt": "พิมพ์ใบเสร็จ",
  "voidOrder": "ยกเลิกบิล",
  "holdOrder": "พักบิล",
  "currencyFormatTHB": "฿{amount}",
  "@currencyFormatTHB": { "placeholders": { "amount": {} } },
  "currencyFormatLAK": "₭{amount}",
  "currencyFormatUSD": "${amount}",
  "itemCount": "{count} รายการ",
  "@itemCount": { "placeholders": { "count": {} } }
}
```

### 12.2 Dynamic Content (JSONB จาก Server)

```dart
// สำหรับข้อมูลที่มาจาก DB (ชื่อสินค้า, หมวดหมู่)
// เก็บเป็น JSONB: {"th":"ข้าวผัด","en":"Fried Rice","lo":"ເຂົ້າຂຽວ"}

class LocaleText extends StatelessWidget {
  final Map<String, String> translations;

  String get text {
    final locale = context.read<LocaleCubit>().state; // 'th','en','lo'
    return translations[locale] ?? translations['th'] ?? '';
  }
}
```

---

## 13. Theming System

### 13.1 Color Palette

```dart
// Primary: น้ำเงิน Professional
class AppColors {
  // Brand
  static const primary = Color(0xFF1565C0);        // Blue 800
  static const primaryLight = Color(0xFF42A5F5);    // Blue 400
  static const primaryDark = Color(0xFF0D47A1);     // Blue 900

  // Semantic
  static const success = Color(0xFF4CAF50);         // Green
  static const warning = Color(0xFFFFA726);         // Orange
  static const error = Color(0xFFEF5350);           // Red
  static const info = Color(0xFF29B6F6);            // Light Blue

  // Table Status
  static const tableAvailable = Color(0xFF4CAF50);  // Green
  static const tableOccupied = Color(0xFFEF5350);   // Red
  static const tableReserved = Color(0xFFFFA726);   // Orange
  static const tableMerged = Color(0xFF7E57C2);     // Purple

  // Order Status
  static const orderDraft = Color(0xFF9E9E9E);
  static const orderOpen = Color(0xFF42A5F5);
  static const orderCompleted = Color(0xFF4CAF50);
  static const orderVoided = Color(0xFFEF5350);
  static const orderHeld = Color(0xFFFFA726);

  // Kitchen Status
  static const kitchenNew = Color(0xFFEF5350);      // Red (urgent)
  static const kitchenPreparing = Color(0xFFFFA726); // Orange
  static const kitchenReady = Color(0xFF4CAF50);     // Green
}
```

### 13.2 Responsive Breakpoints

```dart
class AppDimensions {
  // Breakpoints
  static const double mobileMax = 600;
  static const double tabletMax = 1024;
  // > 1024 = Desktop

  // POS Layout
  static const double posProductPanelRatio = 0.60;  // 60% สินค้า
  static const double posCartPanelRatio = 0.40;     // 40% ตะกร้า

  // Grid
  static const int productGridMobile = 2;  // 2 columns
  static const int productGridTablet = 3;  // 3 columns
  static const int productGridDesktop = 4; // 4 columns
}
```

### 13.3 Theme Switching

```dart
class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit() : super(ThemeMode.system);

  void setLight() => emit(ThemeMode.light);
  void setDark() => emit(ThemeMode.dark);
  void setSystem() => emit(ThemeMode.system);
}
```

---

## 14. WebSocket Architecture

```
┌──────────────────────────────────────────┐
│          WebSocket Client                 │
│                                           │
│  ┌──────────────────────────────────┐     │
│  │     Connection Manager           │     │
│  │  - Auto reconnect (exp. backoff) │     │
│  │  - Heartbeat (30s ping/pong)     │     │
│  │  - Auth token on connect         │     │
│  └──────────┬───────────────────────┘     │
│             │                             │
│  ┌──────────▼───────────────────────┐     │
│  │     Channel Subscriptions        │     │
│  │                                   │     │
│  │  orders  ─────→ OrderBloc         │     │
│  │  kitchen ─────→ KitchenBloc       │     │
│  │  tables  ─────→ TableBloc         │     │
│  │  queue   ─────→ QueueBloc         │     │
│  │  notifications → NotifBloc        │     │
│  │  sync    ─────→ SyncBloc          │     │
│  └──────────────────────────────────┘     │
└──────────────────────────────────────────┘
```

```dart
// websocket_client.dart
class WebSocketClient {
  late IOWebSocketChannel _channel;
  final Map<String, StreamController> _channels = {};

  void connect(String token, String tenantId) {
    _channel = IOWebSocketChannel.connect(
      'wss://api.lumluay.com/ws?token=$token&tenant_id=$tenantId',
    );
    _channel.stream.listen(_handleMessage, onDone: _reconnect);
  }

  Stream<T> subscribe<T>(String channel) {
    _channels[channel] ??= StreamController<T>.broadcast();
    return _channels[channel]!.stream as Stream<T>;
  }

  void _handleMessage(dynamic data) {
    final msg = jsonDecode(data);
    _channels[msg['channel']]?.add(msg['data']);
  }
}
```

---

## 15. Security

### 15.1 Authentication & Authorization

| Layer | Security Measure |
|-------|-----------------|
| JWT | Access token (15min) + Refresh token (30 days) |
| PIN | bcrypt hashed, max 5 attempts → lock 5 min |
| Password | bcrypt (12 rounds), min 8 chars |
| API | Rate limiting per tenant + per IP |
| Tenant | Row Level Security + middleware tenant check |
| Role | Route-based + field-level permissions |

### 15.2 Data Security

| Area | Implementation |
|------|---------------|
| Transport | HTTPS (TLS 1.3) everywhere |
| Token Storage | flutter_secure_storage (Keychain/Keystore) |
| SQLite | SQLCipher encryption (optional) |
| Passwords | bcrypt (never plain text) |
| PII | Encrypted at rest in PostgreSQL |
| Audit | All sensitive operations logged |
| Input | Zod validation + SQL injection prevention (ORM) |
| XSS | Content-Security-Policy headers |
| CORS | Whitelist domains only |

### 15.3 Offline Data Security

```dart
// SQLite ใช้ sqflite_sqlcipher สำหรับ encrypt local DB
final db = await openDatabase(
  'lumluay_pos.db',
  password: await SecureStorage.getDatabaseKey(),
);
```

---

## 16. Deployment Architecture

```
┌─────────────────────────────────────────────────────┐
│                    VPS (Docker)                      │
│                                                      │
│  ┌──────────────────────────────────────────────┐   │
│  │              Docker Compose                   │   │
│  │                                               │   │
│  │  ┌──────────────┐  ┌──────────────────┐      │   │
│  │  │    Nginx     │  │  Certbot (SSL)   │      │   │
│  │  │ :80 → :443   │  │  Let's Encrypt   │      │   │
│  │  └──────┬───────┘  └──────────────────┘      │   │
│  │         │                                     │   │
│  │  ┌──────▼───────┐  ┌──────────────────┐      │   │
│  │  │  API Server  │  │  API Server      │      │   │
│  │  │  (Node.js)   │  │  (Node.js)       │      │   │
│  │  │  Instance 1  │  │  Instance 2      │      │   │
│  │  │  :3000       │  │  :3001           │      │   │
│  │  └──────┬───────┘  └──────┬───────────┘      │   │
│  │         │                  │                   │   │
│  │  ┌──────▼──────────────────▼───────────┐      │   │
│  │  │           pgBouncer                 │      │   │
│  │  │      (Connection Pool)              │      │   │
│  │  └──────────────┬─────────────────────┘      │   │
│  │                 │                             │   │
│  │  ┌──────────────▼───────┐  ┌──────────┐      │   │
│  │  │     PostgreSQL       │  │   Redis  │      │   │
│  │  │     :5432            │  │  :6379   │      │   │
│  │  │  + Auto backup daily │  │          │      │   │
│  │  └──────────────────────┘  └──────────┘      │   │
│  │                                               │   │
│  └──────────────────────────────────────────────┘   │
│                                                      │
│  Monitoring: Prometheus + Grafana (optional)         │
│  Logs: Docker logs → Loki (optional)                 │
└─────────────────────────────────────────────────────┘
```

### docker-compose.yml (พื้นฐาน)

```yaml
version: '3.8'
services:
  nginx:
    image: nginx:alpine
    ports: ["80:80", "443:443"]
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf
      - certbot-data:/etc/letsencrypt
    depends_on: [api]

  api:
    build: ./lumluay-api
    environment:
      - DATABASE_URL=postgresql://...
      - REDIS_URL=redis://redis:6379
      - JWT_SECRET=${JWT_SECRET}
    deploy:
      replicas: 2
    depends_on: [postgres, redis]

  postgres:
    image: postgres:16-alpine
    volumes:
      - pgdata:/var/lib/postgresql/data
      - ./backups:/backups
    environment:
      POSTGRES_DB: lumluay_pos
      POSTGRES_USER: ${DB_USER}
      POSTGRES_PASSWORD: ${DB_PASSWORD}

  redis:
    image: redis:7-alpine
    volumes:
      - redis-data:/data

  pgbouncer:
    image: edoburu/pgbouncer
    environment:
      DATABASE_URL: postgresql://${DB_USER}:${DB_PASSWORD}@postgres:5432/lumluay_pos
      MAX_CLIENT_CONN: 200
      DEFAULT_POOL_SIZE: 25

volumes:
  pgdata:
  redis-data:
  certbot-data:
```

### App Distribution

| Platform | Distribution |
|----------|-------------|
| Android APK | Direct download / Google Play |
| iOS | App Store / TestFlight |
| Web PWA | https://app.lumluay.com |
| APK for POS Machine | Sideload .apk (MDM optional) |

---

## 17. Tech Stack Summary

### Backend

| Component | Technology | Version |
|-----------|-----------|---------|
| Runtime | Node.js | 20 LTS |
| Language | TypeScript | 5.x |
| Framework | NestJS | 10.x |
| ORM | Drizzle ORM | latest |
| Database | PostgreSQL | 16 |
| Cache | Redis | 7 |
| Job Queue | BullMQ | latest |
| Validation | Zod | latest |
| Auth | Passport JWT | latest |
| WebSocket | Socket.IO | 4.x |
| Testing | Jest + Supertest | latest |
| Container | Docker + docker-compose | latest |

### Flutter App

| Component | Technology / Package | Purpose |
|-----------|---------------------|---------|
| Language | Dart 3.x | - |
| Framework | Flutter 3.x | Cross-platform |
| State Mgmt | flutter_bloc | BLoC pattern |
| DI | get_it + injectable | Dependency injection |
| Navigation | go_router | Declarative routing |
| HTTP | dio | API client |
| WebSocket | web_socket_channel | Real-time |
| Local DB | drift (SQLite) | Offline storage |
| Secure Storage | flutter_secure_storage | Token/key storage |
| i18n | flutter_localizations + intl | Multi-language |
| Barcode | mobile_scanner | Camera scanner |
| Printing | esc_pos_utils + esc_pos_bluetooth | Thermal printing |
| Image | cached_network_image | Product images |
| Excel | excel | Import/Export |
| PDF | pdf + printing | Reports |
| Charts | fl_chart | Dashboard charts |
| Connectivity | connectivity_plus | Online/offline detect |
| Permission | permission_handler | Camera, Bluetooth |
| Sound | audioplayers | Alert sounds |
| Dual Screen | presentation_displays | Customer display |
| UUID | uuid | Offline-safe ID |
| Testing | mockito + bloc_test | Unit/widget tests |

---

## Navigation Flow (GoRouter)

```
/                           → Redirect to /login or /pos
/login                      → Login screen
/pin                        → PIN lock screen
/setup-wizard               → First-time setup

/pos                        → ★ POS main screen (ขายของ)
/pos/checkout/:orderId      → Checkout / Payment
/pos/held-orders            → Held orders list

/tables                     → Floor plan / Table management
/tables/:id                 → Table detail + current order

/kitchen                    → KDS (Kitchen Display)

/orders                     → Order history
/orders/:id                 → Order detail

/queue                      → Queue management

/products                   → Product list
/products/new               → Create product
/products/:id/edit          → Edit product
/categories                 → Category management
/modifiers                  → Modifier groups

/inventory                  → Stock overview
/inventory/adjustment       → Stock adjustment

/members                    → Member list
/members/:id                → Member detail

/coupons                    → Coupon list
/coupons/new                → Create coupon

/reports                    → Dashboard
/reports/sales              → Sales report
/reports/products           → Product report
/reports/profit-loss        → P&L report

/settings                   → Store settings
/settings/printers          → Printer config
/settings/tax               → Tax rates
/settings/users             → User management
/settings/backup            → Backup/Restore

/admin                      → Super Admin dashboard (super_admin only)
/admin/tenants              → Tenant list
/admin/tenants/:id          → Tenant detail
/admin/plans                → Subscription plans

/qr-menu/:tenantSlug        → Public E-Menu (ไม่ต้อง auth)
```
