# Lao UI Migration — Full Review & Handoff Plan

> **Last updated**: 2026-04-05  
> **Repository**: https://github.com/tay1862/lumluay-pos.git  
> **Branch**: `main` (HEAD: `f933e58`)

---

## 1. Project Overview

The Lumluay POS Flutter app was originally built with Thai (ภาษาไทย) UI text. The goal of Phase 4.1 is to convert **all hardcoded Thai UI strings to Lao (ພາສາລາວ)** equivalents, update currency symbols (`฿` → `₭`) and default currency codes (`THB` → `LAK`) where appropriate.

---

## 2. What Was Done (Complete Changelog)

### 2.1 Session 1 — Cascade (initial batch)
Converted Thai→Lao in these files:
- `lib/shared/widgets/app_dialogs.dart`
- `lib/shared/widgets/pin_dialog.dart`
- `lib/shared/widgets/sync_status_indicator.dart`
- `lib/shared/widgets/offline_banner.dart`
- `lib/shared/widgets/app_utils_widgets.dart` (currency defaults THB→LAK)
- `lib/features/pos/presentation/widgets/product_grid.dart`
- `lib/features/pos/presentation/widgets/order_cart.dart`
- `lib/features/pos/presentation/widgets/payment_panel.dart`
- `lib/features/pos/presentation/widgets/cart_item_card.dart`
- `lib/features/pos/presentation/widgets/member_lookup_dialog.dart`
- `lib/features/auth/presentation/pages/pin_lock_page.dart`
- `lib/features/admin/presentation/pages/plan_management_page.dart`
- `lib/features/coupons/presentation/pages/coupons_page.dart`
- `lib/features/coupons/presentation/pages/coupon_form_page.dart`

### 2.2 Session 2 — Cascade (settings + reports + queue)
- `lib/core/utils/validators.dart`
- `lib/core/services/fcm_service.dart`
- `lib/shared/widgets/search_field.dart`
- `lib/shared/widgets/skeleton_widget.dart`
- `lib/features/reports/presentation/pages/sales_report_page.dart`
- `lib/features/reports/presentation/pages/products_report_page.dart`
- `lib/features/reports/presentation/pages/reports_page.dart`
- `lib/features/members/presentation/pages/members_page.dart`
- `lib/features/queue/presentation/pages/queue_page.dart`
- `lib/features/queue/data/queue_repository.dart`
- `lib/features/receipts/presentation/pages/receipt_page.dart`
- `lib/features/settings/presentation/pages/training_mode_page.dart`
- `lib/features/settings/presentation/pages/printer_settings_page.dart`
- `lib/features/settings/presentation/pages/theme_settings_page.dart`
- `lib/features/settings/presentation/pages/receipt_settings_page.dart`
- `lib/features/settings/presentation/pages/auto_lock_settings_page.dart`
- `lib/features/settings/presentation/pages/currency_settings_page.dart`

### 2.3 Session 3 — Other AI (massive batch in commit `beca779`)
75 files changed, 3588 insertions, 1527 deletions:
- `lib/features/orders/presentation/pages/orders_page.dart` (48 lines)
- `lib/features/tables/presentation/pages/tables_page.dart` (38 lines)
- `lib/features/products/presentation/pages/modifier_group_management_page.dart` (45 lines)
- `lib/features/products/presentation/pages/product_form_page.dart` (38 lines)
- `lib/features/stock/presentation/pages/stock_page.dart` (33 lines)
- `lib/features/shifts/presentation/pages/shifts_page.dart` (29 lines)
- `lib/features/products/presentation/pages/products_page.dart` (21 lines)
- `lib/features/products/presentation/pages/category_management_page.dart` (18 lines)
- `lib/features/tables/presentation/pages/zone_management_page.dart` (16 lines)
- `lib/features/pos/presentation/widgets/discount_dialog.dart` (11 lines)
- `lib/features/pos/presentation/widgets/modifier_dialog.dart` (8 lines)
- `lib/features/orders/presentation/widgets/order_card.dart` (6 lines)
- `lib/features/notifications/presentation/pages/notifications_page.dart` (5 lines)
- `lib/features/kitchen/presentation/pages/kitchen_page.dart` (4 lines)
- `lib/features/kitchen/presentation/widgets/kitchen_order_card.dart` (3 lines)
- `lib/features/coupons/data/coupons_repository.dart` (3 lines)
- `lib/features/pos/presentation/widgets/product_list_view.dart` (2 lines)
- **Also**: `setup_wizard_page.dart` refactored to use l10n ARB system, `settings_page.dart`, `users_page.dart`, `dashboard_page.dart`, `pos_page.dart`, `login_page.dart`, `app_shell.dart`
- **New l10n system**: Added `l10n/app_en.arb`, `l10n/app_lo.arb`, `l10n/app_th.arb` + generated localizations
- **Test files updated**: `login_pin_widget_test.dart`, `payment_panel_widget_test.dart`, `product_grid_widget_test.dart`, `app_utils_widgets_test.dart`
- **New test files**: `kitchen_repository_test.dart`, `notifications_test.dart`, `receipts_test.dart`, `stock_repository_test.dart`

---

## 3. Current State — Verification Results (2026-04-05)

### 3.1 Thai text remaining in production code (`lib/`)
**Only 5 lines remain — ALL intentional:**

| File | Line | Content | Reason |
|------|------|---------|--------|
| `language_settings_page.dart` | 14 | `label: 'ภาษาไทย'` | Thai locale proper name |
| `language_settings_page.dart` | 16 | `nativeName: 'ไทย'` | Thai locale proper name |
| `settings_page.dart` | 552 | `title: const Text('ภาษาไทย')` | Thai locale display label |
| `currency_settings_page.dart` | 42 | `('THB', '฿', 'ບາດໄທ')` | THB currency entry (฿ is correct symbol) |
| `app_utils_widgets.dart` | 59 | `return '฿'` | THB→฿ mapping in multi-currency formatter |

### 3.2 Thai text remaining in test code (`test/`)
**Only 1 line — intentional:**

| File | Line | Content | Reason |
|------|------|---------|--------|
| `app_utils_widgets_test.dart` | 8 | `'฿1,234.50'` | Tests THB formatting — correct |

### 3.3 Lao text in production code
**849 lines** of Lao text across all source files — confirms migration is complete.

### 3.4 l10n ARB System
Three ARB files are in place:
- `lib/l10n/app_en.arb` — English
- `lib/l10n/app_lo.arb` — Lao (ລາວ)
- `lib/l10n/app_th.arb` — Thai (ไทย)

Generated localizations exist at `lib/l10n/generated/`. The `setup_wizard_page.dart` was refactored to use this system. Other pages still use hardcoded Lao strings (not yet migrated to ARB keys).

### 3.5 Git Status
- **Working tree is clean** — all changes committed and pushed
- **Latest commit**: `f933e58` on `main`
- **Remote**: synced with `origin/main`

---

## 4. Conventions (MUST follow for any future work)

1. **Thai text in UI** → Replace with Lao equivalent
2. **Currency symbol `฿`** → Replace with `₭` only in Lao-facing defaults; keep `฿` in THB currency mapping functions
3. **Fallback currency `'THB'`** → Change to `'LAK'` only where it's a default, NOT in multi-currency data structures
4. **Thai locale labels** (`ภาษาไทย`, `ไทย`) → Keep as-is; they are proper names for the Thai language option
5. **Widget structure** → Preserve exactly; this is localization, not redesign
6. **l10n ARB keys** → Use `AppLocalizations.of(context)!.keyName` pattern when migrating to ARB system

---

## 5. Next Phase Plan

### Phase 4.2: Migrate hardcoded Lao strings to ARB l10n system (RECOMMENDED)

Currently most files have **hardcoded Lao strings** directly in the Dart source. The proper Flutter i18n approach is to use the ARB localization system that's already been set up.

**Priority order:**

#### Step 1 — Define ARB keys for all existing hardcoded strings
- Scan all `.dart` files for hardcoded Lao strings (Unicode range `\x{0E80}-\x{0EFF}`)
- Add corresponding keys to `app_lo.arb`, `app_th.arb`, `app_en.arb`
- Run `flutter gen-l10n` to regenerate

#### Step 2 — Replace hardcoded strings with ARB references
Replace patterns like:
```dart
// Before:
Text('ຕັ້ງຄ່າ')
// After:
Text(AppLocalizations.of(context)!.settings)
```

**Files to migrate (by feature area):**

1. **Core & Shared** (~15 files)
   - `validators.dart`, `fcm_service.dart`
   - `app_dialogs.dart`, `pin_dialog.dart`, `sync_status_indicator.dart`
   - `offline_banner.dart`, `search_field.dart`, `skeleton_widget.dart`
   - `app_utils_widgets.dart`, `app_shell.dart`

2. **POS** (~8 files)
   - `pos_page.dart`, `product_grid.dart`, `order_cart.dart`
   - `payment_panel.dart`, `cart_item_card.dart`
   - `discount_dialog.dart`, `modifier_dialog.dart`, `member_lookup_dialog.dart`

3. **Features** (~20 files)
   - `orders_page.dart`, `order_card.dart`
   - `products_page.dart`, `product_form_page.dart`, `category_management_page.dart`
   - `modifier_group_management_page.dart`, `product_list_view.dart`
   - `tables_page.dart`, `zone_management_page.dart`
   - `kitchen_page.dart`, `kitchen_order_card.dart`
   - `members_page.dart`, `queue_page.dart`, `queue_repository.dart`
   - `receipt_page.dart`, `notifications_page.dart`
   - `reports_page.dart`, `sales_report_page.dart`, `products_report_page.dart`
   - `shifts_page.dart`, `stock_page.dart`

4. **Settings** (~10 files)
   - `settings_page.dart`, `training_mode_page.dart`
   - `printer_settings_page.dart`, `theme_settings_page.dart`
   - `receipt_settings_page.dart`, `auto_lock_settings_page.dart`
   - `currency_settings_page.dart`, `users_page.dart`
   - `login_page.dart`, `pin_lock_page.dart`

#### Step 3 — Update tests
- Ensure all `expect(find.text(...))` calls reference the correct localized strings
- Add localization test wrappers if needed

#### Step 4 — Build cleanup
- Remove deprecated `synthetic-package` from `l10n.yaml`
- Fix missing asset directories in `pubspec.yaml`
- Fix Cupertino icon font packaging warning

---

## 6. Quick Verification Commands

```bash
# Count remaining Thai text in production code (should be 5):
grep -rnP '[\x{0E00}-\x{0E7F}]' lib/ --include='*.dart' | grep -v '\.g\.dart' | grep -v 'l10n/' | wc -l

# Count Lao text in production code (should be ~849):
grep -rnP '[\x{0E80}-\x{0EFF}]' lib/ --include='*.dart' | grep -v '\.g\.dart' | grep -v 'l10n/' | wc -l

# Count Thai text in test code (should be 1):
grep -rnP '[\x{0E00}-\x{0E7F}]' test/ --include='*.dart' | wc -l

# Build web to check for errors:
flutter build web --release 2>&1 | grep -i error
```

---

## 7. Summary

| Metric | Value |
|--------|-------|
| **Total files migrated** | 65+ production files |
| **Thai lines remaining (production)** | 5 (all intentional) |
| **Thai lines remaining (test)** | 1 (intentional) |
| **Lao lines in production** | ~849 |
| **l10n ARB keys defined** | ~50 (setup wizard area) |
| **Git status** | Clean, pushed to `origin/main` |
| **Phase 4.1 status** | ✅ **COMPLETE** |
| **Phase 4.2 status** | 📋 Planned (ARB migration) |