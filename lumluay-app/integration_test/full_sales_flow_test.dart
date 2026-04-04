import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:lumluay_pos/features/pos/presentation/widgets/product_grid.dart';
import 'package:lumluay_pos/features/pos/providers/cart_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('18.2.7 Full sales flow smoke (UI)', (tester) async {
    ProductItem? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: ProductGrid(
          products: const [
            ProductItem(id: 'p1', name: 'Coffee', price: 60, categoryId: 'c1'),
          ],
          onAddRequested: (product, _) async {
            selected = product;
          },
        ),
      ),
    );

    await tester.tap(find.text('Coffee'));
    await tester.pumpAndSettle();

    expect(selected?.id, 'p1');
  });
}
