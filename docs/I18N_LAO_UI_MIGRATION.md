# Lao UI Migration Status

This document tracks the ongoing Thai-to-Lao UI migration in the Flutter app and records the conventions that should remain true as the work continues.

## Scope

- Frontend UI localization in `lumluay-app`
- Lao-facing text replacement for Thai UI strings
- Lao currency defaults where the UI previously assumed Thai-only values
- Preservation of multi-currency behavior where the product already supports it

## Current Status

- Migration is in progress
- Core reports, members, queue, receipts, and several settings screens have already been updated
- Remaining work is concentrated in core POS flows, order management, payment screens, and some shared utility components

## Conventions

When continuing the migration, keep these rules consistent:

1. Replace Thai UI-facing strings with Lao equivalents.
2. Use `₭` where Lao Kip should be shown in Lao-facing defaults.
3. Replace Thai-specific fallback currency codes such as `THB` with `LAK` only where the code path is a default, not where true multi-currency behavior exists.
4. Preserve proper names, locale labels, and system identifiers when translating them would reduce clarity.
5. Preserve widget structure and application behavior; this document is about localization, not redesign.

## Verified Completed Areas

- `lib/core/utils/validators.dart`
- `lib/core/services/fcm_service.dart`
- `lib/shared/widgets/app_utils_widgets.dart`
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
- `lib/shared/widgets/search_field.dart`
- `lib/shared/widgets/skeleton_widget.dart`

Special case:

- `lib/features/settings/presentation/pages/language_settings_page.dart` keeps Thai locale labels where they function as proper names.

## Remaining Priority Areas

1. POS core screens
2. Order management pages
3. Payment processing screens
4. Additional settings pages
5. Shared dialogs, notifications, and validation helpers

## Validation Checklist

- No Thai characters remain in Lao-facing UI text for the migrated area
- Currency labels remain consistent with locale expectations
- Validation and error messages stay understandable after translation
- Multi-currency behavior is not regressed by localization edits
- Core POS flows still function after string changes

## Follow-up Cleanup

The Flutter tool currently reports a few non-blocking warnings during web builds that are adjacent to localization work but not part of the migration itself:

- `l10n.yaml` still contains the deprecated `synthetic-package` argument
- Some asset directories referenced by `pubspec.yaml` are missing from the tree
- The build warns about missing Cupertino icon font packaging

These should be handled in separate cleanup changes so localization commits stay focused.