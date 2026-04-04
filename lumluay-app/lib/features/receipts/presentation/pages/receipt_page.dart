import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/receipts_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Receipt Page
// Shows the receipt for a completed order; supports reprint.
// ─────────────────────────────────────────────────────────────────────────────

class ReceiptPage extends ConsumerWidget {
  const ReceiptPage({super.key, required this.orderId});

  final String orderId;

  static const routePath = '/receipt/:orderId';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final receiptAsync = ref.watch(receiptProvider(orderId));
    final theme = Theme.of(context);
    final currFmt = NumberFormat('#,##0.00', 'en_US');

    return Scaffold(
      appBar: AppBar(
        title: const Text('ใบเสร็จ'),
        actions: [
          receiptAsync.whenData((r) => IconButton(
                icon: const Icon(Icons.print),
                tooltip: 'พิมพ์ใบเสร็จ',
                onPressed: () {
                  // TODO: trigger printer service
                },
              )).value ??
              const SizedBox.shrink(),
        ],
      ),
      body: receiptAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('ไม่พบใบเสร็จ: $e')),
        data: (receipt) => SingleChildScrollView(
          padding: EdgeInsets.all(24.w),
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: 400.w),
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        receipt.receiptNumber,
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        DateFormat('dd/MM/yyyy HH:mm').format(receipt.createdAt),
                        style: theme.textTheme.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                      const Divider(height: 32),
                      _receiptRow('ยอดรวม', '฿${currFmt.format(receipt.subtotal)}', theme),
                      if (receipt.discountAmount > 0)
                        _receiptRow(
                          'ส่วนลด',
                          '-฿${currFmt.format(receipt.discountAmount)}',
                          theme,
                          isNegative: true,
                        ),
                      if (receipt.taxAmount > 0)
                        _receiptRow('ภาษี', '฿${currFmt.format(receipt.taxAmount)}', theme),
                      if (receipt.serviceCharge > 0)
                        _receiptRow('ค่าบริการ', '฿${currFmt.format(receipt.serviceCharge)}', theme),
                      const Divider(height: 24),
                      _receiptRow(
                        'รวมทั้งหมด',
                        '฿${currFmt.format(receipt.total)}',
                        theme,
                        isTotal: true,
                      ),
                      SizedBox(height: 16.h),
                      _receiptRow(
                        'วิธีชำระ',
                        _paymentLabel(receipt.paymentMethod),
                        theme,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _receiptRow(
    String label,
    String value,
    ThemeData theme, {
    bool isTotal = false,
    bool isNegative = false,
  }) {
    final style = isTotal
        ? theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)
        : theme.textTheme.bodyMedium;
    final valueStyle = isNegative
        ? style?.copyWith(color: Colors.red)
        : style;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }

  String _paymentLabel(String method) {
    switch (method) {
      case 'cash':
        return 'เงินสด';
      case 'card':
        return 'บัตรเครดิต';
      case 'qr':
        return 'QR Code';
      default:
        return method;
    }
  }
}
