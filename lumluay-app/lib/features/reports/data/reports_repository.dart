import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart' as dio_options;
import '../../../core/network/api_client.dart';

class ReportsSummary {
  final double totalRevenue;
  final int totalOrders;
  final double avgOrderValue;
  final Map<String, dynamic> paymentBreakdown;

  const ReportsSummary({
    required this.totalRevenue,
    required this.totalOrders,
    required this.avgOrderValue,
    required this.paymentBreakdown,
  });

  factory ReportsSummary.fromJson(Map<String, dynamic> j) => ReportsSummary(
        totalRevenue: (j['totalRevenue'] as num?)?.toDouble() ?? 0,
        totalOrders: (j['totalOrders'] as num?)?.toInt() ?? 0,
        avgOrderValue: (j['avgOrderValue'] as num?)?.toDouble() ?? 0,
        paymentBreakdown:
            (j['paymentBreakdown'] as Map<String, dynamic>?) ?? {},
      );
}

class DailyBreakdown {
  final String date;
  final double revenue;
  final int orders;

  const DailyBreakdown(
      {required this.date, required this.revenue, required this.orders});

  factory DailyBreakdown.fromJson(Map<String, dynamic> j) => DailyBreakdown(
        date: j['date'] as String? ?? '',
        revenue: (j['revenue'] as num?)?.toDouble() ?? 0,
        orders: (j['orders'] as num?)?.toInt() ?? 0,
      );
}

class TopProduct {
  final String name;
  final int quantity;
  final double revenue;

  const TopProduct(
      {required this.name, required this.quantity, required this.revenue});

  factory TopProduct.fromJson(Map<String, dynamic> j) => TopProduct(
        name: j['productName'] as String? ?? '',
        quantity: (j['totalQuantity'] as num?)?.toInt() ?? 0,
        revenue: (j['totalRevenue'] as num?)?.toDouble() ?? 0,
      );
}

class ReportsRepository {
  const ReportsRepository(this._api);
  final ApiClient _api;

  Future<ReportsSummary> getSummary(DateTime from, DateTime to) async {
    final resp = await _api.get(
      '/reports/summary',
      queryParameters: {
        'from': _fmt(from),
        'to': _fmt(to),
      },
    );
    return ReportsSummary.fromJson(resp as Map<String, dynamic>);
  }

  Future<List<DailyBreakdown>> getDaily(DateTime from, DateTime to) async {
    final resp = await _api.get(
      '/reports/daily',
      queryParameters: {'from': _fmt(from), 'to': _fmt(to)},
    );
    return (resp as List)
        .map((e) => DailyBreakdown.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TopProduct>> getTopProducts(DateTime from, DateTime to) async {
    final resp = await _api.get(
      '/reports/top-products',
      queryParameters: {'from': _fmt(from), 'to': _fmt(to), 'limit': '10'},
    );
    return (resp as List)
        .map((e) => TopProduct.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 15.2.1 Sales grouped report ────────────────────────────────────────────
  Future<List<SalesReportRow>> getSalesReport(
    DateTime from,
    DateTime to, {
    String groupBy = 'day',
  }) async {
    final data = await _api.get<List<dynamic>>(
      '/reports/sales',
      queryParameters: {
        'from': _fmt(from),
        'to': _fmt(to),
        'groupBy': groupBy,
      },
    );
    return data
        .map((e) => SalesReportRow.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 15.2.1 Products report ─────────────────────────────────────────────────
  Future<List<ProductReport>> getProductsReport(
    DateTime from,
    DateTime to, {
    int limit = 100,
  }) async {
    final data = await _api.get<List<dynamic>>(
      '/reports/products',
      queryParameters: {
        'from': _fmt(from),
        'to': _fmt(to),
        'limit': '$limit',
      },
    );
    return data
        .map((e) => ProductReport.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  // ── 15.2.8 Download export CSV as bytes ──────────────────────────────────
  Future<List<int>> downloadExport(
      DateTime from, DateTime to, String type) async {
    final response = await _api.dio.get<List<int>>(
      '/reports/export',
      queryParameters: {'type': type, 'from': _fmt(from), 'to': _fmt(to)},
      options: dio_options.Options(responseType: dio_options.ResponseType.bytes),
    );
    return response.data ?? [];
  }

  // ── 15.2.8 Export URL builder ──────────────────────────────────────────────
  String exportUrl(DateTime from, DateTime to, String type) {
    final base = _api.dio.options.baseUrl;
    return '$base/reports/export?type=$type&from=${_fmt(from)}&to=${_fmt(to)}';
  }

  String _fmt(DateTime d) => d.toIso8601String().split('T').first;
}

final reportsRepositoryProvider = Provider<ReportsRepository>(
  (ref) => ReportsRepository(ref.watch(apiClientProvider)),
);

final reportsSummaryProvider =
    FutureProvider.family<ReportsSummary, (DateTime, DateTime)>((ref, range) {
  return ref.watch(reportsRepositoryProvider).getSummary(range.$1, range.$2);
});

final reportsDailyProvider =
    FutureProvider.family<List<DailyBreakdown>, (DateTime, DateTime)>(
        (ref, range) {
  return ref.watch(reportsRepositoryProvider).getDaily(range.$1, range.$2);
});

final reportsTopProductsProvider =
    FutureProvider.family<List<TopProduct>, (DateTime, DateTime)>((ref, range) {
  return ref.watch(reportsRepositoryProvider).getTopProducts(range.$1, range.$2);
});

// ─────────────────────────────────────────────────────────────────────────────
// 15.2.1 — Sales report row (grouped by day/week/month)
// ─────────────────────────────────────────────────────────────────────────────
class SalesReportRow {
  final String period;
  final int orderCount;
  final double revenue;
  final double discount;
  final double net;

  const SalesReportRow({
    required this.period,
    required this.orderCount,
    required this.revenue,
    required this.discount,
    required this.net,
  });

  factory SalesReportRow.fromJson(Map<String, dynamic> j) => SalesReportRow(
        period: j['period'] as String? ?? '',
        orderCount: (j['orderCount'] as num?)?.toInt() ?? 0,
        revenue: (j['revenue'] as num?)?.toDouble() ?? 0,
        discount: (j['discount'] as num?)?.toDouble() ?? 0,
        net: (j['net'] as num?)?.toDouble() ?? 0,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 15.2.1 — Product-level report row
// ─────────────────────────────────────────────────────────────────────────────
class ProductReport {
  final int rank;
  final String productId;
  final String productName;
  final String? categoryName;
  final int totalQty;
  final double totalRevenue;
  final int orderCount;

  const ProductReport({
    required this.rank,
    required this.productId,
    required this.productName,
    this.categoryName,
    required this.totalQty,
    required this.totalRevenue,
    required this.orderCount,
  });

  factory ProductReport.fromJson(Map<String, dynamic> j) => ProductReport(
        rank: (j['rank'] as num?)?.toInt() ?? 0,
        productId: j['productId'] as String? ?? '',
        productName: j['productName'] as String? ?? '',
        categoryName: j['categoryName'] as String?,
        totalQty: (j['totalQty'] as num?)?.toInt() ?? 0,
        totalRevenue: (j['totalRevenue'] as num?)?.toDouble() ?? 0,
        orderCount: (j['orderCount'] as num?)?.toInt() ?? 0,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// 15.2.1 — Providers for new report types
// ─────────────────────────────────────────────────────────────────────────────
typedef _DateRange = (DateTime, DateTime);

final reportsSalesProvider =
    FutureProvider.family<List<SalesReportRow>, ({DateTime from, DateTime to, String groupBy})>(
        (ref, params) {
  return ref
      .watch(reportsRepositoryProvider)
      .getSalesReport(params.from, params.to, groupBy: params.groupBy);
});

final reportsProductsProvider =
    FutureProvider.family<List<ProductReport>, _DateRange>((ref, range) {
  return ref
      .watch(reportsRepositoryProvider)
      .getProductsReport(range.$1, range.$2);
});

