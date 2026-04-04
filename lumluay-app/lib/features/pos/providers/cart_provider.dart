import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Domain models (lightweight, for UI state)
// ─────────────────────────────────────────────────────────────────────────────

class ProductItem extends Equatable {
  final String id;
  final String name;
  final String? imageUrl;
  final double price;
  final String? sku;
  final String? barcode;
  final String productType;
  final String categoryId;
  final bool isAvailable;

  const ProductItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    this.sku,
    this.barcode,
    this.productType = 'simple',
    required this.categoryId,
    this.isAvailable = true,
  });

  factory ProductItem.fromJson(Map<String, dynamic> json) => ProductItem(
        id: json['id'] as String,
        name: json['name'] as String,
        imageUrl: json['imageUrl'] as String?,
        price: ((json['price'] ?? json['basePrice']) as num).toDouble(),
        sku: json['sku'] as String?,
        barcode: (json['barcode'] ?? json['barCode']) as String?,
        productType: '${json['productType'] ?? 'simple'}',
        categoryId: '${json['categoryId'] ?? json['category']?['id'] ?? ''}',
        isAvailable: json['isAvailable'] as bool? ?? true,
      );

  bool get isOpenPrice => productType == 'open_price';

  ProductItem copyWith({
    double? price,
  }) {
    return ProductItem(
      id: id,
      name: name,
      imageUrl: imageUrl,
      price: price ?? this.price,
      sku: sku,
      barcode: barcode,
      productType: productType,
      categoryId: categoryId,
      isAvailable: isAvailable,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        price,
        sku,
        barcode,
        productType,
        categoryId,
        isAvailable,
      ];
}

class CartItem extends Equatable {
  final String productId;
  final String productName;
  final double unitPrice;
  final int quantity;
  final String? note;

  const CartItem({
    required this.productId,
    required this.productName,
    required this.unitPrice,
    this.quantity = 1,
    this.note,
  });

  double get lineTotal => unitPrice * quantity;

  CartItem copyWith({int? quantity, String? note}) => CartItem(
        productId: productId,
        productName: productName,
        unitPrice: unitPrice,
        quantity: quantity ?? this.quantity,
        note: note ?? this.note,
      );

  @override
  List<Object?> get props => [productId, quantity, note];
}

// ─────────────────────────────────────────────────────────────────────────────
// Cart state
// ─────────────────────────────────────────────────────────────────────────────

class CartState extends Equatable {
  final List<CartItem> items;
  final double discountAmount;
  final String? couponCode;
  final String? tableId;
  final String? tableName;
  final String orderType; // 'dine_in' | 'takeaway' | 'delivery'
  final String? memberId;
  final String? memberName;

  const CartState({
    this.items = const [],
    this.discountAmount = 0,
    this.couponCode,
    this.tableId,
    this.tableName,
    this.orderType = 'dine_in',
    this.memberId,
    this.memberName,
  });

  double get subtotal =>
      items.fold(0, (sum, item) => sum + item.lineTotal);

  double get total => (subtotal - discountAmount).clamp(0, double.maxFinite);

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => items.isEmpty;

  CartState copyWith({
    List<CartItem>? items,
    double? discountAmount,
    String? couponCode,
    String? tableId,
    String? tableName,
    String? orderType,
    Object? memberId = _sentinel,
    Object? memberName = _sentinel,
  }) =>
      CartState(
        items: items ?? this.items,
        discountAmount: discountAmount ?? this.discountAmount,
        couponCode: couponCode ?? this.couponCode,
        tableId: tableId ?? this.tableId,
        tableName: tableName ?? this.tableName,
        orderType: orderType ?? this.orderType,
        memberId: memberId == _sentinel ? this.memberId : memberId as String?,
        memberName:
            memberName == _sentinel ? this.memberName : memberName as String?,
      );

  @override
  List<Object?> get props =>
      [items, discountAmount, couponCode, tableId, orderType, memberId];
}

// Sentinel value for nullable copyWith fields
const _sentinel = Object();

// ─────────────────────────────────────────────────────────────────────────────
// Cart notifier
// ─────────────────────────────────────────────────────────────────────────────

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (_) => CartNotifier(),
);

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState());

  void addItem(ProductItem product) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere(
        (i) => i.productId == product.id && i.note == null);
    if (idx >= 0) {
      items[idx] = items[idx].copyWith(quantity: items[idx].quantity + 1);
    } else {
      items.add(CartItem(
        productId: product.id,
        productName: product.name,
        unitPrice: product.price,
      ));
    }
    state = state.copyWith(items: items);
  }

  /// Add a fully configured [CartItem] (from ModifierDialog).
  void addCartItem(CartItem item) {
    final items = List<CartItem>.from(state.items);
    // Match by productId + note to avoid merging items with different modifiers
    final idx = items.indexWhere(
        (i) => i.productId == item.productId &&
            i.unitPrice == item.unitPrice &&
            i.note == item.note);
    if (idx >= 0) {
      items[idx] =
          items[idx].copyWith(quantity: items[idx].quantity + item.quantity);
    } else {
      items.add(item);
    }
    state = state.copyWith(items: items);
  }

  void removeItem(String productId) {
    final items = List<CartItem>.from(state.items);
    final idx = items.indexWhere((i) => i.productId == productId);
    if (idx >= 0) {
      if (items[idx].quantity > 1) {
        items[idx] = items[idx].copyWith(quantity: items[idx].quantity - 1);
      } else {
        items.removeAt(idx);
      }
    }
    state = state.copyWith(items: items);
  }

  void deleteItem(String productId) {
    final items = state.items.where((i) => i.productId != productId).toList();
    state = state.copyWith(items: items);
  }

  void setDiscount(double amount) {
    state = state.copyWith(discountAmount: amount);
  }

  void setTable(String id, String name) {
    state = state.copyWith(tableId: id, tableName: name);
  }

  void setOrderType(String type) {
    state = state.copyWith(orderType: type);
  }

  void setMember(String id, String name) {
    state = state.copyWith(memberId: id, memberName: name);
  }

  void clearMember() {
    state = state.copyWith(memberId: null, memberName: null);
  }

  void clear() {
    state = const CartState();
  }
}
