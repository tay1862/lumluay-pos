import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/reports_repository.dart';

final _productReportDateRangeProvider =
    StateProvider<(DateTime, DateTime)>((ref) {
  final now = DateTime.now();
  return (DateTime(now.year, now.month, 1), now);
});

class ProductsReportPage extends ConsumerWidget {
  const ProductsReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(_productReportDateRangeProvider);
    final topAsync = ref.watch(reportsTopProductsProvider(range));
    final fmtDate = DateFormat('d MMM yyyy', 'th_TH');
    final fmtMoney = NumberFormat('#,##0.00');
    final fmtQty = NumberFormat('#,##0');

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายงานสินค้า'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: Text(
              '${fmtDate.format(range.$1)} – ${fmtDate.format(range.$2)}',
              style: const TextStyle(fontSize: 12),
            ),
            onPressed: () => _pickRange(context, ref, range),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(reportsTopProductsProvider(range)),
        child: topAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Text(e.toString(),
                style: const TextStyle(color: Colors.red)),
          ),
          data: (products) {
            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.inventory_2_outlined,
                        size: 48.sp, color: Colors.black26),
                    SizedBox(height: 12.h),
                    const Text('ไม่มีข้อมูลสินค้าในช่วงนี้',
                        style: TextStyle(color: Colors.black54)),
                  ],
                ),
              );
            }

            final maxRev =
                products.map((p) => p.revenue).reduce((a, b) => a > b ? a : b);
            final totalRev =
                products.fold<double>(0, (s, p) => s + p.revenue);
            final totalQty =
                products.fold<int>(0, (s, p) => s + p.quantity);

            return ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                // ── Summary counts ───────────────────────────────────────
                Row(
                  children: [
                    _SummaryTile(
                        label: 'รายได้รวม',
                        value: '฿${fmtMoney.format(totalRev)}',
                        icon: Icons.payments_outlined,
                        color: Colors.green),
                    SizedBox(width: 8.w),
                    _SummaryTile(
                        label: 'จำนวนขาย',
                        value: fmtQty.format(totalQty),
                        icon: Icons.shopping_cart_outlined,
                        color: Colors.blue),
                  ],
                ),
                SizedBox(height: 16.h),

                // ── Products table ───────────────────────────────────────
                Text('สินค้าขายดี Top ${products.length}',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold)),
                SizedBox(height: 8.h),
                Card(
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.w, vertical: 10.h),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surfaceContainerHighest,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(12.r),
                            topRight: Radius.circular(12.r),
                          ),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                                width: 28.w,
                                child: Text('#',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.sp,
                                        color: Colors.black54))),
                            Expanded(
                                child: Text('สินค้า',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13.sp))),
                            SizedBox(
                                width: 52.w,
                                child: Text('จำนวน',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.sp))),
                            SizedBox(
                                width: 90.w,
                                child: Text('รายได้',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12.sp))),
                          ],
                        ),
                      ),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: products.length,
                        separatorBuilder: (_, __) =>
                            const Divider(height: 1),
                        itemBuilder: (context, i) {
                          final p = products[i];
                          final revenueRatio =
                              maxRev > 0 ? p.revenue / maxRev : 0.0;
                          return Padding(
                            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    SizedBox(
                                        width: 28.w,
                                        child: CircleAvatar(
                                          radius: 11.r,
                                          backgroundColor: Theme.of(context)
                                              .primaryColor
                                              .withValues(alpha: 0.15),
                                          child: Text(
                                            '${i + 1}',
                                            style: TextStyle(
                                                fontSize: 10.sp,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        )),
                                    Expanded(
                                        child: Text(p.name,
                                            style: TextStyle(
                                                fontSize: 13.sp,
                                                fontWeight:
                                                    FontWeight.w500))),
                                    SizedBox(
                                        width: 52.w,
                                        child: Text(
                                          '×${fmtQty.format(p.quantity)}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontSize: 12.sp,
                                              color: Colors.black54),
                                        )),
                                    SizedBox(
                                        width: 90.w,
                                        child: Text(
                                          '฿${fmtMoney.format(p.revenue)}',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade700),
                                        )),
                                  ],
                                ),
                                SizedBox(height: 6.h),
                                // Revenue bar
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4.r),
                                  child: LinearProgressIndicator(
                                    value: revenueRatio,
                                    minHeight: 4.h,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor:
                                        AlwaysStoppedAnimation<Color>(
                                      HSLColor.fromColor(
                                              Theme.of(context).primaryColor)
                                          .withLightness(0.45 +
                                              0.25 * (1 - revenueRatio))
                                          .toColor(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _pickRange(
      BuildContext context, WidgetRef ref, (DateTime, DateTime) current) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange:
          DateTimeRange(start: current.$1, end: current.$2),
    );
    if (picked != null) {
      ref.read(_productReportDateRangeProvider.notifier).state =
          (picked.start, picked.end);
    }
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Card(
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22.sp),
              SizedBox(width: 8.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.bold,
                          color: color)),
                  Text(label,
                      style: TextStyle(
                          fontSize: 11.sp, color: Colors.black54)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
