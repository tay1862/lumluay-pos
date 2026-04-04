import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/pin_lock_page.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../features/shifts/data/shifts_repository.dart';
import '../../features/pos/presentation/pages/pos_page.dart';
import '../../features/kitchen/presentation/pages/kitchen_page.dart';
import '../../features/reports/presentation/pages/reports_page.dart';
import '../../features/reports/presentation/pages/sales_report_page.dart';
import '../../features/reports/presentation/pages/products_report_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../../features/tables/presentation/pages/tables_page.dart';
import '../../features/stock/presentation/pages/stock_page.dart';
import '../../features/members/presentation/pages/members_page.dart';
import '../../features/orders/presentation/pages/orders_page.dart';
import '../../features/shifts/presentation/pages/shifts_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/products/presentation/pages/products_page.dart';
import '../../features/products/presentation/pages/product_form_page.dart';
import '../../features/queue/presentation/pages/queue_page.dart';
import '../../features/notifications/presentation/pages/notifications_page.dart';
import '../../features/settings/presentation/pages/users_page.dart';
import '../../features/settings/presentation/pages/currency_settings_page.dart';
import '../../features/settings/presentation/pages/receipt_settings_page.dart';
import '../../features/settings/presentation/pages/printer_settings_page.dart';
import '../../features/settings/presentation/pages/language_settings_page.dart';
import '../../features/settings/presentation/pages/theme_settings_page.dart';
import '../../features/settings/presentation/pages/auto_lock_settings_page.dart';
import '../../features/settings/presentation/pages/training_mode_page.dart';
import '../../features/settings/presentation/pages/setup_wizard_page.dart';
import '../../features/settings/presentation/pages/backup_settings_page.dart';
import '../../features/settings/presentation/pages/import_page.dart';
import '../../features/settings/presentation/pages/export_page.dart';
import '../../features/products/presentation/pages/category_management_page.dart';
import '../../features/products/presentation/pages/modifier_group_management_page.dart';
import '../../features/tables/presentation/pages/zone_management_page.dart';
import '../../features/coupons/presentation/pages/coupons_page.dart';
import '../../features/coupons/presentation/pages/coupon_form_page.dart';
import '../../features/admin/presentation/pages/admin_dashboard_page.dart';
import '../../features/admin/presentation/pages/tenant_list_page.dart';
import '../../features/admin/presentation/pages/plan_management_page.dart';
import '../../features/pos/presentation/pages/customer_display_page.dart';
import '../../features/qr_menu/presentation/pages/qr_menu_page.dart';
import '../../features/coupons/data/coupons_repository.dart' show Coupon;
import '../../../shared/widgets/app_shell.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = _RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/dashboard',
    refreshListenable: routerNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
      final isAuthenticated = authState is AuthAuthenticated;
      final userRole = authState is AuthAuthenticated
          ? authState.user.role
          : null;
      final loc = state.matchedLocation;
      final isPublic = loc == '/login' || loc == '/pin';

      if (!isAuthenticated && !isPublic) return '/login';
      if (isAuthenticated && loc == '/login') return '/dashboard';
      if (isAuthenticated && loc.startsWith('/admin') && userRole != 'super_admin') {
        return '/dashboard';
      }

      // 10.2.5 — Shift check: after login, ensure a shift is open.
      // Routes exempt from shift check: settings, shifts itself, public routes.
      if (isAuthenticated && !isPublic) {
        const shiftExempt = ['/shifts', '/settings', '/login', '/pin'];
        final isExempt = shiftExempt.any((p) => loc.startsWith(p));
        if (!isExempt) {
          final shiftState = ref.read(shiftBlocProvider);
          if (shiftState.status == ShiftBlocStatus.loading ||
              shiftState.status == ShiftBlocStatus.initial) {
            // Still loading — allow through; the UI will show loading state.
            return null;
          }
          if (shiftState.status == ShiftBlocStatus.closed) {
            return '/shifts';
          }
        }
      }

      return null;
    },
    routes: [
      // ── Public (outside shell) ──────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/pin',
        name: 'pin',
        builder: (context, state) => PinLockPage(
          userId: state.uri.queryParameters['userId'],
        ),
      ),

      // ── Authenticated routes inside AppShell ──────────────────────
      ShellRoute(
        builder: (context, state, child) => AppShell(child: child),
        routes: [
          GoRoute(
            path: '/dashboard',
            name: 'dashboard',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/pos',
            name: 'pos',
            builder: (context, state) => PosPage(
              initialTableId: state.uri.queryParameters['tableId'],
              initialTableName: state.uri.queryParameters['tableName'],
            ),
          ),
          GoRoute(
            path: '/kitchen',
            name: 'kitchen',
            builder: (context, state) => const KitchenPage(),
          ),
          GoRoute(
            path: '/reports',
            name: 'reports',
            builder: (context, state) => const ReportsPage(),
          ),
          GoRoute(
            path: '/reports/sales',
            name: 'reports-sales',
            builder: (context, state) => const SalesReportPage(),
          ),
          GoRoute(
            path: '/reports/products',
            name: 'reports-products',
            builder: (context, state) => const ProductsReportPage(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsPage(),
          ),
          GoRoute(
            path: '/settings/users',
            name: 'settings-users',
            builder: (context, state) => const UsersPage(),
          ),
          GoRoute(
            path: '/settings/currency',
            name: 'settings-currency',
            builder: (context, state) => const CurrencySettingsPage(),
          ),
          GoRoute(
            path: '/settings/receipt',
            name: 'settings-receipt',
            builder: (context, state) => const ReceiptSettingsPage(),
          ),
          GoRoute(
            path: '/settings/printer',
            name: 'settings-printer',
            builder: (context, state) => const PrinterSettingsPage(),
          ),
          GoRoute(
            path: '/settings/language',
            name: 'settings-language',
            builder: (context, state) => const LanguageSettingsPage(),
          ),
          GoRoute(
            path: '/settings/theme',
            name: 'settings-theme',
            builder: (context, state) => const ThemeSettingsPage(),
          ),
          GoRoute(
            path: '/settings/auto-lock',
            name: 'settings-auto-lock',
            builder: (context, state) => const AutoLockSettingsPage(),
          ),
          GoRoute(
            path: '/settings/training',
            name: 'settings-training',
            builder: (context, state) => const TrainingModePage(),
          ),
          GoRoute(
            path: '/settings/backup',
            name: 'settings-backup',
            builder: (context, state) => const BackupSettingsPage(),
          ),
          GoRoute(
            path: '/settings/import',
            name: 'settings-import',
            builder: (context, state) => const ImportPage(),
          ),
          GoRoute(
            path: '/settings/export',
            name: 'settings-export',
            builder: (context, state) => const ExportPage(),
          ),
          GoRoute(
            path: '/settings/zones',
            name: 'settings-zones',
            builder: (context, state) => const ZoneManagementPage(),
          ),
          GoRoute(
            path: '/setup-wizard',
            name: 'setup-wizard',
            builder: (context, state) => const SetupWizardPage(),
          ),
          GoRoute(
            path: '/tables',
            name: 'tables',
            builder: (context, state) => const TablesPage(),
          ),
          GoRoute(
            path: '/stock',
            name: 'stock',
            builder: (context, state) => const StockPage(),
          ),
          GoRoute(
            path: '/members',
            name: 'members',
            builder: (context, state) => const MembersPage(),
          ),
          GoRoute(
            path: '/coupons',
            name: 'coupons',
            builder: (context, state) => const CouponsPage(),
          ),
          GoRoute(
            path: '/coupons/new',
            name: 'coupon-new',
            builder: (context, state) => const CouponFormPage(),
          ),
          GoRoute(
            path: '/coupons/:id/edit',
            name: 'coupon-edit',
            builder: (context, state) => CouponFormPage(
              coupon: state.extra as Coupon?,
            ),
          ),
          GoRoute(
            path: '/orders',
            name: 'orders',
            builder: (context, state) => const OrdersPage(),
          ),
          GoRoute(
            path: '/orders/:id',
            name: 'order-detail',
            builder: (context, state) =>
                OrderDetailPage(orderId: state.pathParameters['id']!),
          ),
          GoRoute(
            path: '/shifts',
            name: 'shifts',
            builder: (context, state) => const ShiftsPage(),
          ),
          GoRoute(
            path: '/products',
            name: 'products',
            builder: (context, state) => const ProductsPage(),
          ),
          GoRoute(
            path: '/products/new',
            name: 'product-new',
            builder: (context, state) => const ProductFormPage(),
          ),
          GoRoute(
            path: '/products/:id/edit',
            name: 'product-edit',
            builder: (context, state) =>
                ProductFormPage(productId: state.pathParameters['id']),
          ),
          GoRoute(
            path: '/products/categories',
            name: 'products-categories',
            builder: (context, state) => const CategoryManagementPage(),
          ),
          GoRoute(
            path: '/products/modifier-groups',
            name: 'products-modifier-groups',
            builder: (context, state) =>
                const ModifierGroupManagementPage(),
          ),
          GoRoute(
            path: '/queue',
            name: 'queue',
            builder: (context, state) => const QueuePage(),
          ),
          GoRoute(
            path: '/notifications',
            name: 'notifications',
            builder: (context, state) => const NotificationsPage(),
          ),
          GoRoute(
            path: '/customer-display',
            name: 'customer-display',
            builder: (context, state) => const CustomerDisplayPage(),
          ),
          GoRoute(
            path: '/qr-menu',
            name: 'qr-menu',
            builder: (context, state) => QrMenuPage(
              menuUrl: state.uri.queryParameters['url'] ?? '',
              tenantName: state.uri.queryParameters['name'] ?? 'LUMLUAY POS',
            ),
          ),
          GoRoute(
            path: '/admin/dashboard',
            name: 'admin-dashboard',
            builder: (context, state) => const AdminDashboardPage(),
          ),
          GoRoute(
            path: '/admin/tenants',
            name: 'admin-tenants',
            builder: (context, state) => const TenantListPage(),
          ),
          GoRoute(
            path: '/admin/plans',
            name: 'admin-plans',
            builder: (context, state) => const PlanManagementPage(),
          ),
        ],
      ),
    ],
  );
});

// ── Router notifier to react to auth state changes ────────────────────────
class _RouterNotifier extends ChangeNotifier {
  _RouterNotifier(this._ref) {
    _ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
    _ref.listen(shiftBlocProvider, (previous, next) {
      if (previous?.status != next.status) notifyListeners();
    });
  }

  final Ref _ref;
}
