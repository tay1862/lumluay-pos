import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../core/services/auto_lock_service.dart';
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

const _navItems = [
  _NavItem(
    path: '/dashboard',
    label: 'หน้าหลัก',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  _NavItem(
    path: '/pos',
    label: 'ขายสินค้า',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale,
  ),
  _NavItem(
    path: '/tables',
    label: 'ผังโต๊ะ',
    icon: Icons.table_restaurant_outlined,
    selectedIcon: Icons.table_restaurant,
  ),
  _NavItem(
    path: '/orders',
    label: 'ออเดอร์',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
  ),
  _NavItem(
    path: '/kitchen',
    label: 'ครัว (KDS)',
    icon: Icons.restaurant_outlined,
    selectedIcon: Icons.restaurant,
  ),
  _NavItem(
    path: '/queue',
    label: 'คิว',
    icon: Icons.people_outline,
    selectedIcon: Icons.people,
  ),
  _NavItem(
    path: '/members',
    label: 'สมาชิก',
    icon: Icons.person_outline,
    selectedIcon: Icons.person,
  ),
  _NavItem(
    path: '/coupons',
    label: 'คูปอง',
    icon: Icons.confirmation_number_outlined,
    selectedIcon: Icons.confirmation_number,
    roles: ['owner', 'manager'],
  ),
  _NavItem(
    path: '/stock',
    label: 'สต็อก',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2,
  ),
  _NavItem(
    path: '/products',
    label: 'สินค้า',
    icon: Icons.storefront_outlined,
    selectedIcon: Icons.storefront,
  ),
  _NavItem(
    path: '/reports',
    label: 'รายงาน',
    icon: Icons.bar_chart_outlined,
    selectedIcon: Icons.bar_chart,
    roles: ['owner', 'manager'],
  ),
  _NavItem(
    path: '/shifts',
    label: 'กะ',
    icon: Icons.timer_outlined,
    selectedIcon: Icons.timer,
  ),
  _NavItem(
    path: '/settings',
    label: 'ตั้งค่า',
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings,
    roles: ['owner', 'manager'],
  ),
];

// Bottom nav items (phone — top 5 only + "more")
const _bottomNavItems = [
  _NavItem(
    path: '/dashboard',
    label: 'หน้าหลัก',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard,
  ),
  _NavItem(
    path: '/pos',
    label: 'ขาย',
    icon: Icons.point_of_sale_outlined,
    selectedIcon: Icons.point_of_sale,
  ),
  _NavItem(
    path: '/tables',
    label: 'โต๊ะ',
    icon: Icons.table_restaurant_outlined,
    selectedIcon: Icons.table_restaurant,
  ),
  _NavItem(
    path: '/orders',
    label: 'ออเดอร์',
    icon: Icons.receipt_long_outlined,
    selectedIcon: Icons.receipt_long,
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
      if (item.roles == null) return true;
      return item.roles!.contains(widget.userRole);
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
            icon: Icon(Icons.more_horiz),
            label: 'เพิ่มเติม',
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
        .where((item) => item.roles == null || item.roles!.contains(userRole))
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

    return Container(
      height: 56.h,
      padding: EdgeInsets.symmetric(horizontal: 12.w),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const LanguageSwitcher(compact: true),
          SizedBox(width: 6.w),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none),
                tooltip: 'การแจ้งเตือน',
                onPressed: () => context.push('/notifications'),
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'ตั้งค่า',
            onPressed: () => context.push('/settings'),
          ),
          SizedBox(width: 8.w),
          CircleAvatar(
            radius: 16.r,
            child: Text(
              initial,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  String _titleForPath(String path) {
    if (path.startsWith('/dashboard')) return 'ภาพรวมธุรกิจ';
    if (path.startsWith('/pos')) return 'ขายสินค้า';
    if (path.startsWith('/tables')) return 'ผังโต๊ะ';
    if (path.startsWith('/orders')) return 'ออเดอร์';
    if (path.startsWith('/kitchen')) return 'ครัว (KDS)';
    if (path.startsWith('/queue')) return 'จัดการคิว';
    if (path.startsWith('/members')) return 'สมาชิก';
    if (path.startsWith('/coupons')) return 'คูปอง';
    if (path.startsWith('/stock')) return 'สต็อก';
    if (path.startsWith('/products')) return 'จัดการสินค้า';
    if (path.startsWith('/reports')) return 'รายงาน';
    if (path.startsWith('/settings')) return 'ตั้งค่า';
    if (path.startsWith('/notifications')) return 'การแจ้งเตือน';
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
    return Column(
      children: [
        SizedBox(height: 8.h),
        if (expanded) ...[
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Center(
                    child: Text('L',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18.sp)),
                  ),
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LUMLUAY',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 13.sp)),
                      Text(userName,
                          style: TextStyle(
                              fontSize: 10.sp, color: Colors.black54),
                          overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left, size: 20),
                  onPressed: onToggle,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
        ] else
          IconButton(
            icon: const Icon(Icons.menu, size: 20),
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
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Column(
        children: [
          SyncStatusIndicator(expanded: expanded),
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            tooltip: 'การแจ้งเตือน',
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
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
