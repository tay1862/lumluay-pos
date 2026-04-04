import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/features/pos/data/pos_repository.dart';
import 'package:lumluay_pos/features/pos/providers/cart_provider.dart';
import 'package:lumluay_pos/features/pos/providers/order_bloc.dart';
import 'package:mocktail/mocktail.dart';

class MockPosRepository extends Mock implements PosRepository {}

void main() {
  setUpAll(() {
    registerFallbackValue(const CartState(items: []));
  });

  test('OrderBloc createAndConfirm sets success state', () async {
    final repository = MockPosRepository();
    when(() => repository.createOrder(any())).thenAnswer((_) async => {'id': 'o1'});
    when(() => repository.confirmOrder(any())).thenAnswer((_) async {});

    final bloc = OrderBloc(repository);

    final cart = CartState(
      items: const [
        CartItem(productId: 'p1', productName: 'Tea', unitPrice: 30, quantity: 1),
      ],
    );

    final orderId = await bloc.createAndConfirm(cart);

    expect(orderId, 'o1');
    expect(bloc.state.status, OrderActionStatus.success);
    expect(bloc.state.orderId, 'o1');
  });
}
