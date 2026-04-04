import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../admin/data/admin_repository.dart';

final _tenantPageProvider = StateProvider<int>((ref) => 1);

class TenantListPage extends ConsumerWidget {
  const TenantListPage({super.key});

  static const routePath = '/admin/tenants';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final page = ref.watch(_tenantPageProvider);
    final tenantsAsync = ref.watch(adminTenantsProvider(page));
    final repo = ref.read(adminRepositoryProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Tenants')),
      body: tenantsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (result) {
          final List<dynamic> tenants =
              (result['data'] as List<dynamic>?) ?? [];
          final meta = result['meta'] as Map<String, dynamic>? ?? {};
          final totalPages = (meta['pages'] as num?)?.toInt() ?? 1;

          return Column(
            children: [
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () =>
                      ref.refresh(adminTenantsProvider(page).future),
                  child: ListView.builder(
                    itemCount: tenants.length,
                    itemBuilder: (_, i) {
                      final t = Map<String, dynamic>.from(tenants[i] as Map);
                      final isActive = t['isActive'] == true;
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isActive
                              ? Colors.green.withValues(alpha: 0.15)
                              : theme.colorScheme.error.withValues(alpha: 0.1),
                          child: Icon(
                            Icons.business,
                            color: isActive
                                ? Colors.green
                                : theme.colorScheme.error,
                            size: 20.r,
                          ),
                        ),
                        title: Text('${t['name']}'),
                        subtitle: Text('${t['slug']}'),
                        trailing: Switch(
                          value: isActive,
                          onChanged: (val) async {
                            await repo.setTenantActive('${t['id']}', val);
                            ref.invalidate(adminTenantsProvider(page));
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              // Pagination
              if (totalPages > 1)
                Padding(
                  padding: EdgeInsets.all(8.r),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: page > 1
                            ? () => ref
                                .read(_tenantPageProvider.notifier)
                                .state = page - 1
                            : null,
                      ),
                      Text('$page / $totalPages'),
                      IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: page < totalPages
                            ? () => ref
                                .read(_tenantPageProvider.notifier)
                                .state = page + 1
                            : null,
                      ),
                    ],
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
