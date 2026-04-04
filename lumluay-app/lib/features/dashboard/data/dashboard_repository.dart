import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────
class DashboardSummary {
  final double todayRevenue;
  final int orderCount;
  final double avgOrderValue;
  final int openOrders;
  final double revenueGrowth; // % vs yesterday

  const DashboardSummary({
    required this.todayRevenue,
    required this.orderCount,
    required this.avgOrderValue,
    required this.openOrders,
    required this.revenueGrowth,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> j) {
    return DashboardSummary(
      todayRevenue: double.tryParse('${j['totalRevenue']}') ?? 0,
      orderCount: int.tryParse('${j['orderCount']}') ?? 0,
      avgOrderValue: double.tryParse('${j['avgOrderValue']}') ?? 0,
      openOrders: int.tryParse('${j['openOrders']}') ?? 0,
      revenueGrowth: double.tryParse('${j['revenueGrowth']}') ?? 0,
    );
  }
}

class HourlySale {
  final int hour;
  final double revenue;

  const HourlySale({required this.hour, required this.revenue});

  factory HourlySale.fromJson(Map<String, dynamic> j) {
    return HourlySale(
      hour: int.tryParse('${j['hour']}') ?? 0,
      revenue: double.tryParse('${j['revenue']}') ?? 0,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────
class DashboardRepository {
  const DashboardRepository(this._client);
  final ApiClient _client;

  Future<DashboardSummary> getSummary() async {
    final today = DateTime.now();
    final dateStr =
        '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
    final data = await _client.get('/reports/summary', queryParameters: {
      'from': dateStr,
      'to': dateStr,
    });
    return DashboardSummary.fromJson(data as Map<String, dynamic>);
  }

  Future<List<HourlySale>> getHourlySales() async {
    final data = await _client.get('/reports/hourly');
    final list = data as List<dynamic>;
    return list.map((e) => HourlySale.fromJson(e as Map<String, dynamic>)).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final dashboardRepositoryProvider = Provider((ref) {
  return DashboardRepository(ref.watch(apiClientProvider));
});

final dashboardSummaryProvider = FutureProvider((ref) {
  return ref.watch(dashboardRepositoryProvider).getSummary();
});

final hourlyProvider = FutureProvider((ref) {
  return ref.watch(dashboardRepositoryProvider).getHourlySales();
});
