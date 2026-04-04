import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/orders_repository.dart';
import '../pages/orders_page.dart';

/// 15.3.2 — Public OrderCard extracted from orders_page.dart.
/// Can be reused in dashboard, search results, etc.
class OrderCard extends ConsumerWidget {
  const OrderCard({super.key, required this.order});
  final OrderSummary order;

  (Color, String) _statusStyle() => switch (order.status) {
        'completed' => (Colors.green, 'เสร็จ'),
        'voided' => (Colors.red, 'ยกเลิก'),
        'held' => (Colors.orange, 'พัก'),
        'open' => (Colors.blue, 'เปิด'),
        _ => (Colors.grey, order.status),
      };

  String _typeLabel() => switch (order.orderType) {
        'takeaway' => 'Take Away',
        'delivery' => 'Delivery',
        _ => 'Dine In',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fmtMoney = NumberFormat('#,##0.00');
    final fmtTime = DateFormat('d/M HH:mm');
    final (statusColor, statusLabel) = _statusStyle();

    return ListTile(
      onTap: () => _showOrderDetail(context),
      leading: Container(
        width: 48.w,
        height: 48.w,
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(Icons.receipt_long_outlined,
            color: statusColor, size: 22.sp),
      ),
      title: Row(
        children: [
          Text(
            order.receiptNumber,
            style:
                TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(width: 6.w),
          Container(
            padding:
                EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              statusLabel,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      subtitle: Text(
        [
          if (order.tableName != null) order.tableName!,
          _typeLabel(),
          '${order.itemCount} รายการ',
          fmtTime.format(order.createdAt),
        ].join(' · '),
        style: TextStyle(fontSize: 11.sp, color: Colors.black54),
      ),
      trailing: Text(
        '฿${fmtMoney.format(order.totalAmount)}',
        style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w700,
            color: Colors.black87),
      ),
    );
  }

  void _showOrderDetail(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => OrderDetailPage(orderId: order.id)),
    );
  }
}
