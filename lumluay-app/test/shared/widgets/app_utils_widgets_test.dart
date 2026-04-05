import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/shared/widgets/app_utils_widgets.dart';

void main() {
  test('CurrencyText.format applies decimals and symbols', () {
    expect(CurrencyText.format(1234.5, currency: 'THB'), '฿1,234.50');
    expect(CurrencyText.format(1234.5, currency: 'LAK'), '₭1,235');
    expect(CurrencyText.format(1234.5, currency: 'USD'), r'$1,234.50');
  });

  testWidgets('AppEmptyState renders title and optional action', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1024, 768),
        builder: (_, __) => const MaterialApp(
          home: Scaffold(
            body: AppEmptyState(
              icon: Icons.inbox,
              title: 'No data',
              actionLabel: 'Retry',
            ),
          ),
        ),
      ),
    );

    expect(find.text('No data'), findsOneWidget);
    expect(find.text('Retry'), findsNothing);
  });

  testWidgets('AppErrorState renders message and retry button', (tester) async {
    var tapped = false;
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(1024, 768),
        builder: (_, __) => MaterialApp(
          home: Scaffold(
            body: AppErrorState(
              message: 'Failed',
              onRetry: () => tapped = true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Failed'), findsOneWidget);
    await tester.tap(find.text('ລອງໃໝ່'));
    await tester.pump();
    expect(tapped, isTrue);
  });
}
