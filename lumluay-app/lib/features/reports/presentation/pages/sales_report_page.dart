import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../data/reports_repository.dart';

final _salesDateRangeProvider = StateProvider<(DateTime, DateTime)>((ref) {
  final now = DateTime.now();
  return (DateTime(now.year, now.month, 1), now);
});

class SalesReportPage extends ConsumerWidget {
  const SalesReportPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(_salesDateRangeProvider);
    final summaryAsync = ref.watch(reportsSummaryProvider(range));
    final dailyAsync = ref.watch(reportsDailyProvider(range));
    final fmtDate = DateFormat('d MMM yyyy', 'lo');
    final fmtMoney = NumberFormat('#,##0.00');

    return Scaffold(
      appBar: AppBar(
        title: const Text('ລາຍງານຍອດຂາຍ'),
        actions: [
          // ── 15.2.8 Export CSV ────────────────────────────────────────────
          IconButton(
            icon: const Icon(Icons.download_outlined),
            tooltip: 'ສົ່ງອອກ CSV',
            onPressed: () => _exportCsv(context, ref, range),
          ),
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
        onRefresh: () async {
          ref.invalidate(reportsSummaryProvider(range));
          ref.invalidate(reportsDailyProvider(range));
        },
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // ── Summary Strip ────────────────────────────────────────────
            summaryAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => _errorCard(e.toString()),
              data: (s) => _SummaryStrip(
                revenue: s.totalRevenue,
                orders: s.totalOrders,
                avg: s.avgOrderValue,
                paymentBreakdown: s.paymentBreakdown,
              ),
            ),
            SizedBox(height: 16.h),

            // ── Daily Table ──────────────────────────────────────────────
            Text('ລາຍໄດ້ລາຍວັນ',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            SizedBox(height: 8.h),
            dailyAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _errorCard(e.toString()),
              data: (rows) => rows.isEmpty
                  ? Card(
                      child: Padding(
                        padding: EdgeInsets.all(24.h),
                        child: const Center(child: Text('ບໍ່ມີຂໍ້ມູນໃນຊ່ວງນີ້')),
                      ),
                    )
                  : Card(
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
                                Expanded(
                                    child: Text('ວັນທີ',
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.sp))),
                                SizedBox(
                                    width: 80.w,
                                    child: Text('ອໍເດີ',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.sp))),
                                SizedBox(
                                    width: 100.w,
                                    child: Text('ລາຍໄດ້',
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13.sp))),
                              ],
                            ),
                          ),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: rows.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, i) {
                              final d = rows[i];
                              final date = DateTime.tryParse(d.date) ??
                                  DateTime.now();
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 10.h),
                                child: Row(
                                  children: [
                                    Expanded(
                                        child: Text(
                                        DateFormat('EEE d MMM', 'lo')
                                          .format(date),
                                      style: TextStyle(fontSize: 13.sp),
                                    )),
                                    SizedBox(
                                        width: 80.w,
                                        child: Text(
                                          '${d.orders}',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(fontSize: 13.sp),
                                        )),
                                    SizedBox(
                                        width: 100.w,
                                        child: Text(
                                          '₭${fmtMoney.format(d.revenue)}',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontSize: 13.sp,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.green.shade700),
                                        )),
                                  ],
                                ),
                              );
                            },
                          ),
                          // Total row
                          dailyAsync.whenData((rows) {
                            final totalRev = rows
                                .fold<double>(0, (s, d) => s + d.revenue);
                            final totalOrd =
                                rows.fold<int>(0, (s, d) => s + d.orders);
                            return Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 16.w, vertical: 10.h),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.only(
                                  bottomLeft: Radius.circular(12.r),
                                  bottomRight: Radius.circular(12.r),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                      child: Text('ລວມ',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.sp))),
                                  SizedBox(
                                      width: 80.w,
                                      child: Text('$totalOrd',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.sp))),
                                  SizedBox(
                                      width: 100.w,
                                      child: Text(
                                          '₭${fmtMoney.format(totalRev)}',
                                          textAlign: TextAlign.right,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13.sp,
                                              color: Colors.green.shade700))),
                                ],
                              ),
                            );
                          }).value ??
                              const SizedBox.shrink(),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _errorCard(String msg) => Card(
        color: Colors.red.shade50,
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(msg, style: const TextStyle(color: Colors.red)),
        ),
      );

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
      ref.read(_salesDateRangeProvider.notifier).state =
          (picked.start, picked.end);
    }
  }

  // ── 15.2.8 ─────────────────────────────────────────────────────────────────
  Future<void> _exportCsv(
      BuildContext context, WidgetRef ref, (DateTime, DateTime) range) async {
    final repo = ref.read(reportsRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    try {
      final csvBytes = await repo.downloadExport(range.$1, range.$2, 'sales');
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/sales-${range.$1.toIso8601String().split('T').first}.csv');
      await file.writeAsBytes(csvBytes);
      messenger.showSnackBar(
        SnackBar(
          content: Text('ບັນທຶກໄຟລ໌ແລ້ວ: ${file.path}'),
          action: SnackBarAction(label: 'ຕົກລົງ', onPressed: () {}),
        ),
      );
    } catch (e) {
      messenger
          .showSnackBar(SnackBar(content: Text('ສົ່ງອອກບໍ່ສຳເລັດ: $e')));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary strip
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({
    required this.revenue,
    required this.orders,
    required this.avg,
    required this.paymentBreakdown,
  });

  final double revenue;
  final int orders;
  final double avg;
  final Map<String, dynamic> paymentBreakdown;

  @override
  Widget build(BuildContext context) {
    final fmtMoney = NumberFormat('#,##0.00');
    return Column(
      children: [
        Row(
          children: [
            _KpiCard(
              label: 'ລາຍໄດ້ລວມ',
              value: '₭${fmtMoney.format(revenue)}',
              icon: Icons.payments_outlined,
              color: Colors.green,
            ),
            SizedBox(width: 8.w),
            _KpiCard(
              label: 'ຈຳນວນອໍເດີ',
              value: '$orders',
              icon: Icons.receipt_long_outlined,
              color: Colors.blue,
            ),
            SizedBox(width: 8.w),
            _KpiCard(
              label: 'ສະເລຍ/ອໍເດີ',
              value: '₭${fmtMoney.format(avg)}',
              icon: Icons.trending_up,
              color: Colors.orange,
            ),
          ],
        ),
        if (paymentBreakdown.isNotEmpty) ...[
          SizedBox(height: 8.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('ຊ່ອງທາງຊຳລະເງິນ',
                      style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.black54)),
                  SizedBox(height: 8.h),
                  ...paymentBreakdown.entries.map(
                    (e) => Padding(
                      padding: EdgeInsets.only(bottom: 4.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(e.key,
                              style: TextStyle(fontSize: 13.sp)),
                          Text(
                            '₭${fmtMoney.format((e.value as num).toDouble())}',
                            style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
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
          padding: EdgeInsets.all(10.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 18.sp),
              SizedBox(height: 6.h),
              Text(value,
                  style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: color)),
              Text(label,
                  style:
                      TextStyle(fontSize: 10.sp, color: Colors.black54)),
            ],
          ),
        ),
      ),
    );
  }
}
