import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/core/config/app_env.dart';
import 'package:lumluay_pos/core/network/api_client.dart';
import 'package:lumluay_pos/features/pos/providers/cart_provider.dart';
import 'package:lumluay_pos/features/pos/presentation/widgets/payment_panel.dart';
import 'package:lumluay_pos/features/settings/data/settings_repository.dart';

class FakeSettingsRepository extends SettingsRepository {
  FakeSettingsRepository()
      : super(ApiClient(const AppEnv(
          flavor: AppFlavor.dev,
          apiBaseUrl: 'http://localhost',
          wsBaseUrl: 'http://localhost',
        )));

  @override
  Future<CurrencySettings> getCurrencies() async {
    return const CurrencySettings(
      defaultCurrency: 'THB',
      enabledCurrencies: ['THB'],
      decimals: {'THB': 2},
      exchangeRates: {'THB': 1},
    );
  }
}

void main() {
  testWidgets('PaymentPanel shows payment header and total', (tester) async {
    final cart = CartState(
      items: const [
        CartItem(productId: 'p1', productName: 'Tea', unitPrice: 35, quantity: 2),
      ],
    );

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1024, 768),
        builder: (_, __) => ProviderScope(
          overrides: [
            settingsRepositoryProvider.overrideWith((ref) => FakeSettingsRepository()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: PaymentPanel(
                cart: cart,
                onClose: () {},
              ),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('ชำระเงิน'), findsOneWidget);
    expect(find.text('ยอดรวมบิล'), findsOneWidget);
    expect(find.text('คงเหลือ'), findsOneWidget);
  });
}
