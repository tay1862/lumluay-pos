import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────────────
enum QueueStatus { waiting, called, serving, done, cancelled }

class QueueTicket {
  final String id;
  final String ticketNumber;
  final String? customerName;
  final String? phone;
  final int partySize;
  final QueueStatus status;
  final DateTime createdAt;
  final DateTime? calledAt;

  const QueueTicket({
    required this.id,
    required this.ticketNumber,
    this.customerName,
    this.phone,
    required this.partySize,
    required this.status,
    required this.createdAt,
    this.calledAt,
  });

  factory QueueTicket.fromJson(Map<String, dynamic> j) {
    return QueueTicket(
      id: '${j['id']}',
      ticketNumber: '${j['ticketNumber']}',
      customerName:
          j['customerName'] != null ? '${j['customerName']}' : null,
      phone: j['phone'] != null ? '${j['phone']}' : null,
      partySize: int.tryParse('${j['partySize']}') ?? 1,
      status: _parseStatus('${j['status']}'),
      createdAt:
          DateTime.tryParse('${j['createdAt']}') ?? DateTime.now(),
      calledAt: j['calledAt'] != null
          ? DateTime.tryParse('${j['calledAt']}')
          : null,
    );
  }

  static QueueStatus _parseStatus(String s) {
    switch (s) {
      case 'waiting':
        return QueueStatus.waiting;
      case 'called':
        return QueueStatus.called;
      case 'serving':
        return QueueStatus.serving;
      case 'done':
        return QueueStatus.done;
      case 'cancelled':
        return QueueStatus.cancelled;
      default:
        return QueueStatus.waiting;
    }
  }

  String get statusLabel {
    switch (status) {
      case QueueStatus.waiting:
        return 'รอเรียก';
      case QueueStatus.called:
        return 'เรียกแล้ว';
      case QueueStatus.serving:
        return 'กำลังบริการ';
      case QueueStatus.done:
        return 'เสร็จสิ้น';
      case QueueStatus.cancelled:
        return 'ยกเลิก';
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Repository
// ─────────────────────────────────────────────────────────────────────────────
class QueueRepository {
  const QueueRepository(this._client);
  final ApiClient _client;

  Future<List<QueueTicket>> getQueue({QueueStatus? status}) async {
    final params = <String, String>{};
    if (status != null) params['status'] = status.name;
    final data = await _client.get('/queue', queryParameters: params);
    final list = (data as List<dynamic>);
    return list
        .map((e) => QueueTicket.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<QueueTicket> createTicket({
    String? customerName,
    String? phone,
    required int partySize,
  }) async {
    final data = await _client.post('/queue', data: {
      if (customerName != null && customerName.isNotEmpty)
        'customerName': customerName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'partySize': partySize,
    });
    return QueueTicket.fromJson(data as Map<String, dynamic>);
  }

  Future<QueueTicket> callTicket(String id) async {
    final data = await _client.patch('/queue/$id/call', data: {});
    return QueueTicket.fromJson(data as Map<String, dynamic>);
  }

  Future<QueueTicket> serveTicket(String id) async {
    final data = await _client.patch('/queue/$id/serve', data: {});
    return QueueTicket.fromJson(data as Map<String, dynamic>);
  }

  Future<QueueTicket> completeTicket(String id) async {
    final data = await _client.patch('/queue/$id/done', data: {});
    return QueueTicket.fromJson(data as Map<String, dynamic>);
  }

  Future<QueueTicket> cancelTicket(String id) async {
    final data = await _client.patch('/queue/$id/cancel', data: {});
    return QueueTicket.fromJson(data as Map<String, dynamic>);
  }

  /// 14.2.4 — Seat a called ticket: updates status to serving + links tableId
  Future<QueueTicket> seatTicket(String id, String tableId) async {
    final data = await _client.patch('/queue/$id/status', data: {
      'status': 'serving',
      'tableId': tableId,
    });
    return QueueTicket.fromJson(data as Map<String, dynamic>);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────────────────────────────────────
final queueRepositoryProvider = Provider((ref) {
  return QueueRepository(ref.watch(apiClientProvider));
});

final queueStatusFilterProvider =
    StateProvider<QueueStatus?>((ref) => null);

final queueListProvider = FutureProvider((ref) {
  final repo = ref.watch(queueRepositoryProvider);
  final status = ref.watch(queueStatusFilterProvider);
  return repo.getQueue(status: status);
});
