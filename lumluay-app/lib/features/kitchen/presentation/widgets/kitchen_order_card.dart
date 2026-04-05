import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../domain/models/kitchen_order.dart';
import 'kitchen_timer.dart';

class KitchenOrderCard extends StatelessWidget {
  final KitchenOrder order;
  final bool loading;
  final ValueChanged<String> onNextStatus;

  const KitchenOrderCard({
    super.key,
    required this.order,
    required this.loading,
    required this.onNextStatus,
  });

  Color get _headerColor {
    if (order.isUrgent) return const Color(0xFFD32F2F);
    if (order.status == KitchenStatus.preparing) return const Color(0xFFF57F17);
    if (order.status == KitchenStatus.ready) return const Color(0xFF2E7D32);
    return const Color(0xFF1565C0);
  }

  String? get _nextStatus {
    return switch (order.status) {
      KitchenStatus.pending => 'preparing',
      KitchenStatus.preparing => 'ready',
      KitchenStatus.ready => 'served',
      _ => null,
    };
  }

  String? get _nextLabel {
    return switch (order.status) {
      KitchenStatus.pending => 'ຮັບອໍເດີ',
      KitchenStatus.preparing => 'ທຳເສັດແລ້ວ',
      KitchenStatus.ready => 'ເສີບແລ້ວ',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF0F3460),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(
          color: order.isUrgent ? Colors.red : Colors.transparent,
          width: 2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            color: _headerColor,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: Row(
              children: [
                Text(
                  order.orderReceiptNumber,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const Spacer(),
                if (order.tableName != null)
                  Chip(
                    label: Text(order.tableName!,
                        style: TextStyle(fontSize: 11.sp, color: Colors.white)),
                    backgroundColor: Colors.white24,
                    side: BorderSide.none,
                    padding: EdgeInsets.zero,
                  ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
            child: Row(
              children: [
                KitchenTimer(startedAt: order.startedAt ?? order.createdAt),
                const Spacer(),
                if (order.station != null)
                  Text(
                    order.station!.toUpperCase(),
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              itemCount: order.items.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.white12),
              itemBuilder: (context, i) {
                final item = order.items[i];
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 24.w,
                        child: Text(
                          'x${item.quantity}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.orange,
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      SizedBox(width: 6.w),
                      Expanded(
                        child: Text(
                          item.productName,
                          style: TextStyle(color: Colors.white, fontSize: 13.sp),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: EdgeInsets.all(8.w),
            child: loading
                ? const SizedBox(
                    height: 36,
                    child: Center(
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
                    ),
                  )
                : (_nextStatus == null
                    ? const SizedBox.shrink()
                    : FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: Colors.orange),
                        onPressed: () => onNextStatus(_nextStatus!),
                        child: Text(_nextLabel!),
                      )),
          ),
        ],
      ),
    );
  }
}
