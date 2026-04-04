import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/features/pos/presentation/widgets/product_grid.dart';
import 'package:lumluay_pos/features/pos/providers/cart_provider.dart';

void main() {
  testWidgets('ProductGrid renders empty state', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1024, 768),
        builder: (_, __) => MaterialApp(
          home: ProductGrid(
            products: const [],
            onAddRequested: (_, __) async {},
          ),
        ),
      ),
    );

    expect(find.text('ไม่มีสินค้า'), findsOneWidget);
  });

  testWidgets('ProductGrid tap triggers add callback', (tester) async {
    ProductItem? tapped;

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1024, 768),
        builder: (_, __) => MaterialApp(
          home: ProductGrid(
            products: const [
              ProductItem(
                id: 'p1',
                name: 'Noodle',
                price: 55,
                categoryId: 'c1',
              ),
            ],
            onAddRequested: (product, _) async {
              tapped = product;
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Noodle'));
    await tester.pumpAndSettle();

    expect(tapped?.id, 'p1');
  });
}
