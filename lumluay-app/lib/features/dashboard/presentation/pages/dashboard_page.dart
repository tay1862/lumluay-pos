import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/dashboard_repository.dart';
import '../../../../core/theme/app_theme.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final hourlyAsync = ref.watch(hourlyProvider);
    final fmt = NumberFormat('#,##0.00', 'th_TH');
    final today = DateFormat('EEEE, d MMMM y', 'th_TH').format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(hourlyProvider);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 80.h,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                titlePadding:
                    EdgeInsets.only(left: 20.w, bottom: 12.h),
                title: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('แดชบอร์ด',
                        style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87)),
                    Text(today,
                        style: TextStyle(
                            fontSize: 10.sp, color: Colors.black45)),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.all(16.w),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // KPI cards
                    summaryAsync.when(
                      loading: () => const _KpiShimmer(),
                      error: (e, _) => _ErrorCard(message: '$e'),
                      data: (summary) => _KpiGrid(summary: summary, fmt: fmt),
                    ),
                    SizedBox(height: 20.h),

                    // Hourly chart
                    Text('ยอดขายรายชั่วโมง',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 10.h),
                    Container(
                      height: 200.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: hourlyAsync.when(
                        loading: () => const Center(
                            child: CircularProgressIndicator()),
                        error: (e, _) => Center(child: Text('$e')),
                        data: (hourly) => _HourlyChart(hourly: hourly),
                      ),
                    ),

                    SizedBox(height: 20.h),

                    // Quick actions
                    Text('ทางลัด',
                        style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700)),
                    SizedBox(height: 10.h),
                    _QuickActions(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI grid
// ─────────────────────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary, required this.fmt});
  final DashboardSummary summary;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final positive = summary.revenueGrowth >= 0;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.7,
      children: [
        _KpiCard(
          label: 'รายได้วันนี้',
          value: '฿ ${fmt.format(summary.todayRevenue)}',
          icon: Icons.attach_money,
          color: AppColors.primary,
          badge: '${positive ? '+' : ''}${summary.revenueGrowth.toStringAsFixed(1)}%',
          badgePositive: positive,
        ),
        _KpiCard(
          label: 'ออเดอร์วันนี้',
          value: '${summary.orderCount} รายการ',
          icon: Icons.receipt_long_outlined,
          color: const Color(0xFF1A7F64),
        ),
        _KpiCard(
          label: 'เฉลี่ย / บิล',
          value: '฿ ${fmt.format(summary.avgOrderValue)}',
          icon: Icons.calculate_outlined,
          color: Colors.indigo,
        ),
        _KpiCard(
          label: 'ออเดอร์เปิดอยู่',
          value: '${summary.openOrders} รายการ',
          icon: Icons.pending_actions_outlined,
          color: Colors.orange.shade700,
        ),
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
    this.badge,
    this.badgePositive = true,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? badge;
  final bool badgePositive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(icon, color: color, size: 22.sp),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 10.sp, color: Colors.black54)),
                SizedBox(height: 2.h),
                Text(value,
                    style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700),
                    overflow: TextOverflow.ellipsis),
                if (badge != null)
                  Text(badge!,
                      style: TextStyle(
                          fontSize: 9.sp,
                          color: badgePositive
                              ? Colors.green
                              : Colors.red,
                          fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Simple hourly bar chart (no fl_chart dependency)
// ─────────────────────────────────────────────────────────────────────────────
class _HourlyChart extends StatelessWidget {
  const _HourlyChart({required this.hourly});
  final List<HourlySale> hourly;

  @override
  Widget build(BuildContext context) {
    if (hourly.isEmpty) {
      return const Center(child: Text('ยังไม่มีข้อมูล'));
    }
    final maxRevenue = hourly
        .map((h) => h.revenue)
        .fold(0.0, (a, b) => a > b ? a : b);

    return Padding(
      padding: EdgeInsets.all(16.w),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: hourly.map((h) {
          final fraction = maxRevenue > 0 ? h.revenue / maxRevenue : 0.0;
          final now = DateTime.now().hour;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 2.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 500),
                    height: (170.h * fraction).clamp(4.0, 170.h),
                    decoration: BoxDecoration(
                      color: h.hour == now
                          ? AppColors.primary
                          : AppColors.primary.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.vertical(
                          top: Radius.circular(4.r)),
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text('${h.hour}',
                      style: TextStyle(
                          fontSize: 8.sp, color: Colors.black45)),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick actions
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 4,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      children: [
        _ActionBtn(
          icon: Icons.point_of_sale,
          label: 'เปิดบิลใหม่',
          color: AppColors.primary,
          onTap: () => context.push('/pos'),
        ),
        _ActionBtn(
          icon: Icons.table_restaurant,
          label: 'ผังโต๊ะ',
          color: const Color(0xFF1A7F64),
          onTap: () => context.push('/tables'),
        ),
        _ActionBtn(
          icon: Icons.restaurant,
          label: 'หน้าจอครัว',
          color: Colors.indigo,
          onTap: () => context.push('/kitchen'),
        ),
        _ActionBtn(
          icon: Icons.timer,
          label: 'เปิด/ปิดกะ',
          color: Colors.orange.shade700,
          onTap: () => context.push('/shifts'),
        ),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(icon, color: color, size: 22.sp),
            ),
            SizedBox(height: 6.h),
            Text(label,
                style: TextStyle(fontSize: 10.sp),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
class _KpiShimmer extends StatelessWidget {
  const _KpiShimmer();

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12.w,
      mainAxisSpacing: 12.h,
      childAspectRatio: 1.7,
      children: List.generate(
          4,
          (_) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                ),
              )),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400),
          SizedBox(width: 8.w),
          Expanded(child: Text(message, style: TextStyle(fontSize: 12.sp))),
        ],
      ),
    );
  }
}
