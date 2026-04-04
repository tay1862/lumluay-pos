import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/pos_repository.dart';
import 'cart_provider.dart';

enum OrderActionStatus { idle, loading, success, error }

class OrderState extends Equatable {
  const OrderState({
    this.status = OrderActionStatus.idle,
    this.orderId,
    this.error,
  });

  final OrderActionStatus status;
  final String? orderId;
  final String? error;

  OrderState copyWith({
    OrderActionStatus? status,
    String? orderId,
    String? error,
    bool clearOrderId = false,
    bool clearError = false,
  }) {
    return OrderState(
      status: status ?? this.status,
      orderId: clearOrderId ? null : (orderId ?? this.orderId),
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [status, orderId, error];
}

class OrderBloc extends StateNotifier<OrderState> {
  OrderBloc(this._repo) : super(const OrderState());

  final PosRepository _repo;

  Future<String> createAndConfirm(CartState cart) async {
    state = state.copyWith(
      status: OrderActionStatus.loading,
      clearError: true,
      clearOrderId: true,
    );

    try {
      final order = await _repo.createOrder(cart);
      final orderId = '${order['id']}';
      await _repo.confirmOrder(orderId);
      state = state.copyWith(
        status: OrderActionStatus.success,
        orderId: orderId,
      );
      return orderId;
    } catch (e) {
      state = state.copyWith(
        status: OrderActionStatus.error,
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> holdOrder(String orderId) async {
    state = state.copyWith(status: OrderActionStatus.loading, clearError: true);
    try {
      await _repo.holdOrder(orderId);
      state = state.copyWith(status: OrderActionStatus.success, orderId: orderId);
    } catch (e) {
      state = state.copyWith(status: OrderActionStatus.error, error: e.toString());
      rethrow;
    }
  }

  Future<void> resumeOrder(String orderId) async {
    state = state.copyWith(status: OrderActionStatus.loading, clearError: true);
    try {
      await _repo.resumeOrder(orderId);
      state = state.copyWith(status: OrderActionStatus.success, orderId: orderId);
    } catch (e) {
      state = state.copyWith(status: OrderActionStatus.error, error: e.toString());
      rethrow;
    }
  }

  Future<void> voidOrder(String orderId, {required String reason}) async {
    state = state.copyWith(status: OrderActionStatus.loading, clearError: true);
    try {
      await _repo.voidOrder(orderId, reason: reason);
      state = state.copyWith(status: OrderActionStatus.success, orderId: orderId);
    } catch (e) {
      state = state.copyWith(status: OrderActionStatus.error, error: e.toString());
      rethrow;
    }
  }

  void reset() {
    state = const OrderState();
  }
}

final orderBlocProvider = StateNotifierProvider<OrderBloc, OrderState>((ref) {
  return OrderBloc(ref.read(posRepositoryProvider));
});
