import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

enum TableStatus { available, occupied, reserved, cleaning, unknown }

class ZoneModel {
  final String id;
  final String name;
  final String? description;
  final int sortOrder;
  final bool isActive;

  const ZoneModel({
    required this.id,
    required this.name,
    this.description,
    required this.sortOrder,
    required this.isActive,
  });

  factory ZoneModel.fromJson(Map<String, dynamic> j) => ZoneModel(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        description: j['description'] as String?,
        sortOrder: (j['sortOrder'] as num?)?.toInt() ?? 0,
        isActive: j['isActive'] as bool? ?? true,
      );
}

class TableModel {
  final String id;
  final String name;
  final String? zoneId;
  final int seats;
  final TableStatus status;
  final String rawStatus;
  final String? currentOrderId;
  final double? currentOrderTotal;
  final DateTime? occupiedSince;

  const TableModel({
    required this.id,
    required this.name,
    this.zoneId,
    required this.seats,
    required this.status,
    required this.rawStatus,
    this.currentOrderId,
    this.currentOrderTotal,
    this.occupiedSince,
  });

  static TableStatus _statusFromText(String value) {
    switch (value) {
      case 'available':
        return TableStatus.available;
      case 'occupied':
        return TableStatus.occupied;
      case 'reserved':
        return TableStatus.reserved;
      case 'cleaning':
        return TableStatus.cleaning;
      default:
        return TableStatus.unknown;
    }
  }

  factory TableModel.fromJson(Map<String, dynamic> j) => TableModel(
        id: j['id'] as String,
        name: j['name'] as String? ?? '',
        zoneId: j['zoneId'] as String?,
        seats: (j['capacity'] as num?)?.toInt() ?? (j['seats'] as num?)?.toInt() ?? 4,
        status: _statusFromText(j['status'] as String? ?? 'available'),
        rawStatus: j['status'] as String? ?? 'available',
        currentOrderId: j['currentOrderId'] as String?,
        currentOrderTotal:
            (j['currentOrderTotal'] as num?)?.toDouble(),
        occupiedSince: j['occupiedSince'] != null
            ? DateTime.tryParse(j['occupiedSince'] as String)
            : null,
      );
}

class TablesRepository {
  TablesRepository(this._api);
  final ApiClient _api;

  List<ZoneModel>? _zonesCache;
  final Map<String, List<TableModel>> _tablesCache = {};

  Future<List<Map<String, dynamic>>> _getActiveOrders() async {
    final data = await _api.get<List<dynamic>>(
      '/orders',
      queryParameters: {
        'status': 'open,held,preparing,ready,served',
        'limit': '500',
      },
    );
    return data
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  List<TableModel> _joinOrders(
    List<TableModel> tables,
    List<Map<String, dynamic>> orders,
  ) {
    final byTable = <String, Map<String, dynamic>>{};
    for (final order in orders) {
      final tableId = order['tableId']?.toString();
      if (tableId == null || tableId.isEmpty) continue;
      byTable[tableId] ??= order;
    }

    return tables.map((table) {
      final order = byTable[table.id];
      if (order == null) return table;
      return TableModel(
        id: table.id,
        name: table.name,
        zoneId: table.zoneId,
        seats: table.seats,
        status: TableStatus.occupied,
        rawStatus: 'occupied',
        currentOrderId: order['id']?.toString(),
        currentOrderTotal: double.tryParse('${order['totalAmount'] ?? 0}'),
        occupiedSince: DateTime.tryParse('${order['createdAt'] ?? ''}'),
      );
    }).toList();
  }

  Future<List<ZoneModel>> getZones({bool forceRefresh = false}) async {
    if (!forceRefresh && _zonesCache != null) return _zonesCache!;
    final raw = await _api.get<List<dynamic>>('/tables/zones');
    final data = raw
        .map((e) => ZoneModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
    _zonesCache = data;
    return data;
  }

  Future<List<TableModel>> getTables({String? zoneId, bool forceRefresh = false}) async {
    final key = zoneId ?? 'all';
    if (!forceRefresh && _tablesCache[key] != null) return _tablesCache[key]!;

    final data = await _api.get<List<dynamic>>(
      '/tables',
      queryParameters: {if (zoneId != null) 'zoneId': zoneId},
    );
    final base = data
        .map((e) => TableModel.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();

    final orders = await _getActiveOrders();
    final hydrated = _joinOrders(base, orders);
    _tablesCache[key] = hydrated;
    return hydrated;
  }

  Future<Map<String, dynamic>> updateStatus(String tableId, String status) async {
    final result = await _api.patch<Map<String, dynamic>>(
      '/tables/$tableId/status',
      data: {'status': status},
    );
    invalidateCache();
    return result;
  }

  Future<Map<String, dynamic>> moveTable({
    required String sourceTableId,
    required String targetTableId,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/tables/$sourceTableId/move',
      data: {'targetTableId': targetTableId},
    );
    invalidateCache();
    return result;
  }

  Future<Map<String, dynamic>> mergeTables({
    required String targetTableId,
    required List<String> mergeTableIds,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/tables/$targetTableId/merge',
      data: {'mergeTableIds': mergeTableIds},
    );
    invalidateCache();
    return result;
  }

  Future<Map<String, dynamic>> splitTable({
    required String sourceTableId,
    required String targetTableId,
    required List<String> orderItemIds,
  }) async {
    final result = await _api.post<Map<String, dynamic>>(
      '/tables/$sourceTableId/split',
      data: {
        'targetTableId': targetTableId,
        'orderItemIds': orderItemIds,
      },
    );
    invalidateCache();
    return result;
  }

  Future<Map<String, dynamic>> getTableQrCode(String tableId) {
    return _api.get<Map<String, dynamic>>('/tables/$tableId/qr-code');
  }

  Future<ZoneModel> createZone({
    required String name,
    String? description,
    int sortOrder = 0,
  }) async {
    final data = await _api.post<Map<String, dynamic>>(
      '/tables/zones',
      data: {
        'name': name,
        'description': description,
        'sortOrder': sortOrder,
      },
    );
    invalidateCache();
    return ZoneModel.fromJson(data);
  }

  Future<ZoneModel> updateZone({
    required String id,
    String? name,
    String? description,
    int? sortOrder,
  }) async {
    final data = await _api.patch<Map<String, dynamic>>(
      '/tables/zones/$id',
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (sortOrder != null) 'sortOrder': sortOrder,
      },
    );
    invalidateCache();
    return ZoneModel.fromJson(data);
  }

  Future<void> deleteZone(String id) async {
    await _api.delete('/tables/zones/$id');
    invalidateCache();
  }

  Future<List<Map<String, dynamic>>> getOrderItems(String orderId) async {
    final order = await _api.get<Map<String, dynamic>>('/orders/$orderId');
    final items = order['items'] as List? ?? const [];
    return items
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
  }

  Future<Map<String, dynamic>?> getActiveOrderByTableId(String tableId) async {
    final orders = await _getActiveOrders();
    for (final order in orders) {
      if ('${order['tableId']}' == tableId) {
        return order;
      }
    }
    return null;
  }

  void invalidateCache() {
    _zonesCache = null;
    _tablesCache.clear();
  }
}

final tablesRepositoryProvider = Provider<TablesRepository>(
  (ref) => TablesRepository(ref.watch(apiClientProvider)),
);

final zonesProvider = FutureProvider<List<ZoneModel>>((ref) {
  return ref.watch(tablesRepositoryProvider).getZones();
});

final selectedZoneIdProvider = StateProvider<String?>((ref) => null);

final tableReloadSeedProvider = StateProvider<int>((ref) => 0);

final tablesProvider = FutureProvider.family<List<TableModel>, String?>(
    (ref, zoneId) {
  ref.watch(tableReloadSeedProvider);
  return ref.watch(tablesRepositoryProvider).getTables(zoneId: zoneId);
});
