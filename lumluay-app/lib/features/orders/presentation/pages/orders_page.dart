import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../data/orders_repository.dart';
import '../widgets/order_card.dart';

class OrdersPage extends ConsumerWidget {
  const OrdersPage({super.key});

  static const _statuses = [
    ('all', 'ทั้งหมด'),
    ('open', 'เปิด'),
    ('completed', 'เสร็จ'),
    ('held', 'พัก'),
    ('voided', 'ยกเลิก'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusFilter = ref.watch(ordersStatusFilterProvider);
    final ordersAsync = ref.watch(ordersListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ประวัติออเดอร์'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(ordersListProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: SizedBox(
            height: 48.h,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 6.h),
              children: _statuses.map((s) {
                return Padding(
                  padding: EdgeInsets.only(right: 6.w),
                  child: FilterChip(
                    label: Text(s.$2),
                    selected: statusFilter == s.$1,
                    onSelected: (_) => ref
                        .read(ordersStatusFilterProvider.notifier)
                        .state = s.$1,
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (orders) {
          if (orders.isEmpty) {
            return const Center(
              child: Text('ไม่มีออเดอร์',
                  style: TextStyle(color: Colors.black54)),
            );
          }
          return ListView.separated(
            itemCount: orders.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (ctx, i) =>
                OrderCard(order: orders[i]),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order detail page
// ─────────────────────────────────────────────────────────────────────────────
class OrderDetailPage extends ConsumerWidget {
  const OrderDetailPage({super.key, required this.orderId});
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(orderDetailProvider(orderId));
    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดออเดอร์'),
        actions: [
          // ── 15.3.4 Reprint ────────────────────────────────────────────
          detailAsync.whenOrNull(
            data: (order) => IconButton(
              icon: const Icon(Icons.print_outlined),
              tooltip: 'พิมพ์ใหม่',
              onPressed: () => _printReceipt(context, order),
            ),
          ) ??
              const SizedBox.shrink(),
        ],
      ),
      body: detailAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (order) => _OrderDetailBody(order: order, orderId: orderId),
      ),
    );
  }

  Future<void> _printReceipt(BuildContext context, OrderDetail order) async {
    final fmtMoney = NumberFormat('#,##0.00', 'en_US');
    await Printing.layoutPdf(
      onLayout: (format) async {
        final doc = pw.Document();
        doc.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.roll80,
            build: (ctx) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Center(
                  child: pw.Text('ใบเสร็จ',
                      style: pw.TextStyle(
                          fontSize: 18,
                          fontWeight: pw.FontWeight.bold)),
                ),
                pw.SizedBox(height: 4),
                pw.Text('เลขที่: ${order.receiptNumber}'),
                pw.Text(
                    'วันที่: ${DateFormat('dd/MM/yyyy HH:mm').format(order.createdAt)}'),
                if (order.tableName != null)
                  pw.Text('โต๊ะ: ${order.tableName}'),
                pw.Divider(),
                ...order.items.map(
                  (item) => pw.Row(
                    mainAxisAlignment:
                        pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Expanded(
                          child: pw.Text(
                              '${item.quantity}× ${item.productName}')),
                      pw.Text('฿${fmtMoney.format(item.lineTotal)}'),
                    ],
                  ),
                ),
                pw.Divider(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('รวม',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold)),
                    pw.Text('฿${fmtMoney.format(order.totalAmount)}',
                        style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        );
        return doc.save();
      },
    );
  }
}

class _OrderDetailBody extends ConsumerWidget {
  const _OrderDetailBody({required this.order, required this.orderId});
  final OrderDetail order;
  final String orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmtMoney = NumberFormat('#,##0.00', 'en_US');
    final fmtTime = DateFormat('d MMM yyyy HH:mm');

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // Header card
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      order.receiptNumber,
                      style: TextStyle(
                          fontSize: 20.sp, fontWeight: FontWeight.w800),
                    ),
                    const Spacer(),
                    _StatusBadge(status: order.status),
                  ],
                ),
                SizedBox(height: 8.h),
                if (order.tableName != null)
                  _InfoRow(label: 'โต๊ะ', value: order.tableName!),
                if (order.memberName != null)
                  _InfoRow(label: 'สมาชิก', value: order.memberName!),
                _InfoRow(label: 'เวลา', value: fmtTime.format(order.createdAt)),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Items
        Text('รายการ',
            style: TextStyle(
                fontSize: 15.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 6.h),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: order.items.length,
            separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 16, endIndent: 16),
            itemBuilder: (ctx, i) {
              final item = order.items[i];
              return ListTile(
                dense: true,
                title: Text(
                  '${item.quantity}× ${item.productName}'
                  '${item.variantName != null ? ' (${item.variantName})' : ''}',
                  style: TextStyle(fontSize: 13.sp),
                ),
                subtitle: item.note != null
                    ? Text(item.note!,
                        style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.black54,
                            fontStyle: FontStyle.italic))
                    : null,
                trailing: Text('฿${fmtMoney.format(item.lineTotal)}',
                    style: TextStyle(
                        fontSize: 13.sp, fontWeight: FontWeight.w600)),
              );
            },
          ),
        ),
        SizedBox(height: 12.h),

        // Totals
        Card(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              children: [
                _TotalRow(label: 'ยอดรวมก่อนส่วนลด',
                    value: '฿${fmtMoney.format(order.subtotal)}'),
                if (order.discountAmount > 0)
                  _TotalRow(
                      label: 'ส่วนลด',
                      value: '-฿${fmtMoney.format(order.discountAmount)}',
                      valueColor: Colors.red),
                if (order.taxAmount > 0)
                  _TotalRow(
                      label: 'ภาษี',
                      value: '฿${fmtMoney.format(order.taxAmount)}'),
                if (order.serviceChargeAmount > 0)
                  _TotalRow(
                      label: 'ค่าบริการ',
                      value:
                          '฿${fmtMoney.format(order.serviceChargeAmount)}'),
                const Divider(),
                _TotalRow(
                    label: 'ยอดสุทธิ',
                    value: '฿${fmtMoney.format(order.totalAmount)}',
                    bold: true),
              ],
            ),
          ),
        ),

        // Payments
        if (order.payments.isNotEmpty) ...[
          SizedBox(height: 12.h),
          Text('การชำระเงิน',
              style: TextStyle(
                  fontSize: 15.sp, fontWeight: FontWeight.w700)),
          SizedBox(height: 6.h),
          Card(
            child: ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: order.payments.length,
              itemBuilder: (ctx, i) {
                final p = order.payments[i];
                return ListTile(
                  dense: true,
                  leading:
                      Icon(_methodIcon(p['method'] as String? ?? ''),
                          size: 18.sp),
                  title: Text(_methodLabel(p['method'] as String? ?? ''),
                      style: TextStyle(fontSize: 13.sp)),
                  trailing: Text(
                      '฿${fmtMoney.format((p['amount'] as num?)?.toDouble() ?? 0)}',
                      style: TextStyle(
                          fontSize: 13.sp, fontWeight: FontWeight.w600)),
                );
              },
            ),
          ),
        ],

        // ── 15.3.5 Refund button (completed orders only) ─────────────────
        if (order.status == 'completed') ...[
          SizedBox(height: 20.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.undo_rounded, color: Colors.red),
              label: const Text('คืนเงิน / Refund',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: EdgeInsets.symmetric(vertical: 12.h),
              ),
              onPressed: () => _showRefundDialog(context, ref),
            ),
          ),
          SizedBox(height: 16.h),
        ],
      ],
    );
  }

  void _showRefundDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (_) => _RefundDialog(orderId: orderId, ref: ref),
    );
  }

  IconData _methodIcon(String method) => switch (method) {
        'qr_promptpay' => Icons.qr_code,
        'card' => Icons.credit_card,
        'transfer' => Icons.account_balance,
        'wallet' => Icons.account_balance_wallet,
        _ => Icons.payments,
      };

  String _methodLabel(String method) => switch (method) {
        'cash' => 'เงินสด',
        'qr_promptpay' => 'QR PromptPay',
        'card' => 'บัตร',
        'transfer' => 'โอน',
        'wallet' => 'Wallet',
        _ => method,
      };
}

// ─────────────────────────────────────────────────────────────────────────────
// 15.3.5 — Refund dialog
// ─────────────────────────────────────────────────────────────────────────────
class _RefundDialog extends ConsumerStatefulWidget {
  const _RefundDialog({required this.orderId, required this.ref});
  final String orderId;
  final WidgetRef ref;

  @override
  ConsumerState<_RefundDialog> createState() => _RefundDialogState();
}

class _RefundDialogState extends ConsumerState<_RefundDialog> {
  final _reasonCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    try {
      final amount = double.tryParse(_amountCtrl.text.trim());
      await widget.ref
          .read(ordersRepositoryProvider)
          .refundOrder(widget.orderId,
              amount: amount, reason: _reasonCtrl.text.trim());
      widget.ref.invalidate(orderDetailProvider(widget.orderId));
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('คืนเงินสำเร็จ')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('คืนเงิน'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _reasonCtrl,
            decoration: const InputDecoration(labelText: 'เหตุผล'),
            maxLines: 2,
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _amountCtrl,
            decoration: const InputDecoration(
                labelText: 'จำนวนเงิน (เว้นว่างเพื่อคืนเต็ม)'),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: const Text('ยกเลิก')),
        FilledButton(
          onPressed: _loading ? null : _submit,
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: _loading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2))
              : const Text('ยืนยันคืนเงิน'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────
class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (status) {
      'completed' => (Colors.green, 'เสร็จ'),
      'voided' => (Colors.red, 'ยกเลิก'),
      'held' => (Colors.orange, 'พัก'),
      'open' => (Colors.blue, 'เปิด'),
      _ => (Colors.grey, status),
    };
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(label,
          style: TextStyle(
              color: color,
              fontSize: 12.sp,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 2.h),
        child: Row(
          children: [
            Text('$label: ',
                style: TextStyle(
                    fontSize: 12.sp, color: Colors.black54)),
            Text(value,
                style: TextStyle(
                    fontSize: 12.sp, fontWeight: FontWeight.w500)),
          ],
        ),
      );
}

class _TotalRow extends StatelessWidget {
  const _TotalRow(
      {required this.label,
      required this.value,
      this.bold = false,
      this.valueColor});
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.symmetric(vertical: 3.h),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight:
                          bold ? FontWeight.w700 : FontWeight.normal)),
            ),
            Text(
              value,
              style: TextStyle(
                  fontSize: 13.sp,
                  fontWeight:
                      bold ? FontWeight.w800 : FontWeight.w500,
                  color: valueColor),
            ),
          ],
        ),
      );
}
