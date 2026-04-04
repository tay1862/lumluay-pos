enum KitchenStatus { pending, preparing, ready, served, cancelled }

class KitchenOrderItem {
  final int quantity;
  final String productName;
  final String? note;

  const KitchenOrderItem({
    required this.quantity,
    required this.productName,
    this.note,
  });

  factory KitchenOrderItem.fromJson(Map<String, dynamic> json) => KitchenOrderItem(
        quantity: (json['quantity'] as num?)?.toInt() ?? 1,
        productName: json['productName'] as String? ?? '',
        note: json['note'] as String?,
      );
}

class KitchenOrder {
  final String id;
  final String orderReceiptNumber;
  final String? tableName;
  final KitchenStatus status;
  final String? station;
  final List<KitchenOrderItem> items;
  final DateTime createdAt;
  final DateTime? startedAt;

  const KitchenOrder({
    required this.id,
    required this.orderReceiptNumber,
    this.tableName,
    required this.status,
    this.station,
    required this.items,
    required this.createdAt,
    this.startedAt,
  });

  factory KitchenOrder.fromJson(Map<String, dynamic> json) => KitchenOrder(
        id: json['id'] as String,
        orderReceiptNumber:
            json['orderReceiptNumber'] as String? ?? json['receiptNumber'] as String? ?? '',
        tableName: json['tableName'] as String?,
        status: _parseStatus(json['status'] as String? ?? 'pending'),
        station: json['station'] as String?,
        items: (json['items'] as List? ?? [])
            .map((e) => KitchenOrderItem.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        createdAt: DateTime.parse(json['createdAt'] as String),
        startedAt: json['startedAt'] != null
            ? DateTime.parse(json['startedAt'] as String)
            : null,
      );

  static KitchenStatus _parseStatus(String value) {
    return switch (value) {
      'preparing' => KitchenStatus.preparing,
      'ready' => KitchenStatus.ready,
      'served' => KitchenStatus.served,
      'cancelled' => KitchenStatus.cancelled,
      _ => KitchenStatus.pending,
    };
  }

  String get statusValue => switch (status) {
        KitchenStatus.pending => 'pending',
        KitchenStatus.preparing => 'preparing',
        KitchenStatus.ready => 'ready',
        KitchenStatus.served => 'served',
        KitchenStatus.cancelled => 'cancelled',
      };

  int get waitMinutes => DateTime.now().difference(createdAt).inMinutes;

  bool get isUrgent => waitMinutes >= 15;
}
