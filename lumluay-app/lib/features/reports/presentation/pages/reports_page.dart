import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/reports_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Date range state
// ─────────────────────────────────────────────────────────────────────────────
final _dateRangeProvider =
    StateProvider<(DateTime, DateTime)>((ref) {
  final now = DateTime.now();
  final from = DateTime(now.year, now.month, 1);
  return (from, now);
});

// ─────────────────────────────────────────────────────────────────────────────
// Reports Page
// ─────────────────────────────────────────────────────────────────────────────
class ReportsPage extends ConsumerWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(_dateRangeProvider);
    final summaryAsync = ref.watch(reportsSummaryProvider(range));
    final dailyAsync = ref.watch(reportsDailyProvider(range));
    final topAsync = ref.watch(reportsTopProductsProvider(range));
    final fmt = DateFormat('d MMM yyyy', 'lo');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('ລາຍງານ'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.date_range, size: 18),
            label: Text('${fmt.format(range.$1)} – ${fmt.format(range.$2)}',
                style: const TextStyle(fontSize: 12)),
            onPressed: () => _pickDateRange(context, ref, range),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(reportsSummaryProvider(range));
          ref.invalidate(reportsDailyProvider(range));
          ref.invalidate(reportsTopProductsProvider(range));
        },
        child: ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            // Summary cards
            summaryAsync.when(
              loading: () => const _SummaryShimmer(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (s) => _SummaryRow(summary: s),
            ),
            SizedBox(height: 16.h),

            // Daily breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle(title: 'ລາຍໄດ້ລາຍວັນ', icon: Icons.bar_chart),
                TextButton(
                  onPressed: () => context.push('/reports/sales'),
                  child: const Text('ເບິ່ງທັງໝົດ'),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            dailyAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (data) => _DailyChart(data: data),
            ),
            SizedBox(height: 16.h),

            // Top products
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _SectionTitle(title: 'ສິນຄ້າຂາຍດີ', icon: Icons.star_outline),
                TextButton(
                  onPressed: () => context.push('/reports/products'),
                  child: const Text('ເບິ່ງທັງໝົດ'),
                ),
              ],
            ),
            SizedBox(height: 8.h),
            topAsync.when(
              loading: () => const _LoadingCard(),
              error: (e, _) => _ErrorCard(message: e.toString()),
              data: (data) => _TopProductsList(products: data),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDateRange(
      BuildContext context, WidgetRef ref, (DateTime, DateTime) current) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: current.$1, end: current.$2),
    );
    if (picked != null) {
      ref.read(_dateRangeProvider.notifier).state =
          (picked.start, picked.end);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary row
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.summary});
  final ReportsSummary summary;

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    return Row(
      children: [
        Expanded(
            child: _StatCard(
                label: 'ລາຍໄດ້ລວມ',
                value: '₭${fmt.format(summary.totalRevenue)}',
                icon: Icons.payments_outlined,
                color: Colors.green)),
        SizedBox(width: 8.w),
        Expanded(
            child: _StatCard(
                label: 'ຈຳນວນອໍເດີ',
                value: '${summary.totalOrders}',
                icon: Icons.receipt_long_outlined,
                color: Colors.blue)),
        SizedBox(width: 8.w),
        Expanded(
            child: _StatCard(
                label: 'ສະເລຍ/ອໍເດີ',
                value: '₭${fmt.format(summary.avgOrderValue)}',
                icon: Icons.trending_up,
                color: Colors.orange)),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
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
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20.sp),
            SizedBox(height: 8.h),
            Text(value,
                style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: color)),
            Text(label,
                style: TextStyle(fontSize: 11.sp, color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Daily bar chart (manual, no chart lib dependency)
// ─────────────────────────────────────────────────────────────────────────────
class _DailyChart extends StatelessWidget {
  const _DailyChart({required this.data});
  final List<DailyBreakdown> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24.h),
          child: const Center(child: Text('ບໍ່ມີຂໍ້ມູນ')),
        ),
      );
    }

    final maxRev = data.map((d) => d.revenue).reduce((a, b) => a > b ? a : b);
    final fmt = NumberFormat('#,##0');
    final dateFmt = DateFormat('d/M');

    return Card(
      child: Padding(
        padding: EdgeInsets.all(12.w),
        child: SizedBox(
          height: 180.h,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: data.map((d) {
              final ratio = maxRev > 0 ? d.revenue / maxRev : 0.0;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 2.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '₭${fmt.format(d.revenue)}',
                        style: TextStyle(fontSize: 8.sp, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2.h),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4.r),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: (ratio * 120.h).clampDouble(2, 120.h),
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        dateFmt.format(DateTime.tryParse(d.date) ?? DateTime.now()),
                        style: TextStyle(fontSize: 9.sp, color: Colors.black54),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top products list
// ─────────────────────────────────────────────────────────────────────────────
class _TopProductsList extends StatelessWidget {
  const _TopProductsList({required this.products});
  final List<TopProduct> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Card(
        child: Padding(
          padding: EdgeInsets.all(24.h),
          child: const Center(child: Text('ບໍ່ມີຂໍ້ມູນ')),
        ),
      );
    }

    final fmtMoney = NumberFormat('#,##0.00');
    final maxRev =
        products.map((p) => p.revenue).reduce((a, b) => a > b ? a : b);

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: products.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, indent: 16, endIndent: 16),
        itemBuilder: (context, i) {
          final p = products[i];
          final ratio = maxRev > 0 ? p.revenue / maxRev : 0.0;
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                        radius: 12.r,
                        backgroundColor:
                            Theme.of(context).primaryColor.withValues(alpha: 0.15),
                        child: Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 11.sp,
                                color: Theme.of(context).primaryColor,
                                fontWeight: FontWeight.w700))),
                    SizedBox(width: 8.w),
                    Expanded(
                        child: Text(p.name,
                            style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w600))),
                    Text('×${p.quantity}',
                        style: TextStyle(
                            color: Colors.grey, fontSize: 12.sp)),
                    SizedBox(width: 8.w),
                    Text('₭${fmtMoney.format(p.revenue)}',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 13.sp,
                            color: Colors.green[700])),
                  ],
                ),
                SizedBox(height: 4.h),
                LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.grey[200],
                  color: Theme.of(context).primaryColor,
                  minHeight: 4,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.icon});
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18.sp, color: Theme.of(context).primaryColor),
        SizedBox(width: 6.w),
        Text(title,
            style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _SummaryShimmer extends StatelessWidget {
  const _SummaryShimmer();

  @override
  Widget build(BuildContext context) => Row(
        children: List.generate(
          3,
          (_) => Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Card(
                child: SizedBox(height: 80.h),
              ),
            ),
          ),
        ),
      );
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) => const Card(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Card(
        color: Colors.red[50],
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Text(message,
              style: const TextStyle(color: Colors.red, fontSize: 12)),
        ),
      );
}

extension on double {
  double clampDouble(double min, double max) {
    if (this < min) return min;
    if (this > max) return max;
    return this;
  }
}
