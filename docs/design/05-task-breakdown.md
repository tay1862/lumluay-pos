# LUMLUAY POS - Task Breakdown (Implementation Roadmap)

> แตก Task จาก Design Doc ทั้ง 4 อย่างละเอียด
> รวม ~280 tasks | 18 Phases | เรียงตาม dependency
> Last Updated: 2026-04-02 (updated) (updated) (updated) (updated)

---

## สารบัญ

- [Phase 0: Project Setup & Infrastructure](#phase-0-project-setup--infrastructure)
- [Phase 1: Database & Backend Foundation](#phase-1-database--backend-foundation)
- [Phase 2: Authentication & Authorization](#phase-2-authentication--authorization)
- [Phase 3: Tenant & Store Settings](#phase-3-tenant--store-settings)
- [Phase 4: Flutter App Foundation](#phase-4-flutter-app-foundation)
- [Phase 5: Products & Categories](#phase-5-products--categories)
- [Phase 6: POS Core — Cart & Order](#phase-6-pos-core--cart--order)
- [Phase 7: Checkout & Payment](#phase-7-checkout--payment)
- [Phase 8: Tables & Floor Plan (Restaurant)](#phase-8-tables--floor-plan-restaurant)
- [Phase 9: Kitchen Display System (KDS)](#phase-9-kitchen-display-system-kds)
- [Phase 10: Shifts & Cash Management](#phase-10-shifts--cash-management)
- [Phase 11: Inventory & Stock](#phase-11-inventory--stock)
- [Phase 12: Members & Customers](#phase-12-members--customers)
- [Phase 13: Coupons & Promotions](#phase-13-coupons--promotions)
- [Phase 14: Queue Management](#phase-14-queue-management)
- [Phase 15: Reports & Dashboard](#phase-15-reports--dashboard)
- [Phase 16: Offline & Sync Engine](#phase-16-offline--sync-engine)
- [Phase 17: Hardware, Notification, Import/Export, QR Menu, Admin](#phase-17-hardware-notification-importexport-qr-menu-admin)
- [Phase 18: Testing, Polish & Deployment](#phase-18-testing-polish--deployment)

---

## Task Status Legend

| Status | Icon |
|--------|------|
| Not Started | ⬜ |
| In Progress | 🔄 |
| Done | ✅ |
| Blocked | 🚫 |

---

## Phase 0: Project Setup & Infrastructure

> ตั้งค่าโปรเจค, เครื่องมือ, CI/CD, Docker

### 0.1 Backend Project Init
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 0.1.1 | ✅ สร้างโปรเจค NestJS + TypeScript | `nest new lumluay-api`, ตั้ง tsconfig, eslint, prettier | - |
| 0.1.2 | ✅ ตั้งค่า Docker Compose | `docker-compose.yml` — PostgreSQL 16, Redis 7, API, Nginx, PgBouncer | 0.1.1 |
| 0.1.3 | ✅ ตั้งค่า Dockerfile (Backend) | Multi-stage build, production-ready | 0.1.1 |
| 0.1.4 | ⬜ ตั้งค่า Environment Config | `.env.example`, config module, validation (Zod) | 0.1.1 |
| 0.1.5 | ✅ ตั้งค่า Drizzle ORM | `drizzle.config.ts`, database connection, migration tools | 0.1.1 |
| 0.1.6 | ✅ ตั้งค่า Redis Connection | Redis module, config, health check | 0.1.2 |
| 0.1.7 | ✅ ตั้งค่า Logger | Structured logging (pino/winston), log levels, request logger | 0.1.1 |
| 0.1.8 | ✅ สร้าง API Health Check endpoint | `GET /health` — DB, Redis, uptime | 0.1.5, 0.1.6 |
| 0.1.9 | ✅ ตั้งค่า CORS | Allow origins สำหรับ Flutter Web, QR Menu | 0.1.1 |

### 0.2 Flutter Project Init
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 0.2.1 | ✅ สร้างโปรเจค Flutter | `flutter create lumluay_pos`, ตั้ง `analysis_options.yaml` | - |
| 0.2.2 | ✅ เพิ่ม Dependencies (pubspec.yaml) | flutter_bloc, get_it, dio, go_router, drift, freezed, json_serializable, intl, etc. (~30 packages) | 0.2.1 |
| 0.2.3 | ✅ ตั้งค่า Folder Structure | สร้างโครงสร้าง Clean Architecture — `core/`, `features/`, `shared/` | 0.2.1 |
| 0.2.4 | ✅ ตั้งค่า Flavors/Environments | Dev, Staging, Prod — แยก API URL, config | 0.2.1 |
| 0.2.5 | ✅ ตั้งค่า Code Generation | build_runner config สำหรับ freezed, json_serializable, drift | 0.2.2 |
| 0.2.6 | ✅ ตั้งค่า Android Signing | Keystore, `build.gradle` signing config สำหรับ APK release | 0.2.1 |
| 0.2.7 | ✅ ตั้งค่า iOS Bundle / Provisioning | Bundle ID, provisioning profiles | 0.2.1 |

### 0.3 Git & CI/CD
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 0.3.1 | ✅ ตั้งค่า Git Repository | Monorepo (lumluay-api + lumluay_pos) หรือ 2 repo, branch strategy | - |
| 0.3.2 | ✅ ตั้งค่า .gitignore | Backend (.env, node_modules, dist) + Flutter (.dart_tool, build) | 0.3.1 |
| 0.3.3 | ✅ ตั้งค่า CI Pipeline | GitHub Actions / GitLab CI — lint, test, build | 0.3.1 |

---

## Phase 1: Database & Backend Foundation

> สร้าง Database schema ทั้งหมด, Common middleware, Base classes

### 1.1 Database Schema
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 1.1.1 | ✅ สร้าง Drizzle Schema: `tenants` | table definition, ENUM types | 0.1.5 |
| 1.1.2 | ✅ สร้าง Drizzle Schema: `users` + `user_sessions` | user_role ENUM, relations | 1.1.1 |
| 1.1.3 | ✅ สร้าง Drizzle Schema: `store_settings` + `tax_rates` | JSONB fields, relations | 1.1.1 |
| 1.1.4 | ✅ สร้าง Drizzle Schema: `categories` | 2-level parent_id, JSONB name | 1.1.1 |
| 1.1.5 | ✅ สร้าง Drizzle Schema: `products` + `product_variants` | product_type ENUM, all fields | 1.1.4 |
| 1.1.6 | ✅ สร้าง Drizzle Schema: `modifier_groups` + `modifier_options` + `product_modifier_groups` | M:N relations | 1.1.5 |
| 1.1.7 | ✅ สร้าง Drizzle Schema: `unit_conversions` | conversion_rate | 1.1.5 |
| 1.1.8 | ✅ สร้าง Drizzle Schema: `zones` + `tables` | table_status ENUM, merged_into_id | 1.1.1 |
| 1.1.9 | ✅ สร้าง Drizzle Schema: `orders` | order_status, order_type ENUM, all FKs | 1.1.2, 1.1.8 |
| 1.1.10 | ✅ สร้าง Drizzle Schema: `order_items` + `order_item_modifiers` | snapshot fields, status ENUM | 1.1.9, 1.1.6 |
| 1.1.11 | ✅ สร้าง Drizzle Schema: `payments` | payment_method ENUM, multi-currency fields | 1.1.9 |
| 1.1.12 | ✅ สร้าง Drizzle Schema: `stock_movements` | stock_movement_type ENUM | 1.1.5 |
| 1.1.13 | ✅ สร้าง Drizzle Schema: `members` | unique phone per tenant | 1.1.1 |
| 1.1.14 | ✅ สร้าง Drizzle Schema: `shifts` | shift_status, sales_by_method JSONB | 1.1.2 |
| 1.1.15 | ✅ สร้าง Drizzle Schema: `coupons` | coupon_type ENUM, limits | 1.1.5 |
| 1.1.16 | ✅ สร้าง Drizzle Schema: `queue_tickets` | queue_status ENUM | 1.1.1 |
| 1.1.17 | ✅ สร้าง Drizzle Schema: `kitchen_orders` | kitchen_status ENUM | 1.1.10 |
| 1.1.18 | ✅ สร้าง Drizzle Schema: `audit_logs` | action ENUM, JSONB changes | 1.1.2 |
| 1.1.19 | ✅ สร้าง Drizzle Schema: `sync_queue` | sync_status ENUM | 1.1.1 |
| 1.1.20 | ✅ สร้าง Drizzle Schema: `notifications` | notification_type ENUM | 1.1.2 |
| 1.1.21 | ✅ สร้าง Drizzle Schema: `subscription_plans` + `tenant_subscriptions` | pricing fields | 1.1.1 |
| 1.1.22 | ✅ สร้าง Migration: Initial | สร้าง + run migration ครั้งแรก (ทุกตาราง) | 1.1.1–1.1.21 |
| 1.1.23 | ✅ สร้าง Indexes ทั้งหมด | ตาม design doc — partial indexes, composite indexes | 1.1.22 |
| 1.1.24 | ✅ สร้าง Row Level Security (RLS) Policies | tenant_id isolation ทุกตาราง | 1.1.22 |

### 1.2 Backend Common / Shared
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 1.2.1 | ✅ สร้าง Common DTOs | PaginationDto, SortDto, FilterDto, ApiResponse wrapper | 0.1.1 |
| 1.2.2 | ✅ สร้าง ValidationPipe (Zod) | Global validation pipe, custom error format | 0.1.1 |
| 1.2.3 | ✅ สร้าง HttpExceptionFilter | Global exception handler → standard error response | 0.1.1 |
| 1.2.4 | ✅ สร้าง TransformInterceptor | Wrap response ใน `{ success, data, meta }` format | 0.1.1 |
| 1.2.5 | ✅ สร้าง Utility Functions | `crypto.util.ts` (hash PIN/password), `currency.util.ts`, `receipt-number.util.ts` | 0.1.1 |
| 1.2.6 | ✅ สร้าง Custom Decorators | `@Roles()`, `@CurrentTenant()`, `@CurrentUser()` | 0.1.1 |
| 1.2.7 | ✅ สร้าง Rate Limiting Middleware | Per-endpoint rate limits (ตาม API design doc) | 0.1.6 |
| 1.2.8 | ✅ สร้าง Database Module | Drizzle ORM provider, connection pool setup | 0.1.5 |

---

## Phase 2: Authentication & Authorization

> Login, PIN, JWT, Role guard, Session management

### 2.1 Backend — Auth Module
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 2.1.1 | ✅ สร้าง Auth Module (NestJS) | Module, Controller, Service | 1.1.2, 1.2.1 |
| 2.1.2 | ✅ สร้าง LoginDto + validation | tenant_slug, username, password validation | 2.1.1 |
| 2.1.3 | ✅ Implement `POST /auth/login` | ตรวจ credentials → bcrypt compare → สร้าง JWT + refresh token → บันทึก session | 2.1.1 |
| 2.1.4 | ✅ Implement `POST /auth/pin` | ตรวจ PIN → bcrypt compare → สร้าง short-lived token | 2.1.1 |
| 2.1.5 | ✅ Implement `POST /auth/refresh` | refresh token → ออก JWT ใหม่, rotate refresh token | 2.1.1 |
| 2.1.6 | ✅ Implement `POST /auth/logout` | ลบ session record, blacklist token | 2.1.1 |
| 2.1.7 | ✅ Implement `GET /auth/me` | คืน user info + tenant info + permissions | 2.1.3 |
| 2.1.8 | ✅ สร้าง JWT Strategy (Passport) | JWT validation, extract user from token | 2.1.3 |
| 2.1.9 | ✅ สร้าง JwtAuthGuard | Protect endpoints ด้วย JWT | 2.1.8 |
| 2.1.10 | ✅ สร้าง RoleGuard | ตรวจ role ตาม `@Roles()` decorator | 2.1.9, 1.2.6 |
| 2.1.11 | ✅ สร้าง TenantMiddleware | Resolve tenant จาก `X-Tenant-ID` header + validate vs token | 1.2.8 |
| 2.1.12 | ✅ สร้าง AuditInterceptor | บันทึก audit log อัตโนมัติ (who, what, when, changes) | 1.1.18 |
| 2.1.13 | ✅ สร้าง TrainingInterceptor | แยก training mode data (is_training flag) | 2.1.11 |

### 2.2 Flutter — Auth Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 2.2.1 | ✅ สร้าง Auth Data Models | `LoginRequest`, `LoginResponse`, `UserModel` (freezed) | 0.2.5 |
| 2.2.2 | ✅ สร้าง AuthRemoteDataSource | Dio calls: login, pin, refresh, logout, me | 0.2.2 |
| 2.2.3 | ✅ สร้าง AuthLocalDataSource | flutter_secure_storage: save/read/delete token, user info | 0.2.2 |
| 2.2.4 | ✅ สร้าง Auth Repository (Interface + Impl) | Combine remote + local, handle token refresh | 2.2.2, 2.2.3 |
| 2.2.5 | ✅ สร้าง Auth Use Cases | Login, PinLogin, Logout, GetCurrentUser, CheckAuth | 2.2.4 |
| 2.2.6 | ✅ สร้าง AuthBloc | Events: Login, PinLogin, Logout, CheckAuth; States: Initial, Loading, Authenticated, Unauthenticated, Error | 2.2.5 |
| 2.2.7 | ✅ สร้าง Login Screen UI | ตาม wireframe — tenant slug, username, password, language selector | 2.2.6 |
| 2.2.8 | ✅ สร้าง PIN Lock Screen UI | ตาม wireframe — avatar, PIN pad (0-9), shake animation on error | 2.2.6 |
| 2.2.9 | ✅ สร้าง Auth Guard (GoRouter redirect) | ตรวจ auth state → redirect ไป login/pin/pos | 2.2.6 |
| 2.2.10 | ✅ Implement Auto-lock | Timer idle → กลับ PIN screen, ตั้งค่า auto_lock_minutes | 2.2.8 |
| 2.2.11 | ✅ สร้าง API Client + Interceptors | Dio base client, add JWT header, add X-Tenant-ID, auto refresh token, error handling | 0.2.2 |

---

## Phase 3: Tenant & Store Settings

> ข้อมูลร้าน, ตั้งค่าภาษี, สกุลเงิน, ใบเสร็จ

### 3.1 Backend — Tenant Module
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 3.1.1 | ✅ สร้าง Tenant Module | Module, Controller, Service | 1.1.1, 1.1.3 |
| 3.1.2 | ✅ Implement `GET /tenant` | คืนข้อมูล tenant + store_settings + tax_rates | 3.1.1 |
| 3.1.3 | ✅ Implement `PATCH /tenant` | อัพเดทข้อมูลร้าน (name, phone, address, logo) | 3.1.1 |

### 3.2 Backend — Settings Module
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 3.2.1 | ✅ สร้าง Settings Module | Module, Controller, Service | 1.1.3 |
| 3.2.2 | ✅ Implement `GET /settings` | คืน store_settings ทั้งหมด | 3.2.1 |
| 3.2.3 | ✅ Implement `PATCH /settings` | Update individual setting fields | 3.2.1 |
| 3.2.4 | ✅ Implement Tax Rates CRUD | `POST/GET/PATCH/DELETE /settings/tax-rates` | 3.2.1 |
| 3.2.5 | ✅ Implement Currency & Exchange Rates | `GET/PATCH /settings/currencies`, `PATCH /settings/exchange-rates` | 3.2.1 |
| 3.2.6 | ✅ Implement Receipt Settings | `GET/PATCH /settings/receipt` — header, footer, prefix, width | 3.2.1 |
| 3.2.7 | ✅ Implement Printer Config | `GET/POST/PATCH/DELETE /settings/printers` — JSONB config | 3.2.1 |

### 3.3 Backend — Users Module
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 3.3.1 | ✅ สร้าง Users Module | Module, Controller, Service | 1.1.2 |
| 3.3.2 | ✅ Implement Users CRUD | `POST/GET/PATCH/DELETE /users` — create, list, update, soft delete | 3.3.1 |
| 3.3.3 | ✅ Implement Change Password | `PATCH /users/:id/password` | 3.3.1 |
| 3.3.4 | ✅ Implement Change PIN | `PATCH /users/:id/pin` | 3.3.1 |

### 3.4 Flutter — Settings Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 3.4.1 | ✅ สร้าง Settings Data Models | StoreSettings, TaxRate, PrinterConfig (freezed) | 0.2.5 |
| 3.4.2 | ✅ สร้าง Settings Repository | Remote + Local datasource | 3.4.1 |
| 3.4.3 | ✅ สร้าง Settings Main Screen UI | ตาม wireframe — grouped list of settings | 3.4.2 |
| 3.4.4 | ✅ สร้าง Store Info Screen | ชื่อร้าน, โลโก้, เบอร์, ที่อยู่, เลขภาษี | 3.4.3 |
| 3.4.5 | ✅ สร้าง Tax Settings Screen | CRUD tax rates, toggle inclusive/exclusive | 3.4.3 |
| 3.4.6 | ✅ สร้าง Currency Settings Screen | เลือก currencies, ใส่อัตราแลกเปลี่ยน, ทศนิยม | 3.4.3 |
| 3.4.7 | ✅ สร้าง Receipt Settings Screen | Header/footer text, logo toggle, width 58/80mm, preview | 3.4.3 |
| 3.4.8 | ✅ สร้าง Printer Settings Screen | เพิ่ม/แก้ไข printer, test print, เลือก connection type | 3.4.3 |
| 3.4.9 | ✅ สร้าง User Management Screen | List users, create/edit user form, assign role + PIN | 3.4.3 |
| 3.4.10 | ✅ สร้าง Language Settings Screen | เลือกภาษา TH/EN/LO, immediate switch | 3.4.3 |
| 3.4.11 | ✅ สร้าง Theme Settings Screen | Dark/Light/Auto toggle, preview | 3.4.3 |
| 3.4.12 | ✅ สร้าง Auto-lock Settings Screen | เลือกเวลา auto-lock (5/10/15/30 นาที / ปิด) | 3.4.3 |
| 3.4.13 | ✅ สร้าง Training Mode Toggle | เปิด/ปิด training mode, คำเตือน | 3.4.3 |

### 3.5 Setup Wizard
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 3.5.1 | ✅ สร้าง Setup Wizard Flow (Flutter) | 5 steps: ข้อมูลร้าน → สกุลเงิน/ภาษี → เครื่องพิมพ์ → สินค้า → พนักงาน | 3.4.1 |
| 3.5.2 | ✅ สร้าง Step 1: ข้อมูลร้าน | Logo upload, ชื่อ, เบอร์, ที่อยู่, เลขภาษี | 3.5.1 |
| 3.5.3 | ✅ สร้าง Step 2: สกุลเงิน + ภาษี | เลือก default currency, ตั้งค่า VAT | 3.5.1 |
| 3.5.4 | ✅ สร้าง Step 3: เครื่องพิมพ์ | ค้นหา/เชื่อมต่อ printer (BT/USB/WiFi) | 3.5.1 |
| 3.5.5 | ✅ สร้าง Step 4: นำเข้าสินค้า | เลือก "ใช้ตัวอย่าง" หรือ "Import CSV" หรือ "เพิ่มทีหลัง" | 3.5.1 |
| 3.5.6 | ✅ สร้าง Step 5: สร้างบัญชีพนักงาน | เพิ่ม user คนแรก (หลัง owner) | 3.5.1 |
| 3.5.7 | ✅ สร้าง Sample Data Seed (Backend) | ข้อมูลตัวอย่างร้านอาหาร (5 หมวด, 20 สินค้า) | 1.1.22 |

---

## Phase 4: Flutter App Foundation

> Design System, Navigation, Shared widgets, Theme, i18n

### 4.1 Design System & Theme
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 4.1.1 | ✅ สร้าง AppColors | Color palette — Primary Blue, Semantic, Neutral (Light/Dark) | 0.2.3 |
| 4.1.2 | ✅ สร้าง AppTextStyles | Typography scale — H1-H3, Body, Caption, Price (tabular nums) | 0.2.3 |
| 4.1.3 | ✅ สร้าง AppDimensions | Spacing scale (4dp base), border radius, breakpoints | 0.2.3 |
| 4.1.4 | ✅ สร้าง AppTheme (Light + Dark) | ThemeData with colors, text, components customized | 4.1.1, 4.1.2 |
| 4.1.5 | ✅ สร้าง ThemeCubit | Toggle Dark/Light/Auto, persist to SharedPrefs | 4.1.4 |

### 4.2 i18n (Multi-language)
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 4.2.1 | ✅ ตั้งค่า l10n.yaml | Flutter intl config, output dir | 0.2.1 |
| 4.2.2 | ✅ สร้าง app_th.arb | ไฟล์ภาษาไทย — ทุกข้อความในแอป (~500 keys) | 4.2.1 |
| 4.2.3 | ✅ สร้าง app_en.arb | ไฟล์ภาษาอังกฤษ | 4.2.1 |
| 4.2.4 | ✅ สร้าง app_lo.arb | ไฟล์ภาษาลาว | 4.2.1 |
| 4.2.5 | ✅ สร้าง LocaleCubit | Switch locale, persist, update app | 4.2.2 |
| 4.2.6 | ✅ สร้าง LocaleText Widget | แสดง JSONB text ตาม current locale (สำหรับ dynamic data) | 4.2.5 |

### 4.3 Navigation & Layout
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 4.3.1 | ✅ สร้าง GoRouter Config | ทุก route (~30 routes), nested navigation | 0.2.2 |
| 4.3.2 | ✅ สร้าง AppScaffold Widget | Side nav (tablet/desktop) + Bottom nav (phone), role-based menu | 4.3.1 |
| 4.3.3 | ✅ สร้าง ResponsiveLayout Widget | LayoutBuilder — Phone/Tablet/Desktop breakpoints | 0.2.3 |
| 4.3.4 | ✅ สร้าง Side Navigation | Expandable nav rail ตาม wireframe — menu items, sync status, shift status | 4.3.2 |
| 4.3.5 | ✅ สร้าง Bottom Navigation (Phone) | 5 tabs with "More" menu for overflow items | 4.3.2 |
| 4.3.6 | ✅ สร้าง App Bar | Title, notifications badge, user info, settings shortcut | 4.3.2 |

### 4.4 Shared Widgets
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 4.4.1 | ✅ สร้าง PrimaryButton + SecondaryButton + DangerButton | Styled buttons ตาม design system | 4.1.4 |
| 4.4.2 | ✅ สร้าง LoadingIndicator | Centered spinner, overlay option | 0.2.3 |
| 4.4.3 | ✅ สร้าง EmptyState Widget | Icon + message + action button | 0.2.3 |
| 4.4.4 | ✅ สร้าง ErrorWidget | ข้อผิดพลาด + retry button | 0.2.3 |
| 4.4.5 | ✅ สร้าง ConfirmDialog | Title + message + confirm/cancel buttons | 0.2.3 |
| 4.4.6 | ✅ สร้าง PinDialog | PIN input popup for permission verification | 0.2.3 |
| 4.4.7 | ✅ สร้าง NumpadWidget (Shared) | 0-9, C, backspace, decimal — reusable numpad | 0.2.3 |
| 4.4.8 | ✅ สร้าง CurrencyText Widget | Format ราคาตามสกุลเงิน (THB 2dp, LAK 0dp, USD 2dp) | 0.2.3 |
| 4.4.9 | ✅ สร้าง SearchField Widget | Search input + barcode scan icon | 0.2.3 |
| 4.4.10 | ✅ สร้าง LanguageSwitcher Widget | TH/EN/LO toggle buttons | 4.2.5 |
| 4.4.11 | ✅ สร้าง Skeleton Loading Widget | Shimmer effect สำหรับ loading state | 0.2.3 |
| 4.4.12 | ✅ สร้าง Offline Banner Widget | แถบเตือน "ออฟไลน์ — ข้อมูลจะ sync เมื่อกลับมาออนไลน์" | 0.2.3 |

### 4.5 Core Services
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 4.5.1 | ✅ สร้าง Dependency Injection (get_it) | `injection.dart` — register all singletons, factories | 0.2.2 |
| 4.5.2 | ✅ สร้าง ConnectivityService | Stream online/offline status, monitor network | 0.2.2 |
| 4.5.3 | ✅ สร้าง ConnectivityBloc | Global state for connection status | 4.5.2 |
| 4.5.4 | ✅ สร้าง SoundPlayer Util | Play new_order, kitchen_ready, notification sounds, mute toggle | 0.2.2 |
| 4.5.5 | ✅ สร้าง Validators Util | Phone, email, required, numeric, price validation | 0.2.3 |

---

## Phase 5: Products & Categories

> CRUD สินค้า, หมวดหมู่, Variants, Modifiers, Barcode

### 5.1 Backend — Categories
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 5.1.1 | ✅ สร้าง Categories Module | Module, Controller, Service | 1.1.4 |
| 5.1.2 | ✅ Implement Categories CRUD | `POST/GET/PATCH/DELETE /categories` — 2-level, sort_order, JSONB name | 5.1.1 |
| 5.1.3 | ✅ Implement Category Reorder | `PATCH /categories/reorder` — batch update sort_order | 5.1.1 |

### 5.2 Backend — Products
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 5.2.1 | ✅ สร้าง Products Module | Module, Controller, Service | 1.1.5 |
| 5.2.2 | ✅ Implement Products CRUD | `POST/GET/PATCH/DELETE /products` — all fields, pagination, filter by category/status/search | 5.2.1 |
| 5.2.3 | ✅ Implement Product Variants CRUD | `POST/GET/PATCH/DELETE /products/:id/variants` | 5.2.1 |
| 5.2.4 | ✅ Implement Modifier Groups CRUD | `POST/GET/PATCH/DELETE /modifier-groups` + options | 1.1.6 |
| 5.2.5 | ✅ Implement Product ↔ Modifier Group Link | `POST/DELETE /products/:id/modifier-groups/:groupId` | 5.2.2, 5.2.4 |
| 5.2.6 | ✅ Implement Barcode Lookup | `GET /products/barcode/:code` — ค้นหาสินค้าจาก barcode | 5.2.2 |
| 5.2.7 | ✅ Implement Unit Conversions CRUD | `POST/GET/DELETE /products/:id/unit-conversions` | 1.1.7 |
| 5.2.8 | ✅ Implement Image Upload | Upload product image → storage (local/S3) → return URL | 5.2.1 |

### 5.3 Flutter — Products Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 5.3.1 | ✅ สร้าง Product/Category Data Models | Product, ProductVariant, ModifierGroup, ModifierOption, Category (freezed) | 0.2.5 |
| 5.3.2 | ✅ สร้าง Products Remote DataSource | API calls: CRUD products, variants, modifiers, barcode lookup | 5.3.1 |
| 5.3.3 | ✅ สร้าง Products Local DataSource | SQLite cache: products, categories, modifiers | 5.3.1 |
| 5.3.4 | ✅ สร้าง Products Repository | Online → API; Offline → SQLite cache, connectivity-aware | 5.3.2, 5.3.3 |
| 5.3.5 | ✅ สร้าง Product List Screen | ตาม wireframe — list view, search, filter by category, pagination | 5.3.4 |
| 5.3.6 | ✅ สร้าง Product Form Screen | ตาม wireframe — all fields, image upload, i18n name inputs (TH/EN/LO) | 5.3.4 |
| 5.3.7 | ✅ สร้าง Variant Management (ใน Product Form) | CRUD variants (S/M/L), price per variant, SKU per variant | 5.3.6 |
| 5.3.8 | ✅ สร้าง Modifier Group Management Screen | CRUD modifier groups + options, link to products | 5.3.4 |
| 5.3.9 | ✅ สร้าง Category Management Screen | CRUD categories (2-level), drag reorder, color/image | 5.3.4 |

---

## Phase 6: POS Core — Cart & Order

> ★ หน้าขายหลัก — เลือกสินค้า, ตะกร้า, สร้าง Order

### 6.1 Backend — Orders
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 6.1.1 | ✅ สร้าง Orders Module | Module, Controller, Service, OrderCalculationService | 1.1.9, 1.1.10 |
| 6.1.2 | ✅ Implement `POST /orders` | สร้าง order (draft/open), assign table, generate order_number | 6.1.1 |
| 6.1.3 | ✅ Implement `GET /orders` | List orders: filter status, date range, pagination | 6.1.1 |
| 6.1.4 | ✅ Implement `GET /orders/:id` | Order detail + items + modifiers + payments | 6.1.1 |
| 6.1.5 | ✅ Implement `POST /orders/:id/items` | เพิ่มรายการ: product_id, variant_id, quantity, modifiers[], note | 6.1.1 |
| 6.1.6 | ✅ Implement `PATCH /orders/:id/items/:itemId` | แก้ไขรายการ: quantity, note, price (open price) | 6.1.1 |
| 6.1.7 | ✅ Implement `DELETE /orders/:id/items/:itemId` | ลบรายการ (ถ้ายังไม่ส่งครัว) | 6.1.1 |
| 6.1.8 | ✅ Implement OrderCalculationService | คำนวณ subtotal, discount, tax (per-item + order-level), service charge, rounding, total | 6.1.1 |
| 6.1.9 | ✅ Implement `PATCH /orders/:id/discount` | Apply ส่วนลดทั้งบิล (percent/amount/coupon) | 6.1.1 |
| 6.1.10 | ✅ Implement `POST /orders/:id/hold` | พักบิล (status → held) | 6.1.1 |
| 6.1.11 | ✅ Implement `POST /orders/:id/resume` | เรียกบิลกลับมา (held → open) | 6.1.1 |
| 6.1.12 | ✅ Implement `POST /orders/:id/void` | Void order — ต้อง PIN ยืนยัน (Manager/Owner), บันทึก reason | 6.1.1 |
| 6.1.13 | ✅ Implement `POST /orders/:id/void-item` | Void individual item — PIN + reason | 6.1.1 |
| 6.1.14 | ✅ Implement `POST /orders/:id/send-to-kitchen` | ส่งรายการเข้าครัว: สร้าง kitchen_orders, update item status, trigger WebSocket | 6.1.1, 1.1.17 |
| 6.1.15 | ✅ Implement Receipt Number Generator | Running number per tenant, reset logic, prefix format | 1.2.5 |

### 6.2 Flutter — POS Main Screen
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 6.2.1 | ✅ สร้าง POS Screen Layout (Tablet) | Split view: Category sidebar + Product grid (60%) + Cart panel (40%) | 4.3.3 |
| 6.2.2 | ✅ สร้าง POS Screen Layout (Phone) | Products full screen + Cart bottom bar + Bottom sheet | 6.2.1 |
| 6.2.3 | ✅ สร้าง CategoryBar Widget | Horizontal/Vertical scrollable category tabs, "ทั้งหมด" tab | 5.3.1 |
| 6.2.4 | ✅ สร้าง ProductGrid Widget | Grid view with ProductCard — image, name, price | 5.3.1 |
| 6.2.5 | ✅ สร้าง ProductListView Widget | List view with ProductRow — compact, quick add | 5.3.1 |
| 6.2.6 | ✅ สร้าง Grid/List Toggle | Switch between grid and list view, persist preference | 6.2.4, 6.2.5 |
| 6.2.7 | ✅ สร้าง QuickKeysBar Widget | ปุ่มลัดสินค้า quick access ด้านล่าง categories | 5.3.1 |
| 6.2.8 | ✅ สร้าง Product Search (POS) | ค้นหาชื่อ + SKU + barcode, instant results | 5.3.4 |
| 6.2.9 | ✅ สร้าง CartBloc | State: items[], totals, discount, member; Events: AddItem, RemoveItem, UpdateQty, ApplyDiscount, Clear | - |
| 6.2.10 | ✅ สร้าง CartPanel Widget (Tablet) | รายการในตะกร้า, qty +/-, swipe delete, subtotals, totals | 6.2.9 |
| 6.2.11 | ✅ สร้าง CartBottomSheet (Phone) | Bottom sheet version of cart panel | 6.2.9 |
| 6.2.12 | ✅ สร้าง CartItemCard Widget | ชื่อ + variant + modifiers + note + qty + price, tap to edit | 6.2.9 |
| 6.2.13 | ✅ สร้าง ModifierDialog | ตาม wireframe — variant selector, modifier checkboxes, note input, qty selector | 5.3.1 |
| 6.2.14 | ✅ สร้าง NoteDialog | Free text note input for item or order | 4.4.5 |
| 6.2.15 | ✅ สร้าง DiscountDialog | Percent / fixed amount / coupon code input | 4.4.7 |
| 6.2.16 | ✅ สร้าง VoidReasonDialog | เหตุผลที่ Void + PIN confirmation | 4.4.5, 4.4.6 |
| 6.2.17 | ✅ สร้าง Order Type Selector | Dine-in / Takeaway toggle (ด้านบน cart) | 6.2.10 |
| 6.2.18 | ✅ สร้าง OrderBloc | Create order, add items, hold, resume, void, link to API | 6.2.9 |
| 6.2.19 | ✅ Implement Open Price Feature | กรอกราคาตอนเพิ่มสินค้า (สำหรับ product type = open_price) | 6.2.13 |
| 6.2.20 | ✅ สร้าง Add-to-cart Animation | Scale bounce + fly-to-cart-icon animation | 6.2.4 |

---

## Phase 7: Checkout & Payment

> ชำระเงิน, Multi-currency, Split Bill, เงินทอน, ใบเสร็จ

### 7.1 Backend — Payments
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 7.1.1 | ✅ สร้าง Payments Module | Module, Controller, Service, ExchangeRateService | 1.1.11 |
| 7.1.2 | ✅ Implement `POST /orders/:id/payments` | สร้าง payment record (cash/qr/transfer), exchange rate conversion | 7.1.1 |
| 7.1.3 | ✅ Implement `POST /orders/:id/complete` | ปิดบิล: validate payments ≥ total, update order status, deduct stock, update member totals | 7.1.2 |
| 7.1.4 | ✅ Implement Split Bill Logic | หลาย payment records ต่อ 1 order, mixed currency/method | 7.1.2 |
| 7.1.5 | ✅ Implement Cash Change Calculation | รับเงิน - total = เงินทอน (per currency) | 7.1.2 |
| 7.1.6 | ✅ Implement Exchange Rate Service | Cache rates in Redis, manual update from settings | 7.1.1 |
| 7.1.7 | ✅ Implement Refund | `POST /orders/:id/refund` — full/partial refund, สร้าง refund order | 7.1.1 |

### 7.2 Flutter — Checkout Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 7.2.1 | ✅ สร้าง Checkout Screen Layout | ตาม wireframe — payment selector (left) + summary (right, tablet), full screen (phone) | 6.2.18 |
| 7.2.2 | ✅ สร้าง PaymentMethodSelector Widget | เงินสด / QR PromptPay / โอน — visual cards | 7.2.1 |
| 7.2.3 | ✅ สร้าง CashInput Widget | Numpad + quick buttons (฿100, ฿500, ฿1000, พอดี) | 4.4.7 |
| 7.2.4 | ✅ สร้าง MultiCurrencyInput Widget | เลือก currency THB/LAK/USD + amount input + show converted amount | 7.2.1 |
| 7.2.5 | ✅ สร้าง SplitBillPanel Widget | + เพิ่มการชำระ, แสดง list of payments, remaining balance | 7.2.1 |
| 7.2.6 | ✅ สร้าง ChangeDisplay Widget | แสดงเงินทอน (ตัวเลขใหญ่, สีเขียว) | 7.2.3 |
| 7.2.7 | ✅ สร้าง PaymentCompleteDialog | ตาม wireframe — ✅ animation, print receipt, new order buttons | 7.2.1 |
| 7.2.8 | ✅ สร้าง CheckoutBloc | Process payment, validate, complete order, trigger print | 7.2.1 |
| 7.2.9 | ✅ สร้าง Receipt Preview (Optional) | แสดง preview ใบเสร็จก่อนพิมพ์ | 7.2.7 |

---

## Phase 8: Tables & Floor Plan (Restaurant)

> จัดการโต๊ะ, โซน, Merge/Split/Move, Real-time status

### 8.1 Backend — Tables & Zones
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 8.1.1 | ✅ สร้าง Tables Module | Module, Controller, Service | 1.1.8 |
| 8.1.2 | ✅ Implement Zones CRUD | `POST/GET/PATCH/DELETE /zones` | 8.1.1 |
| 8.1.3 | ✅ Implement Tables CRUD | `POST/GET/PATCH/DELETE /tables` — zone_id, seats, status, QR code | 8.1.1 |
| 8.1.4 | ✅ Implement Table Status Update | `PATCH /tables/:id/status` — available/occupied/reserved | 8.1.1 |
| 8.1.5 | ✅ Implement Move Table | `POST /tables/:id/move` — ย้าย order ไปโต๊ะใหม่ | 8.1.3, 6.1.1 |
| 8.1.6 | ✅ Implement Merge Tables | `POST /tables/merge` — รวม orders จากหลายโต๊ะ | 8.1.3, 6.1.1 |
| 8.1.7 | ✅ Implement Split Table | `POST /tables/:id/split` — แยกรายการบางส่วนไปโต๊ะใหม่ | 8.1.3, 6.1.1 |
| 8.1.8 | ✅ Implement Table QR Code Generation | Generate QR code URL per table | 8.1.3 |

### 8.2 Flutter — Tables Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 8.2.1 | ✅ สร้าง Table/Zone Data Models | Zone, Table, TableStatus (freezed) | 0.2.5 |
| 8.2.2 | ✅ สร้าง Tables Repository | Remote + Local cache | 8.2.1 |
| 8.2.3 | ✅ สร้าง Floor Plan Screen | ตาม wireframe — zone tabs, table grid, color-coded status | 8.2.2 |
| 8.2.4 | ✅ สร้าง TableCard Widget | Table name, seats, status color, order amount, elapsed time | 8.2.3 |
| 8.2.5 | ✅ สร้าง TableActionSheet | Long press menu: ดูออเดอร์, ไปขาย, ย้าย, รวม, แยก, ชำระ | 8.2.3 |
| 8.2.6 | ✅ Implement Table → POS Flow | กดโต๊ะว่าง → สร้าง order → เปิด POS, กดโต๊ะ occupied → เปิด order เดิม | 8.2.3, 6.2.18 |
| 8.2.7 | ✅ Implement Move Table UI | Dialog เลือกโต๊ะปลายทาง | 8.2.5 |
| 8.2.8 | ✅ Implement Merge Tables UI | เลือกโต๊ะที่จะรวม (multi-select) | 8.2.5 |
| 8.2.9 | ✅ Implement Split Table UI | เลือกรายการที่จะแยกออก → เลือกโต๊ะใหม่ | 8.2.5 |
| 8.2.10 | ✅ สร้าง Zone Management (Settings) | CRUD zones (ชั้น 1, ระเบียง, VIP) | 8.2.2 |

---

## Phase 9: Kitchen Display System (KDS)

> หน้าจอครัว, Real-time order updates, Timer, Status flow

### 9.1 Backend — Kitchen
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 9.1.1 | ✅ สร้าง Kitchen Module | Module, Controller, Service, Gateway (WebSocket) | 1.1.17 |
| 9.1.2 | ✅ Implement `GET /kitchen/orders` | List kitchen orders: filter by status, include item details | 9.1.1 |
| 9.1.3 | ✅ Implement `PATCH /kitchen/orders/:id/accept` | new → preparing | 9.1.1 |
| 9.1.4 | ✅ Implement `PATCH /kitchen/orders/:id/ready` | preparing → ready | 9.1.1 |
| 9.1.5 | ✅ Implement `PATCH /kitchen/orders/:id/served` | ready → served | 9.1.1 |
| 9.1.6 | ✅ สร้าง Kitchen WebSocket Gateway | Emit events: `kitchen:new-order`, `kitchen:status-changed` | 9.1.1 |

### 9.2 Flutter — KDS Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 9.2.1 | ✅ สร้าง Kitchen Data Models | KitchenOrder, KitchenStatus (freezed) | 0.2.5 |
| 9.2.2 | ✅ สร้าง KDS Screen Layout | ตาม wireframe — column/Kanban view (New → Preparing → Ready) | 9.2.1 |
| 9.2.3 | ✅ สร้าง KitchenOrderCard Widget | บิล, โต๊ะ, items, modifiers, note, timer | 9.2.2 |
| 9.2.4 | ✅ สร้าง KitchenTimer Widget | ⏱ elapsed time, color coding (green→yellow→red), blink when > 10min | 9.2.3 |
| 9.2.5 | ✅ Implement KDS Status Buttons | Accept → Ready → Served (tap to progress) | 9.2.3 |
| 9.2.6 | ✅ Implement KDS WebSocket Listener | Real-time new order notification + auto-refresh | 9.2.2 |
| 9.2.7 | ✅ Implement KDS Sound Alert | 🔔 sound on new order arrival | 9.2.6, 4.5.4 |
| 9.2.8 | ✅ Implement KDS Responsive Layout | Phone: 1 col, Tablet: 2 col, Desktop: 3-4 col Kanban | 9.2.2 |

---

## Phase 10: Shifts & Cash Management

> เปิด/ปิดกะ, นับเงินเปิด/ปิด, สรุปกะ

### 10.1 Backend — Shifts
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 10.1.1 | ✅ สร้าง Shifts Module | Module, Controller, Service | 1.1.14 |
| 10.1.2 | ✅ Implement `POST /shifts/open` | สร้าง shift ใหม่: opening_cash, opened_by | 10.1.1 |
| 10.1.3 | ✅ Implement `POST /shifts/close` | ปิด shift: closing_cash, คำนวณ expected, difference, summary per method | 10.1.1 |
| 10.1.4 | ✅ Implement `GET /shifts/current` | ดึง shift ที่เปิดอยู่ | 10.1.1 |
| 10.1.5 | ✅ Implement `GET /shifts` | List shift history: filter by date, user | 10.1.1 |
| 10.1.6 | ✅ Implement `GET /shifts/:id` | Shift detail + sales summary, order count, voids count | 10.1.1 |

### 10.2 Flutter — Shifts Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 10.2.1 | ✅ สร้าง Shift Data Models | Shift, ShiftStatus (freezed) | 0.2.5 |
| 10.2.2 | ✅ สร้าง ShiftBloc | Global: track current shift, open/close events | 10.2.1 |
| 10.2.3 | ✅ สร้าง Open Shift Screen | ใส่ยอดเงินเปิดกะ (numpad), button เปิดกะ | 10.2.2 |
| 10.2.4 | ✅ สร้าง Close Shift Screen | ใส่ยอดนับเงิน, แสดง expected vs actual, difference, สรุปยอดขาย | 10.2.2 |
| 10.2.5 | ✅ Implement Shift Check on App Start | ถ้ายังไม่เปิดกะ → redirect ไป Open Shift Screen | 10.2.2, 2.2.9 |
| 10.2.6 | ✅ สร้าง Shift History Screen | List shifts, tap for detail/summary | 10.2.2 |

---

## Phase 11: Inventory & Stock

> สต็อกสินค้า, ปรับสต็อก, แจ้งเตือนสต็อกต่ำ

### 11.1 Backend — Stock
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 11.1.1 | ✅ สร้าง Stock Module | Module, Controller, Service | 1.1.12 |
| 11.1.2 | ✅ Implement `GET /stock` | List stock overview: product + quantity + status (normal/low/out) | 11.1.1 |
| 11.1.3 | ✅ Implement `POST /stock/adjust` | Batch adjust: type (purchase/adjustment/damage/initial), note, performed_by | 11.1.1 |
| 11.1.4 | ✅ Implement `GET /stock/movements` | Movement history: filter by product, type, date range | 11.1.1 |
| 11.1.5 | ✅ Implement Auto Stock Deduction | After order complete: deduct stock for each item (track_stock=true) | 11.1.1, 7.1.3 |
| 11.1.6 | ✅ Implement Low Stock Alert Job | Background job: check after sale, create notification | 11.1.1 |

### 11.2 Flutter — Inventory Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 11.2.1 | ✅ สร้าง Stock Data Models | StockItem, StockMovement (freezed) | 0.2.5 |
| 11.2.2 | ✅ สร้าง Stock Overview Screen | ตาม wireframe — list: product, qty, unit, status, value | 11.2.1 |
| 11.2.3 | ✅ สร้าง Stock Filter Tabs | ทั้งหมด / ใกล้หมด / หมด | 11.2.2 |
| 11.2.4 | ✅ สร้าง Stock Adjustment Dialog | ตาม wireframe — type, scan/search product, qty, note | 11.2.2 |
| 11.2.5 | ✅ สร้าง Stock Movement History Screen | List movements with pagination | 11.2.1 |

---

## Phase 12: Members & Customers

> สมาชิก, ค้นหา, ยอดรวม, ผูกกับ Order

### 12.1 Backend — Members
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 12.1.1 | ✅ สร้าง Members Module | Module, Controller, Service | 1.1.13 |
| 12.1.2 | ✅ Implement Members CRUD | `POST/GET/PATCH/DELETE /members` — search by name/phone | 12.1.1 |
| 12.1.3 | ✅ Implement `GET /members/:id/orders` | ประวัติออเดอร์ของสมาชิก | 12.1.1, 6.1.1 |
| 12.1.4 | ✅ Implement Member Stats Update | After order complete: increment total_spent, total_visits | 12.1.1, 7.1.3 |

### 12.2 Flutter — Members Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 12.2.1 | ✅ สร้าง Member Data Models | Member (freezed) | 0.2.5 |
| 12.2.2 | ✅ สร้าง Member List Screen | ตาม wireframe — search, list with summary stats | 12.2.1 |
| 12.2.3 | ✅ สร้าง Member Form (Create/Edit) | ชื่อ, เบอร์, email, note | 12.2.2 |
| 12.2.4 | ✅ สร้าง Member Detail Screen | ข้อมูล + ยอดรวม + ประวัติออเดอร์ | 12.2.2 |
| 12.2.5 | ✅ สร้าง Member Lookup (POS) | ค้นหาสมาชิกจากหน้า POS → ผูกกับ order | 12.2.1, 6.2.18 |

---

## Phase 13: Coupons & Promotions

> คูปอง, โค้ดส่วนลด, Buy-X-Get-Y

### 13.1 Backend — Coupons
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 13.1.1 | ✅ สร้าง Coupons Module | Module, Controller, Service | 1.1.15 |
| 13.1.2 | ✅ Implement Coupons CRUD | `POST/GET/PATCH/DELETE /coupons` — code, type, value, limits, validity | 13.1.1 |
| 13.1.3 | ✅ Implement `POST /coupons/validate` | Validate code: check active, expired, max_uses, min_order | 13.1.1 |
| 13.1.4 | ✅ Implement Coupon Apply on Order | Increment used_count after order complete | 13.1.1, 7.1.3 |

### 13.2 Flutter — Coupons Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 13.2.1 | ✅ สร้าง Coupon Data Models | Coupon, CouponType (freezed) | 0.2.5 |
| 13.2.2 | ✅ สร้าง Coupon List Screen | List coupons, active/expired filter | 13.2.1 |
| 13.2.3 | ✅ สร้าง Coupon Form Screen | Create/edit coupon: type, value, limits, dates | 13.2.2 |
| 13.2.4 | ✅ Implement Coupon Apply in Discount Dialog | Scan/type code → validate → show discount | 6.2.15 |

---

## Phase 14: Queue Management

> ระบบคิว, ออกเลขคิว, เรียกคิว, จัดโต๊ะ

### 14.1 Backend — Queue
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 14.1.1 | ✅ สร้าง Queue Module | Module, Controller, Service | 1.1.16 |
| 14.1.2 | ✅ Implement `POST /queue` | ออกคิวใหม่: ticket_number, customer_name, party_size | 14.1.1 |
| 14.1.3 | ✅ Implement `GET /queue` | List queue: filter by status (waiting/called/completed) | 14.1.1 |
| 14.1.4 | ✅ Implement `PATCH /queue/:id/call` | เรียกคิว (waiting → called) | 14.1.1 |
| 14.1.5 | ✅ Implement `PATCH /queue/:id/seat` | จัดโต๊ะ (called → serving), link order_id + table | 14.1.1 |
| 14.1.6 | ✅ Implement `PATCH /queue/:id/complete` | เสร็จสิ้น | 14.1.1 |
| 14.1.7 | ✅ Implement `PATCH /queue/:id/cancel` | ยกเลิกคิว | 14.1.1 |

### 14.2 Flutter — Queue Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 14.2.1 | ✅ สร้าง Queue Data Models | QueueTicket, QueueStatus (freezed) | 0.2.5 |
| 14.2.2 | ✅ สร้าง Queue Screen | ตาม wireframe — cards: waiting/called, buttons per card | 14.2.1 |
| 14.2.3 | ✅ สร้าง New Queue Dialog | ชื่อลูกค้า, จำนวนคน, note | 14.2.2 |
| 14.2.4 | ✅ Implement Queue → Table Flow | จัดโต๊ะจากคิว → เปิด floor plan → เลือกโต๊ะ → สร้าง order | 14.2.2, 8.2.6 |

---

## Phase 15: Reports & Dashboard

> Dashboard ภาพรวม, รายงานขาย, สินค้า, กำไร, Export

### 15.1 Backend — Reports
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 15.1.1 | ✅ สร้าง Reports Module | Module, Controller, Service, DashboardService | 7.1.3 |
| 15.1.2 | ✅ Implement `GET /dashboard/summary` | ยอดขายวันนี้, จำนวนออเดอร์, จำนวนลูกค้า, เฉลี่ย/บิล, % เทียบเมื่อวาน | 15.1.1 |
| 15.1.3 | ✅ Implement `GET /dashboard/hourly-sales` | ยอดขายรายชั่วโมง (สำหรับ chart) | 15.1.1 |
| 15.1.4 | ✅ Implement `GET /dashboard/top-products` | สินค้าขายดีวันนี้ (top 10) | 15.1.1 |
| 15.1.5 | ✅ Implement `GET /dashboard/sales-by-method` | ยอดขายแยกวิธีชำระ (cash/qr/transfer) | 15.1.1 |
| 15.1.6 | ✅ Implement `GET /reports/sales` | รายงานขาย: filter date range, group by day/week/month, breakdown | 15.1.1 |
| 15.1.7 | ✅ Implement `GET /reports/products` | รายงานสินค้า: qty sold, revenue, ranking | 15.1.1 |
| 15.1.8 | ✅ Implement `GET /reports/categories` | รายงานหมวดหมู่: revenue per category | 15.1.1 |
| 15.1.9 | ✅ Implement `GET /reports/payment-methods` | รายงานวิธีชำระ: breakdown | 15.1.1 |
| 15.1.10 | ✅ Implement Report Export | Generate Excel/CSV, return download URL | 15.1.6 |

### 15.2 Flutter — Reports Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 15.2.1 | ✅ สร้าง Report Data Models | DashboardSummary, SalesReport, ProductReport (freezed) | 0.2.5 |
| 15.2.2 | ✅ สร้าง Dashboard Screen | ตาม wireframe — 4 KPI cards, hourly chart, top products, payment methods | 15.2.1 |
| 15.2.3 | ✅ สร้าง KPI Card Widget | Icon + label + value + %change (green/red) | 15.2.2 |
| 15.2.4 | ✅ สร้าง Hourly Sales Chart | Bar chart ยอดขายรายชั่วโมง (fl_chart package) | 15.2.2 |
| 15.2.5 | ✅ สร้าง Date Range Picker | วันนี้ / เมื่อวาน / สัปดาห์นี้ / เดือนนี้ / custom range | 15.2.2 |
| 15.2.6 | ✅ สร้าง Sales Report Screen | ตาราง + chart, group by day/week/month, filter | 15.2.1 |
| 15.2.7 | ✅ สร้าง Product Report Screen | Top products, category breakdown | 15.2.1 |
| 15.2.8 | ✅ Implement Export (Download) | ดาวน์โหลด Excel/CSV, share | 15.2.6 |

### 15.3 Orders History Feature
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 15.3.1 | ✅ สร้าง Order List Screen | ตาม wireframe — filter tabs (ทั้งหมด/เปิด/เสร็จ/พัก/ยกเลิก/คืนเงิน), search, date filter | 6.1.3 |
| 15.3.2 | ✅ สร้าง OrderCard Widget | Order number, status badge, type, items count, total, time | 15.3.1 |
| 15.3.3 | ✅ สร้าง Order Detail Screen | Full order view: items, modifiers, notes, payments, timeline, reprint | 6.1.4 |
| 15.3.4 | ✅ Implement Order Reprint | Print receipt from order detail | 15.3.3 |
| 15.3.5 | ✅ Implement Refund from Order Detail | เลือกรายการ → full/partial refund → confirm | 15.3.3, 7.1.7 |

---

## Phase 16: Offline & Sync Engine

> Offline-first, SQLite, Sync Queue, Conflict Resolution

### 16.1 Backend — Sync
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 16.1.1 | ✅ สร้าง Sync Module | Module, Controller, Service, ConflictResolverService | 1.1.19 |
| 16.1.2 | ✅ Implement `POST /sync/push` | รับ batch records จาก client sync queue, process, resolve conflicts | 16.1.1 |
| 16.1.3 | ✅ Implement `GET /sync/pull` | คืนข้อมูลที่เปลี่ยนแปลงตั้งแต่ `since` timestamp (products, categories, members, settings) | 16.1.1 |
| 16.1.4 | ✅ Implement Conflict Resolution | Last-write-wins, order_number reassignment, stock recalculation | 16.1.2 |

### 16.2 Flutter — Offline & Sync
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 16.2.1 | ✅ สร้าง Local Database (drift/sqflite) | `app_database.dart` — all local tables mirroring server | 0.2.5 |
| 16.2.2 | ✅ สร้าง Local Product Cache DAO | CRUD local_products, local_categories — read from cache when offline | 16.2.1 |
| 16.2.3 | ✅ สร้าง Local Order DAO | Create/update orders offline, local_orders, local_order_items | 16.2.1 |
| 16.2.4 | ✅ สร้าง Local Payment DAO | Create payments offline | 16.2.1 |
| 16.2.5 | ✅ สร้าง Local Shift DAO | Open/close shift offline | 16.2.1 |
| 16.2.6 | ✅ สร้าง Sync Queue Manager | Insert pending sync records, manage status (pending/syncing/completed/failed) | 16.2.1 |
| 16.2.7 | ✅ สร้าง SyncEngine Service | Auto sync every 30s when online, batch push (50 records), pull changes, retry logic (max 5 attempts) | 16.2.6, 4.5.2 |
| 16.2.8 | ✅ สร้าง SyncBloc | Global state: last_sync_time, pending_count, sync_status, errors | 16.2.7 |
| 16.2.9 | ✅ Implement Repository Offline Mode | ทุก repository: online → API, offline → SQLite + sync queue | 16.2.7 |
| 16.2.10 | ✅ สร้าง Sync Status Indicator | แสดง sync status ใน side nav: ● Online/Offline, pending count, last sync time | 16.2.8 |
| 16.2.11 | ✅ Implement Initial Data Sync | ตอน login สำเร็จ: pull all products, categories, members, settings → cache locally | 16.2.7 |

---

## Phase 17: Hardware, Notification, Import/Export, QR Menu, Admin

> Features เสริมที่เหลือทั้งหมด

### 17.1 Printing Service
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 17.1.1 | ✅ สร้าง PrintService (Flutter) | Abstract class → BT, USB, WiFi, Browser Print implementations | 0.2.2 |
| 17.1.2 | ✅ Implement Bluetooth Printer | ESC/POS via flutter_blue_plus, discovery, connect, print | 17.1.1 |
| 17.1.3 | ✅ Implement USB Printer | ESC/POS via usb_serial (Android) | 17.1.1 |
| 17.1.4 | ✅ Implement WiFi/Network Printer | ESC/POS via socket (IP:port) | 17.1.1 |
| 17.1.5 | ✅ Implement Browser Print (Web) | HTML receipt → window.print() via printing package | 17.1.1 |
| 17.1.6 | ✅ สร้าง ReceiptBuilder | สร้างข้อมูลใบเสร็จ: header, items, totals, footer, QR — 58mm/80mm | 17.1.1 |
| 17.1.7 | ✅ สร้าง Kitchen Ticket Builder | สร้าง Kitchen ticket: โต๊ะ, items, modifiers, notes, timestamp | 17.1.6 |
| 17.1.8 | ✅ Implement Auto-print on Complete | เมื่อชำระเงินสำเร็จ → print receipt อัตโนมัติ | 17.1.6, 7.2.7 |
| 17.1.9 | ✅ Implement Kitchen Print on Send | เมื่อส่งออเดอร์เข้าครัว → print kitchen ticket | 17.1.7, 6.1.14 |

### 17.2 Barcode Scanner
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 17.2.1 | ✅ สร้าง BarcodeService (Flutter) | Abstract: Camera scan + USB/BT hardware scanner | 0.2.2 |
| 17.2.2 | ✅ Implement Camera Barcode Scanner | mobile_scanner or barcode_scan package | 17.2.1 |
| 17.2.3 | ✅ Implement USB/BT Hardware Scanner | Listen keyboard input (HID mode) | 17.2.1 |
| 17.2.4 | ✅ Integrate Barcode Scan in POS | Scan → lookup product → add to cart | 17.2.2, 6.2.8 |
| 17.2.5 | ✅ Integrate Barcode Scan in Product Form | Scan → fill barcode field | 17.2.2, 5.3.6 |

### 17.3 Cash Drawer
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 17.3.1 | ✅ สร้าง CashDrawerService | Open command via printer ESC/POS kick command | 17.1.1 |
| 17.3.2 | ✅ Implement Auto-open on Cash Payment | เมื่อชำระเงินสดสำเร็จ → เปิดลิ้นชัก | 17.3.1, 7.2.7 |

### 17.4 Customer Display (Dual Screen)
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 17.4.1 | ✅ สร้าง CustomerDisplay Screen | ตาม wireframe — logo, items, totals, ขอบคุณ (read-only display) | 4.1.4 |
| 17.4.2 | ✅ Implement Dual Screen Output | presentation_displays (Android) — output customer display on 2nd screen | 17.4.1 |

### 17.5 WebSocket (Real-time)
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 17.5.1 | ✅ สร้าง WebSocket Gateway (Backend) | Socket.IO server — auth, room management (per tenant) | 2.1.8 |
| 17.5.2 | ✅ Implement Orders Channel | Broadcast order events: created, updated, completed, voided | 17.5.1, 6.1.1 |
| 17.5.3 | ✅ Implement Kitchen Channel | Broadcast kitchen events: new-order, status-changed | 17.5.1, 9.1.6 |
| 17.5.4 | ✅ Implement Tables Channel | Broadcast table status changes (available→occupied) | 17.5.1, 8.1.4 |
| 17.5.5 | ✅ Implement Queue Channel | Broadcast queue events: new, called | 17.5.1, 14.1.1 |
| 17.5.6 | ✅ Implement Notification Channel | Push notification events in real-time | 17.5.1 |
| 17.5.7 | ✅ สร้าง WebSocketClient (Flutter) | Socket.IO client — connect, reconnect, subscribe to channels | 0.2.2 |
| 17.5.8 | ✅ Implement WebSocket Listener in BLoCs | Listen events → update local state (orders, kitchen, tables, queue) | 17.5.7 |

### 17.6 Notifications
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 17.6.1 | ✅ สร้าง Notifications Module (Backend) | Module, Controller, Service, PushService (FCM/APNs) | 1.1.20 |
| 17.6.2 | ✅ Implement `GET /notifications` | List notifications: unread count, pagination | 17.6.1 |
| 17.6.3 | ✅ Implement `PATCH /notifications/:id/read` | Mark as read | 17.6.1 |
| 17.6.4 | ✅ Implement `PATCH /notifications/read-all` | Mark all as read | 17.6.1 |
| 17.6.5 | ✅ Implement Push Notification Service | FCM for Android, APNs for iOS | 17.6.1 |
| 17.6.6 | ✅ สร้าง Notification List Screen (Flutter) | List with unread indicator, badge on app bar | 17.6.1 |
| 17.6.7 | ✅ สร้าง NotificationBloc | Listen WebSocket + poll, unread count badge | 17.6.6 |
| 17.6.8 | ✅ Implement Local Notifications (Flutter) | flutter_local_notifications — for offline alerts | 17.6.6 |

### 17.7 Import / Export
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 17.7.1 | ✅ สร้าง Import/Export Module (Backend) | Module, Controller, Service | 5.2.1 |
| 17.7.2 | ✅ Implement Product CSV Import | Upload CSV → validate → bulk insert products | 17.7.1 |
| 17.7.3 | ✅ Implement Product CSV Export | Export all products to CSV download | 17.7.1 |
| 17.7.4 | ✅ สร้าง CSV Template | Sample CSV template for product import — GET /import-export/template/products | 17.7.1 |
| 17.7.5 | ✅ สร้าง Import Screen (Flutter) | Upload CSV, preview, confirm, progress bar | 17.7.2 |
| 17.7.6 | ✅ สร้าง Export Screen (Flutter) | Choose data type, format (CSV/Excel), download/share | 17.7.3 |

### 17.8 QR Menu (Public — No Auth)
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 17.8.1 | ✅ สร้าง Public Module (Backend) | Module, Controller, Service — no JWT required | 5.2.1 |
| 17.8.2 | ✅ Implement `GET /public/:tenantSlug/menu` | Public menu: categories + products (active only) | 17.8.1 |
| 17.8.3 | ✅ Implement `POST /public/:tenantSlug/orders` | Customer สั่งอาหารจาก QR → สร้าง order (draft) | 17.8.1 |
| 17.8.4 | ✅ สร้าง QR Menu Screen (Flutter Web) | ตาม wireframe — responsive mobile view, categories, search, cart, ส่ง order | 17.8.2 |
| 17.8.5 | ✅ สร้าง QR Code Generator | Generate QR per table → URL: `https://menu.lumluay.com/{tenant}/{table}` | 8.1.8 |

### 17.9 Super Admin
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 17.9.1 | ✅ สร้าง Admin Module (Backend) | Module, Controllers, Service — super_admin role only | 1.1.21 |
| 17.9.2 | ✅ Implement `GET /admin/tenants` | List all tenants: search, filter active/expired | 17.9.1 |
| 17.9.3 | ✅ Implement `GET /admin/tenants/:id` | Tenant detail + subscription info | 17.9.1 |
| 17.9.4 | ✅ Implement `PATCH /admin/tenants/:id` | Update tenant (activate/deactivate/extend subscription) | 17.9.1 |
| 17.9.5 | ✅ Implement `GET /admin/dashboard` | Total tenants, active count, revenue, expiring soon | 17.9.1 |
| 17.9.6 | ✅ Implement Subscription Plans CRUD | `POST/GET/PATCH /admin/plans` | 17.9.1 |
| 17.9.7 | ✅ สร้าง Admin Dashboard Screen (Flutter) | ตาม wireframe — KPI cards, tenant list, expiring | 17.9.1 |
| 17.9.8 | ✅ สร้าง Tenant List Screen | Search, filter, tap for detail | 17.9.7 |
| 17.9.9 | ✅ สร้าง Plan Management Screen | CRUD subscription plans | 17.9.7 |

### 17.10 Audit Log
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 17.10.1 | ✅ Implement Audit Log Recording | AuditInterceptor บันทึก: action, entity, changes (before/after), user, timestamp | 2.1.12 |
| 17.10.2 | ✅ Implement `GET /audit-logs` | List audit logs: filter by action, entity, user, date | 17.10.1 |

### 17.11 Backup
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 17.11.1 | ✅ Implement Auto Backup Job (Backend) | BullMQ cron: pg_dump daily 03:00 → store compressed | 0.1.6 |
| 17.11.2 | ✅ Implement Manual Export (Flutter) | Export local data → JSON/SQLite backup file → share | 16.2.1 |
| 17.11.3 | ✅ สร้าง Backup Settings Screen | Auto backup toggle, schedule, last backup info, manual trigger | 17.11.1 |

---

## Phase 18: Testing, Polish & Deployment

> Test, Performance, Security hardening, Build, Deploy

### 18.1 Backend Testing
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 18.1.1 | ✅ Unit Tests: Auth Service | Login, PIN, JWT, refresh, role guard | Phase 2 |
| 18.1.2 | ✅ Unit Tests: Order Calculation Service | Subtotal, discount, tax, service charge, rounding | Phase 6 |
| 18.1.3 | ✅ Unit Tests: Payment Service | Multi-currency, split bill, change calculation | Phase 7 |
| 18.1.4 | ✅ Unit Tests: Stock Service | Deduction, adjustment, movement history | Phase 11 |
| 18.1.5 | ✅ Unit Tests: Sync Service | Push/pull, conflict resolution | Phase 16 |
| 18.1.6 | ✅ Integration Tests: Order Flow | Create → Add Items → Send Kitchen → Pay → Complete (full E2E) | Phase 7 |
| 18.1.7 | ✅ Integration Tests: Auth Flow | Login → Refresh → PIN → Logout | Phase 2 |
| 18.1.8 | ✅ Integration Tests: Table Operations | Move, Merge, Split | Phase 8 |
| 18.1.9 | ✅ E2E Tests: API endpoints | ทุก critical endpoint (auth, orders, payments) | Phase 7 |

### 18.2 Flutter Testing
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 18.2.1 | ✅ Unit Tests: BLoCs | AuthBloc, CartBloc, OrderBloc, ShiftBloc, SyncBloc | Phase 6 |
| 18.2.2 | ✅ Unit Tests: Repositories | Online/offline mode switching, caching behavior | Phase 16 |
| 18.2.3 | ✅ Unit Tests: Utils | CurrencyFormatter, ReceiptBuilder, Validators | Phase 4 |
| 18.2.4 | ✅ Widget Tests: POS Screen | Product grid, cart panel, add/remove items | Phase 6 |
| 18.2.5 | ✅ Widget Tests: Login/PIN | Form validation, PIN pad interaction | Phase 2 |
| 18.2.6 | ✅ Widget Tests: Checkout | Payment flow, split bill, change display | Phase 7 |
| 18.2.7 | ✅ Integration Tests: Full Sales Flow | Login → POS → Add items → Checkout → Print → New order | Phase 7 |
| 18.2.8 | ✅ Integration Tests: Offline Flow | Go offline → Create order → Pay → Go online → Verify sync | Phase 16 |

### 18.3 Security Hardening
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 18.3.1 | ✅ Implement Helmet (Backend) | Security headers (CSP, HSTS, X-Frame-Options) | 0.1.1 |
| 18.3.2 | ✅ Implement Input Sanitization | Prevent XSS, SQL injection (parameterized queries via ORM) | 1.2.2 |
| 18.3.3 | ✅ Implement Rate Limiting (per endpoint) | Auth: 5/min, API: 100/min, Export: 5/min | 1.2.7 |
| 18.3.4 | ✅ Implement RLS Verification | Test tenant isolation — user A ต้องเข้าถึง tenant B ไม่ได้ | 1.1.24 |
| 18.3.5 | ✅ Implement Token Rotation | Refresh token rotation, detect reuse → revoke all sessions | 2.1.5 |
| 18.3.6 | ✅ Implement SQLCipher (Local DB) | Encrypt SQLite database on device | 16.2.1 |
| 18.3.7 | 🔄 Security Audit | Review OWASP Top 10, fix findings (dependency audit completed, remediation in progress) | All |

### 18.4 Performance Optimization
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 18.4.1 | ✅ Implement Redis Caching (Backend) | Cache products, categories, settings, exchange rates | 0.1.6 |
| 18.4.2 | ⬜ Implement Database Query Optimization | EXPLAIN ANALYZE critical queries, add missing indexes | 1.1.23 |
| 18.4.3 | 🔄 Flutter Widget Optimization | const constructors, RepaintBoundary, lazy loading images (POS critical path optimized) | Phase 6 |
| 18.4.4 | ⬜ Flutter Build Optimization | Tree shaking, deferred loading, code splitting (web) | Phase 6 |
| 18.4.5 | ✅ Image Optimization | Compress uploaded images, WebP format, thumbnails | 5.2.8 |
| 18.4.6 | ✅ API Response Optimization | Select only needed fields, pagination tuning, gzip | All |

### 18.5 Polish & UX
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 18.5.1 | ⬜ Implement All Animations | ตาม Animation Catalog (04-ui-ux-flow.md) — 15 animations | Phase 6 |
| 18.5.2 | ✅ Implement Skeleton Loading | Shimmer effect ทุก loading state | 4.4.11 |
| 18.5.3 | ✅ Implement Empty States | ทุกหน้า list ที่ว่าง — icon + message + action | 4.4.3 |
| 18.5.4 | ✅ Implement Error States | ทุก error case — retry button | 4.4.4 |
| 18.5.5 | ✅ Implement Keyboard Shortcuts | F1-F12 + Ctrl+N/P + Esc + Delete + +/- (ตาม 04-ui-ux-flow.md) | Phase 6 |
| 18.5.6 | ✅ Implement Haptic Feedback | ปุ่ม PIN, เพิ่มสินค้า, ชำระเงิน | Phase 6 |
| 18.5.7 | 🔄 Accessibility Pass | Touch targets ≥ 48dp, contrast, semantic labels, focus indicators (POS controls updated) | All |
| 18.5.8 | ✅ Thai / English / Lao Translation Complete | ตรวจสอบ ARB files ครบทุก key (~500 keys × 3 ภาษา) | 4.2.2-4.2.4 |

### 18.6 Build & Deployment
| # | Task | Detail | Depends |
|---|------|--------|---------|
| 18.6.1 | ✅ Build Android APK (Release) | `flutter build apk --release` — vendored `presentation_displays` + `sqlcipher_flutter_libs`, patched namespace/compileSdk/jvmTarget; APKs output at `build/app/outputs/apk/{dev,staging,prod}/release/` | All |
| 18.6.2 | ⬜ Build iOS (Release) | `flutter build ios --release`, TestFlight | All |
| 18.6.3 | ✅ Build Web (Release) | `flutter build web` — split database into `database_native.dart` (SQLCipher) + `database_web.dart` (drift WebDatabase/IndexedDB) with conditional import; output at `build/web` | All |
| 18.6.4 | ⬜ Deploy Backend to VPS | Docker compose up — API, PostgreSQL, Redis, Nginx | All |
| 18.6.5 | ✅ ตั้งค่า SSL (Let's Encrypt) | Certbot + Nginx, auto-renew | 18.6.4 |
| 18.6.6 | ✅ ตั้งค่า Nginx Reverse Proxy | API routing, WebSocket proxy, static files, gzip | 18.6.4 |
| 18.6.7 | ✅ ตั้งค่า Monitoring | Health check, uptime monitoring, error alerts | 18.6.4 |
| 18.6.8 | ✅ สร้าง Seed Script (Production) | Super admin account, default subscription plans | 18.6.4 |
| 18.6.9 | ✅ สร้าง Deploy Script | Automated deployment script (docker-compose pull + up) | 18.6.4 |

---

## Summary

| Phase | Tasks | Priority |
|-------|-------|----------|
| Phase 0: Project Setup | 19 | 🔴 Critical |
| Phase 1: Database & Backend Foundation | 32 | 🔴 Critical |
| Phase 2: Authentication | 24 | 🔴 Critical |
| Phase 3: Tenant & Settings | 20 + 7 (wizard) | 🔴 Critical |
| Phase 4: Flutter Foundation | 23 + 5 (services) | 🔴 Critical |
| Phase 5: Products & Categories | 17 | 🔴 Critical |
| Phase 6: POS Core (Cart & Order) | 35 | 🔴 Critical |
| Phase 7: Checkout & Payment | 16 | 🔴 Critical |
| Phase 8: Tables & Floor Plan | 18 | 🟠 High |
| Phase 9: Kitchen Display (KDS) | 14 | 🟠 High |
| Phase 10: Shifts & Cash | 12 | 🟠 High |
| Phase 11: Inventory & Stock | 11 | 🟠 High |
| Phase 12: Members | 9 | 🟡 Medium |
| Phase 13: Coupons | 8 | 🟡 Medium |
| Phase 14: Queue | 11 | 🟡 Medium |
| Phase 15: Reports & Dashboard | 18 | 🟡 Medium |
| Phase 16: Offline & Sync | 15 | 🟠 High |
| Phase 17: Hardware, Notif, etc. | 43 | 🟡 Medium |
| Phase 18: Testing & Deploy | 30 | 🔴 Critical |
| **Total** | **~280 tasks** | |

---

## Recommended Build Order (MVP First)

### 🏁 MVP (Minimum Viable Product) — Phase 0-7
> สามารถขายของได้, ชำระเงินได้, พิมพ์ใบเสร็จได้

**ลำดับ:** Setup → DB → Auth → Settings → Flutter Foundation → Products → POS → Checkout

### 🥈 V1.0 — Add Phase 8-11
> เพิ่ม Restaurant features: โต๊ะ, ครัว, กะ, สต็อก

### 🥇 V1.5 — Add Phase 12-16
> เพิ่ม Members, คูปอง, คิว, Reports, Offline Sync

### 🏆 V2.0 — Add Phase 17-18
> เพิ่ม Hardware, QR Menu, Admin, Full testing, Production deploy
