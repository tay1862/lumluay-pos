import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../admin/data/admin_repository.dart';

class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  static const routePath = '/admin/dashboard';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminDashboardProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: dashboardAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (dashboard) => RefreshIndicator(
          onRefresh: () => ref.refresh(adminDashboardProvider.future),
          child: ListView(
            padding: EdgeInsets.all(16.r),
            children: [
              // Stats cards
              Row(
                children: [
                  _StatCard(
                    label: 'Tenants',
                    value: '${dashboard.stats.tenants}',
                    icon: Icons.business,
                    color: theme.colorScheme.primary,
                  ),
                  SizedBox(width: 8.w),
                  _StatCard(
                    label: 'Users',
                    value: '${dashboard.stats.users}',
                    icon: Icons.people,
                    color: Colors.teal,
                  ),
                  SizedBox(width: 8.w),
                  _StatCard(
                    label: 'Orders',
                    value: '${dashboard.stats.orders}',
                    icon: Icons.receipt_long,
                    color: Colors.orange,
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.attach_money),
                  title: const Text('Total Revenue'),
                  trailing: Text(
                    dashboard.totalRevenue.toStringAsFixed(2),
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              SizedBox(height: 16.h),

              // Expiring tenants
              if (dashboard.expiringTenants.isNotEmpty) ...[
                Text('Expiring Soon',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                ...dashboard.expiringTenants.map(
                  (t) => ListTile(
                    leading: const Icon(Icons.warning_amber, color: Colors.orange),
                    title: Text('${t['name']}'),
                    dense: true,
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(12.r),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28.r),
              SizedBox(height: 4.h),
              Text(value,
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(label, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}
