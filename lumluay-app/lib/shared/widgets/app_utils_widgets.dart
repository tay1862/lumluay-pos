import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../features/settings/data/settings_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// currencyCodeProvider — reactive default currency from store settings
// ─────────────────────────────────────────────────────────────────────────────
final currencyCodeProvider = FutureProvider<String>((ref) async {
  try {
    final repo = ref.watch(settingsRepositoryProvider);
    final currencies = await repo.getCurrencies();
    return currencies.defaultCurrency;
  } catch (_) {
    return 'THB'; // fallback
  }
});

// ─────────────────────────────────────────────────────────────────────────────
// CurrencyText — format amount by currency code
// ─────────────────────────────────────────────────────────────────────────────
class CurrencyText extends ConsumerWidget {
  const CurrencyText(
    this.amount, {
    super.key,
    this.currency,
    this.style,
    this.showSymbol = true,
  });

  final double amount;
  /// Override currency code. When null, uses [currencyCodeProvider] (store default).
  final String? currency;
  final TextStyle? style;
  final bool showSymbol;

  static String format(double amount, {String currency = 'THB', bool showSymbol = true}) {
    final int decimals = _decimals(currency);
    final symbol = showSymbol ? _symbol(currency) : '';
    final fmt = NumberFormat('#,##0${decimals > 0 ? '.${'0' * decimals}' : ''}', 'en_US');
    return '$symbol${fmt.format(amount)}';
  }

  static int _decimals(String currency) {
    switch (currency.toUpperCase()) {
      case 'LAK':
        return 0;
      case 'THB':
      case 'USD':
      default:
        return 2;
    }
  }

  static String _symbol(String currency) {
    switch (currency.toUpperCase()) {
      case 'THB':
        return '฿';
      case 'LAK':
        return '₭';
      case 'USD':
        return '\$';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = currency ??
        (ref.watch(currencyCodeProvider).maybeWhen(
              data: (c) => c,
              orElse: () => 'THB',
            ) ??
            'THB');
    return Text(
      format(amount, currency: code, showSymbol: showSymbol),
      style: style,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppEmptyState
// ─────────────────────────────────────────────────────────────────────────────
class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(title,
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[600])),
            if (subtitle != null) ...[
              SizedBox(height: 6.h),
              Text(subtitle!,
                  style: TextStyle(fontSize: 13.sp, color: Colors.grey[400]),
                  textAlign: TextAlign.center),
            ],
            if (action != null && actionLabel != null) ...[
              SizedBox(height: 20.h),
              OutlinedButton(onPressed: action, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AppErrorState
// ─────────────────────────────────────────────────────────────────────────────
class AppErrorState extends StatelessWidget {
  const AppErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, size: 48.sp, color: Colors.red[300]),
            SizedBox(height: 12.h),
            Text(message,
                style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                textAlign: TextAlign.center),
            SizedBox(height: 16.h),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
            ),
          ],
        ),
      ),
    );
  }
}
