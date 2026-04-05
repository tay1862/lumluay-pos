import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../core/services/auto_lock_service.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/sync/sync_notifier.dart';
import '../../core/services/connectivity_bloc.dart';
import '../../core/theme/app_theme.dart';
import 'offline_banner.dart';
import 'language_switcher.dart';
import 'sync_status_indicator.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Nav item model
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem {
  final String path;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final List<String>? roles; // null = all roles

  const _NavItem({
    required this.path,
    required this.label,
    required this.icon,
    required this.selectedIcon,
    this.roles,
  });
}

bool _canAccessNavItem(_NavItem item, String userRole) {
  if (userRole == 'super_admin') return true;
  if (item.roles == null) return true;
  return item.roles!.contains(userRole);
}

const _navItems = [
  _NavItem(
    path: '/dashboard',
    label: 'ໜ້າຫຼັກ',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  _NavItem(
    path: '/pos',
    label: 'ຂາຍສິນຄ້າ',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale_rounded,
  ),
  _NavItem(
    path: '/tables',
    label: 'ຜັງໂຕະ',
    icon: Icons.table_restaurant_outlined,
    selectedIcon: Icons.table_restaurant_rounded,
  ),
  _NavItem(
    path: '/orders',
    label: 'ອໍເດີ',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
  ),
  _NavItem(
    path: '/kitchen',
    label: 'ຄົວ (KDS)',
    icon: Icons.restaurant_outlined,
    selectedIcon: Icons.restaurant_rounded,
  ),
  _NavItem(
    path: '/queue',
    label: 'ຄິວ',
    icon: Icons.people_outline,
    selectedIcon: Icons.people_rounded,
  ),
  _NavItem(
    path: '/members',
    label: 'ສະມາຊິກ',
    icon: Icons.person_outline,
    selectedIcon: Icons.person_rounded,
  ),
  _NavItem(
    path: '/coupons',
    label: 'ຄູປອງ',
    icon: Icons.confirmation_number_outlined,
    selectedIcon: Icons.confirmation_number_rounded,
    roles: ['owner', 'manager'],
  ),
  _NavItem(
    path: '/stock',
    label: 'ສະຕ໋ອກ',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
  ),
  _NavItem(
    path: '/products',
    label: 'ສິນຄ້າ',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront_rounded,
  ),
  _NavItem(
    path: '/reports',
    label: 'ລາຍງານ',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart_rounded,
    roles: ['owner', 'manager'],
  ),
  _NavItem(
    path: '/shifts',
    label: 'ກະ',
    icon: Icons.timer_outlined,
    selectedIcon: Icons.timer_rounded,
  ),
  _NavItem(
    path: '/settings',
    label: 'ຕັ້ງຄ່າ',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    roles: ['owner', 'manager'],
  ),
];

// Bottom nav items (phone — top 5 only + "more")
const _bottomNavItems = [
  _NavItem(
    path: '/dashboard',
    label: 'ໜ້າຫຼັກ',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
  ),
  _NavItem(
    path: '/pos',
    label: 'ຂາຍ',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale_rounded,
  ),
  _NavItem(
    path: '/tables',
    label: 'ໂຕະ',
    icon: Icons.table_restaurant_outlined,
    selectedIcon: Icons.table_restaurant_rounded,
  ),
  _NavItem(
    path: '/orders',
    label: 'ອໍເດີ',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long_rounded,
  ),
];

// ─────────────────────────────────────────────────────────────────────────────
// Main app shell
// ─────────────────────────────────────────────────────────────────────────────
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = GoRouterState.of(context).matchedLocation;
    final authState = ref.watch(authProvider);
    final userRole = authState is AuthAuthenticated
        ? authState.user.role
        : 'cashier';
    final userName = authState is AuthAuthenticated
        ? authState.user.displayName
        : '';

    final isWide = MediaQuery.of(context).size.width >= 720;

    if (isWide) {
      return UserActivityDetector(
        child: _WideShell(
          currentPath: currentPath,
          userRole: userRole,
          userName: userName,
          child: child,
        ),
      );
    } else {
      return UserActivityDetector(
        child: _NarrowShell(
          currentPath: currentPath,
          userName: userName,
          child: child,
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Wide shell (tablet / desktop)
// ─────────────────────────────────────────────────────────────────────────────
class _WideShell extends StatefulWidget {
  const _WideShell({
    required this.currentPath,
    required this.userRole,
    required this.userName,
    required this.child,
  });
  final String currentPath;
  final String userRole;
  final String userName;
  final Widget child;

  @override
  State<_WideShell> createState() => _WideShellState();
}

class _WideShellState extends State<_WideShell> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final visibleItems = _navItems.where((item) {
      return _canAccessNavItem(item, widget.userRole);
    }).toList();

    final selectedIdx = visibleItems.indexWhere(
        (item) => widget.currentPath.startsWith(item.path));

    return Scaffold(
      body: Row(
        children: [
          // Side rail
          NavigationRail(
            extended: _expanded,
            minWidth: 56.w,
            minExtendedWidth: 200.w,
            selectedIndex: selectedIdx < 0 ? 0 : selectedIdx,
            onDestinationSelected: (i) =>
                context.go(visibleItems[i].path),
            leading: _NavHeader(
              expanded: _expanded,
              userName: widget.userName,
              onToggle: () => setState(() => _expanded = !_expanded),
            ),
            trailing: _NavTrailer(expanded: _expanded),
            destinations: visibleItems
                .map((item) => NavigationRailDestination(
                      icon: Icon(item.icon),
                      selectedIcon: Icon(item.selectedIcon),
                      label: Text(item.label),
                    ))
                .toList(),
          ),
          const VerticalDivider(width: 1),
          Expanded(
            child: Column(
              children: [
                const OfflineBanner(),
                ShellTopBar(
                  currentPath: widget.currentPath,
                  userName: widget.userName,
                ),
                Expanded(child: widget.child),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Narrow shell (phone)
// ─────────────────────────────────────────────────────────────────────────────
class _NarrowShell extends ConsumerWidget {
  const _NarrowShell({
    required this.currentPath,
    required this.userName,
    required this.child,
  });
  final String currentPath;
  final String userName;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIdx = _bottomNavItems.indexWhere(
        (item) => currentPath.startsWith(item.path));

    return Scaffold(
      body: Column(
        children: [
          const OfflineBanner(),
          ShellTopBar(currentPath: currentPath, userName: userName),
          Expanded(child: child),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIdx < 0 ? 0 : selectedIdx,
        onDestinationSelected: (i) {
          if (i < _bottomNavItems.length) {
            context.go(_bottomNavItems[i].path);
            return;
          }
          _showMoreMenu(context, ref);
        },
        destinations: [
          ..._bottomNavItems.map((item) => NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon),
                label: item.label,
              )),
          const NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            label: 'ເພີ່ມເຕີມ',
          ),
        ],
      ),
    );
  }

  Future<void> _showMoreMenu(BuildContext context, WidgetRef ref) async {
    final authState = ref.read(authProvider);
    final userRole = authState is AuthAuthenticated ? authState.user.role : 'cashier';
    final moreItems = _navItems
        .where((item) => !_bottomNavItems.any((b) => b.path == item.path))
        .where((item) => _canAccessNavItem(item, userRole))
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: moreItems
              .map(
                (item) => ListTile(
                  leading: Icon(item.icon),
                  title: Text(item.label),
                  onTap: () {
                    Navigator.pop(ctx);
                    context.go(item.path);
                  },
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class ShellTopBar extends ConsumerWidget {
  const ShellTopBar({
    super.key,
    required this.currentPath,
    required this.userName,
  });

  final String currentPath;
  final String userName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = _titleForPath(currentPath);
    final initial = userName.isEmpty ? '?' : userName.substring(0, 1);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const _TopBarSyncButton(),
          const LanguageSwitcher(compact: true),
          SizedBox(width: 6.w),
          Stack(
            children: [
              IconButton(
                icon: Icon(
                  Icons.notifications_none_rounded,
                  color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                ),
                tooltip: 'ການແຈ້ງເຕືອນ',
                onPressed: () => context.push('/notifications'),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: Icon(
              Icons.settings_outlined,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
            tooltip: 'ຕັ້ງຄ່າ',
            onPressed: () => context.push('/settings'),
          ),
          SizedBox(width: 8.w),
          CircleAvatar(
            radius: 16.r,
            backgroundColor: AppColors.primarySoft,
            child: Text(
              initial,
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _titleForPath(String path) {
    if (path.startsWith('/dashboard')) return 'ພາບລວມທຸລະກິດ';
    if (path.startsWith('/pos')) return 'ຂາຍສິນຄ້າ';
    if (path.startsWith('/tables')) return 'ຜັງໂຕະ';
    if (path.startsWith('/orders')) return 'ອໍເດີ';
    if (path.startsWith('/kitchen')) return 'ຄົວ (KDS)';
    if (path.startsWith('/queue')) return 'ຈັດການຄິວ';
    if (path.startsWith('/members')) return 'ສະມາຊິກ';
    if (path.startsWith('/coupons')) return 'ຄູປອງ';
    if (path.startsWith('/stock')) return 'ສະຕ໋ອກ';
    if (path.startsWith('/products')) return 'ຈັດການສິນຄ້າ';
    if (path.startsWith('/reports')) return 'ລາຍງານ';
    if (path.startsWith('/settings')) return 'ຕັ້ງຄ່າ';
    if (path.startsWith('/notifications')) return 'ການແຈ້ງເຕືອນ';
    return 'LUMLUAY POS';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav header (logo + user info)
// ─────────────────────────────────────────────────────────────────────────────
class _NavHeader extends ConsumerWidget {
  const _NavHeader({
    required this.expanded,
    required this.userName,
    required this.onToggle,
  });
  final bool expanded;
  final String userName;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      children: [
        SizedBox(height: 8.h),
        if (expanded) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Center(
                    child: Text('L',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18.sp)),
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LUMLUAY',
                          style: TextStyle(
                              fontFamily: 'Sarabun',
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp,
                              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)),
                      Text(userName,
                          style: TextStyle(
                              fontFamily: 'Sarabun',
                              fontSize: 10.sp,
                              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.chevron_left_rounded, size: 20,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
                  onPressed: onToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ] else
          IconButton(
            icon: Icon(Icons.menu_rounded, size: 20,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            onPressed: onToggle,
          ),
        SizedBox(height: 8.h),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Nav trailer (notifications + logout)
// ─────────────────────────────────────────────────────────────────────────────
class _NavTrailer extends ConsumerWidget {
  const _NavTrailer({required this.expanded});
  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        children: [
          SyncStatusIndicator(expanded: expanded),
          IconButton(
            icon: Icon(Icons.notifications_outlined,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary),
            tooltip: 'ການແຈ້ງເຕືອນ',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: Icon(Icons.logout_rounded, color: AppColors.error.withOpacity(0.7)),
            tooltip: 'ອອກຈາກລະບົບ',
            onPressed: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar sync button — compact indicator with manual sync tap
// ─────────────────────────────────────────────────────────────────────────────
class _TopBarSyncButton extends ConsumerWidget {
  const _TopBarSyncButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityBlocStreamProvider);
    final syncState = ref.watch(syncNotifierProvider);

    final isOnline = connectivityAsync.maybeWhen(
      data: (s) => s is ConnectivityOnline,
      orElse: () => false,
    );

    final Color dotColor;
    final String tooltip;
    final Widget? overlay;

    if (!isOnline) {
      dotColor = AppColors.error;
      tooltip = 'ອອບໄລນ໌';
      overlay = null;
    } else if (syncState.isSyncing) {
      dotColor = AppColors.primary;
      tooltip = 'ກຳລັງຊິງຄ໌...';
      overlay = SizedBox(
        width: 16.w,
        height: 16.w,
        child: CircularProgressIndicator(strokeWidth: 2, color: dotColor),
      );
    } else if (syncState.hasError) {
      dotColor = AppColors.warning;
      tooltip = 'ຊິງຄ໌ລົ້ມເຫຼວ — ແຕະເພື່ອລອງໃໝ່';
      overlay = null;
    } else if (syncState.pendingCount > 0) {
      dotColor = AppColors.warning;
      tooltip = 'ລໍຖ້າຊິງຄ໌ ${syncState.pendingCount} ລາຍການ';
      overlay = null;
    } else {
      dotColor = AppColors.success;
      tooltip = syncState.lastSyncAt != null ? 'ຊິງຄ໌ແລ້ວ' : 'ອອນໄລນ໌';
      overlay = null;
    }

    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: isOnline && !syncState.isSyncing
            ? () => ref.read(syncEngineProvider).performSync()
            : null,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 8.h),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (overlay != null)
                overlay
              else
                Icon(Icons.sync, size: 18.sp, color: dotColor),
              if (syncState.pendingCount > 0) ...[
                SizedBox(width: 2.w),
                Text(
                  '${syncState.pendingCount}',
                  style: TextStyle(
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w700,
                    color: dotColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
