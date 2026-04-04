import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../providers/cart_provider.dart';
import '../../../../shared/widgets/app_utils_widgets.dart';

/// Secondary display screen shown on a customer-facing monitor.
/// Mount this page on a second window or external display.
class CustomerDisplayPage extends ConsumerWidget {
  const CustomerDisplayPage({super.key});

  static const routePath = '/customer-display';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: theme.colorScheme.primary,
            padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 24.w),
            child: Text(
              'LUMLUAY POS',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ── Item list ──────────────────────────────────────────
          Expanded(
            child: cart.items.isEmpty
                ? Center(
                    child: Text(
                      'Welcome!',
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ),
                  )
                : ListView.separated(
                    padding:
                        EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
                    itemCount: cart.items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final item = cart.items[i];
                      return _CartItemRow(item: item);
                    },
                  ),
          ),

          // ── Totals ─────────────────────────────────────────────
          _TotalsPanel(cart: cart),
        ],
      ),
    );
  }
}

class _CartItemRow extends ConsumerWidget {
  final CartItem item;
  const _CartItemRow({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(currencyCodeProvider).maybeWhen(
      data: (c) => c, orElse: () => 'THB');
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '${item.quantity}x  ${item.productName}',
              style: theme.textTheme.titleMedium,
            ),
          ),
          Text(
            CurrencyText.format(item.lineTotal, currency: currencyCode),
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _TotalsPanel extends ConsumerWidget {
  final CartState cart;
  const _TotalsPanel({required this.cart});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyCode = ref.watch(currencyCodeProvider).maybeWhen(
      data: (c) => c, orElse: () => 'THB');
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      color: theme.colorScheme.primaryContainer,
      padding: EdgeInsets.all(20.r),
      child: Column(
        children: [
          if (cart.discountAmount > 0) ...[
            _buildRow('Subtotal', cart.subtotal, theme, currencyCode),
            _buildRow('Discount', -cart.discountAmount, theme, currencyCode, isNegative: true),
          ],
          _buildRow(
            'TOTAL',
            cart.total,
            theme,
            currencyCode,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildRow(String label, double amount, ThemeData theme, String currency,
      {bool isTotal = false, bool isNegative = false}) {
    final style = isTotal
        ? theme.textTheme.headlineMedium
            ?.copyWith(fontWeight: FontWeight.bold, fontSize: 32.sp)
        : theme.textTheme.titleLarge;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(
            '${isNegative ? "-" : ""}${CurrencyText.format(amount.abs(), currency: currency)}',
            style: style,
          ),
        ],
      ),
    );
  }
}
