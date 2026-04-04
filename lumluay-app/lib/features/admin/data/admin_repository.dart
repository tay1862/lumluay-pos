import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────

class AdminStats {
  final int tenants;
  final int users;
  final int orders;
  const AdminStats(
      {required this.tenants, required this.users, required this.orders});

  factory AdminStats.fromJson(Map<String, dynamic> j) => AdminStats(
        tenants: (j['tenants'] as num?)?.toInt() ?? 0,
        users: (j['users'] as num?)?.toInt() ?? 0,
        orders: (j['orders'] as num?)?.toInt() ?? 0,
      );
}

class AdminDashboard {
  final AdminStats stats;
  final List<Map<String, dynamic>> expiringTenants;
  final double totalRevenue;

  const AdminDashboard({
    required this.stats,
    required this.expiringTenants,
    required this.totalRevenue,
  });

  factory AdminDashboard.fromJson(Map<String, dynamic> j) => AdminDashboard(
        stats: AdminStats.fromJson(j['stats'] as Map<String, dynamic>),
        expiringTenants: (j['expiringTenants'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [],
        totalRevenue: (j['totalRevenue'] as num?)?.toDouble() ?? 0,
      );
}

class TenantItem {
  final String id;
  final String name;
  final String slug;
  final bool isActive;
  final DateTime? subscriptionExpiresAt;
  final DateTime createdAt;

  const TenantItem({
    required this.id,
    required this.name,
    required this.slug,
    required this.isActive,
    this.subscriptionExpiresAt,
    required this.createdAt,
  });

  factory TenantItem.fromJson(Map<String, dynamic> j) => TenantItem(
        id: '${j['id']}',
        name: '${j['name']}',
        slug: '${j['slug']}',
        isActive: j['isActive'] == true,
        subscriptionExpiresAt: j['subscriptionExpiresAt'] != null
            ? DateTime.tryParse('${j['subscriptionExpiresAt']}')
            : null,
        createdAt:
            DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
      );
}

class SubscriptionPlan {
  final String id;
  final String name;
  final String slug;
  final double monthlyPrice;
  final double? yearlyPrice;
  final bool isActive;

  const SubscriptionPlan({
    required this.id,
    required this.name,
    required this.slug,
    required this.monthlyPrice,
    this.yearlyPrice,
    required this.isActive,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> j) => SubscriptionPlan(
        id: '${j['id']}',
        name: '${j['name']}',
        slug: '${j['slug']}',
        monthlyPrice: (j['monthlyPrice'] as num?)?.toDouble() ?? 0,
        yearlyPrice: j['yearlyPrice'] != null
            ? (j['yearlyPrice'] as num).toDouble()
            : null,
        isActive: j['isActive'] == true,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────

class AdminRepository {
  const AdminRepository(this._client);
  final ApiClient _client;

  Future<AdminDashboard> getDashboard() async {
    final data = await _client.get<Map<String, dynamic>>('/admin/dashboard');
    return AdminDashboard.fromJson(data);
  }

  Future<Map<String, dynamic>> getTenants({int page = 1, int limit = 20}) async {
    return _client.get<Map<String, dynamic>>(
      '/admin/tenants',
      queryParameters: {'page': '$page', 'limit': '$limit'},
    );
  }

  Future<void> setTenantActive(String id, bool isActive) async {
    await _client.patch<dynamic>(
        '/admin/tenants/$id/active', data: {'isActive': isActive});
  }

  Future<List<SubscriptionPlan>> getPlans() async {
    final data = await _client.get<List<dynamic>>('/admin/plans');
    return data.map((e) => SubscriptionPlan.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> deletePlan(String id) async {
    await _client.delete('/admin/plans/$id');
  }

  Future<void> createPlan({
    required String name,
    required String slug,
    required double monthlyPrice,
  }) async {
    await _client.post<dynamic>(
      '/admin/plans',
      data: {'name': name, 'slug': slug, 'monthlyPrice': monthlyPrice},
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────

final adminRepositoryProvider = Provider<AdminRepository>((ref) {
  return AdminRepository(ref.watch(apiClientProvider));
});

final adminDashboardProvider = FutureProvider<AdminDashboard>((ref) {
  return ref.watch(adminRepositoryProvider).getDashboard();
});

final adminTenantsProvider = FutureProvider.family<Map<String, dynamic>, int>(
  (ref, page) => ref.watch(adminRepositoryProvider).getTenants(page: page),
);

final adminPlansProvider = FutureProvider<List<SubscriptionPlan>>((ref) {
  return ref.watch(adminRepositoryProvider).getPlans();
});
