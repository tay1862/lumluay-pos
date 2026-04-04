import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

class KitchenTicket {
  final String id;
  final String orderReceiptNumber;
  final String? tableName;
  final String status;
  final String? station;
  final List<Map<String, dynamic>> items;
  final DateTime createdAt;
  final DateTime? startedAt;

  const KitchenTicket({
    required this.id,
    required this.orderReceiptNumber,
    this.tableName,
    required this.status,
    this.station,
    required this.items,
    required this.createdAt,
    this.startedAt,
  });

  factory KitchenTicket.fromJson(Map<String, dynamic> json) => KitchenTicket(
        id: json['id'] as String,
        orderReceiptNumber: json['orderReceiptNumber'] as String? ?? json['receiptNumber'] as String? ?? '',
        tableName: json['tableName'] as String?,
        status: json['status'] as String,
        station: json['station'] as String?,
        items: (json['items'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
      );

  /// Minutes since ticket was created
  int get waitMinutes => DateTime.now().difference(createdAt).inMinutes;

  bool get isUrgent => waitMinutes >= 15;
}

final kitchenRepositoryProvider = Provider<KitchenRepository>(
  (ref) => KitchenRepository(ref.read(apiClientProvider)),
);

final kitchenTicketsProvider =
    FutureProvider.family<List<KitchenTicket>, String?>((ref, station) async {
  final repo = ref.read(kitchenRepositoryProvider);
  return repo.getPendingTickets(station: station);
});

class KitchenRepository {
  final ApiClient _api;
  KitchenRepository(this._api);

  Future<List<KitchenTicket>> getPendingTickets({String? station}) async {
    return _api.get<List<KitchenTicket>>(
      '/kitchen/tickets',
      queryParameters: station != null ? {'station': station} : null,
      fromJson: (d) => (d as List)
          .map((e) =>
              KitchenTicket.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Future<KitchenTicket> updateStatus(String id, String status) async {
    final path = switch (status) {
      'preparing' => '/kitchen/tickets/$id/preparing',
      'ready' => '/kitchen/tickets/$id/ready',
      'served' => '/kitchen/tickets/$id/served',
      _ => throw ArgumentError('Unknown status: $status'),
    };
    return _api.post<KitchenTicket>(
      path,
      fromJson: (d) =>
          KitchenTicket.fromJson(Map<String, dynamic>.from(d as Map)),
    );
  }
}
