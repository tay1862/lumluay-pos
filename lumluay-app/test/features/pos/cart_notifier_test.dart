import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/features/pos/providers/cart_provider.dart';

void main() {
  test('CartNotifier add/remove/clear flow', () {
    final notifier = CartNotifier();

    const product = ProductItem(
      id: 'p1',
      name: 'Noodle',
      price: 50,
      categoryId: 'c1',
    );

    notifier.addItem(product);
    notifier.addItem(product);

    expect(notifier.state.itemCount, 2);
    expect(notifier.state.subtotal, 100);

    notifier.removeItem('p1');
    expect(notifier.state.itemCount, 1);

    notifier.clear();
    expect(notifier.state.isEmpty, isTrue);
  });
}
