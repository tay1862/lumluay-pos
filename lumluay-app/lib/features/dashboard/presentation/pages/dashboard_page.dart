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
    final fmt = NumberFormat('#,##0', 'th_TH');
    final today = DateFormat('EEEE, d MMMM y').format(DateTime.now());
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(hourlyProvider);
        },
        child: CustomScrollView(
          slivers: [
            // ── Hero Header ──
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? AppColors.darkHeroGradient
                      : AppColors.heroGradient,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(AppRadius.xl),
                    bottomRight: Radius.circular(AppRadius.xl),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(20.w, 48.h, 20.w, 24.h),
                child: SafeArea(
                  bottom: false,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ແດດບອດ',
                        style: TextStyle(
                          fontFamily: 'Sarabun',
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        today,
                        style: TextStyle(
                          fontFamily: 'Sarabun',
                          fontSize: 13.sp,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      SizedBox(height: 20.h),
                      // Revenue hero card
                      summaryAsync.when(
                        loading: () => _RevenueHeroShimmer(),
                        error: (e, _) => const SizedBox(),
                        data: (summary) => _RevenueHeroCard(
                          summary: summary,
                          fmt: fmt,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            SliverPadding(
              padding: EdgeInsets.all(16.w),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: 4.h),
                    // KPI cards
                    summaryAsync.when(
                      loading: () => const _KpiShimmer(),
                      error: (e, _) => _ErrorCard(message: '$e'),
                      data: (summary) => _KpiGrid(summary: summary, fmt: fmt),
                    ),
                    SizedBox(height: 24.h),

                    // Hourly chart
                    Text(
                      'ຍອດຂາຍລາຍຊົ່ວໂມງ',
                      style: TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Container(
                      height: 220.h,
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.surfaceElevatedDark
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
                      ),
                      child: hourlyAsync.when(
                        loading: () => Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                        error: (e, _) => Center(child: Text('$e')),
                        data: (hourly) => _HourlyChart(hourly: hourly),
                      ),
                    ),

                    SizedBox(height: 24.h),

                    // Quick actions
                    Text(
                      'ທາງລັດ',
                      style: TextStyle(
                        fontFamily: 'Sarabun',
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    _QuickActions(),
                    SizedBox(height: 24.h),
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
// Revenue hero card (inside gradient header)
// ─────────────────────────────────────────────────────────────────────────────
class _RevenueHeroCard extends StatelessWidget {
  const _RevenueHeroCard({required this.summary, required this.fmt});
  final DashboardSummary summary;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    final positive = summary.revenueGrowth >= 0;
    return Container(
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ລາຍໄດ້ມື້ນີ້',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 13.sp,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  '₭ ${fmt.format(summary.todayRevenue)}',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 28.sp,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: positive
                  ? Colors.white.withOpacity(0.2)
                  : Colors.red.withOpacity(0.25),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  positive
                      ? Icons.trending_up_rounded
                      : Icons.trending_down_rounded,
                  size: 16.sp,
                  color: Colors.white,
                ),
                SizedBox(width: 4.w),
                Text(
                  '${positive ? '+' : ''}${summary.revenueGrowth.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontFamily: 'Sarabun',
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RevenueHeroShimmer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80.h,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// KPI grid (3 secondary cards below hero)
// ─────────────────────────────────────────────────────────────────────────────
class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.summary, required this.fmt});
  final DashboardSummary summary;
  final NumberFormat fmt;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KpiCard(
            label: 'ອໍເດີມື້ນີ້',
            value: '${summary.orderCount}',
            icon: Icons.receipt_long_rounded,
            gradient: AppColors.secondaryGradient,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _KpiCard(
            label: 'ສະເລ່ຍ/ບິນ',
            value: '₭${fmt.format(summary.avgOrderValue)}',
            icon: Icons.analytics_rounded,
            gradient: AppColors.accentGradient,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: _KpiCard(
            label: 'ເປີດຢູ່',
            value: '${summary.openOrders}',
            icon: Icons.pending_actions_rounded,
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            ),
          ),
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
    required this.gradient,
  });
  final String label;
  final String value;
  final IconData icon;
  final LinearGradient gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceElevatedDark : AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36.w,
            height: 36.w,
            decoration: BoxDecoration(
              gradient: gradient,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, color: Colors.white, size: 18.sp),
          ),
          SizedBox(height: 10.h),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 18.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Sarabun',
              fontSize: 11.sp,
              color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hourly bar chart (vibrant gradient bars)
// ─────────────────────────────────────────────────────────────────────────────
class _HourlyChart extends StatelessWidget {
  const _HourlyChart({required this.hourly});
  final List<HourlySale> hourly;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (hourly.isEmpty) {
      return Center(
        child: Text(
          'ຍັງບໍ່ມີຂໍ້ມູນ',
          style: TextStyle(
            fontFamily: 'Sarabun',
            fontSize: 14.sp,
            color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      );
    }
    final maxRevenue = hourly
        .map((h) => h.revenue)
        .fold(0.0, (a, b) => a > b ? a : b);
    final currentHour = DateTime.now().hour;

    return Padding(
      padding: EdgeInsets.fromLTRB(12.w, 16.h, 12.w, 12.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: hourly.map((h) {
          final fraction = maxRevenue > 0 ? h.revenue / maxRevenue : 0.0;
          final isCurrent = h.hour == currentHour;
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 1.5.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    height: (180.h * fraction).clamp(3.0, 180.h),
                    decoration: BoxDecoration(
                      gradient: isCurrent
                          ? AppColors.primaryGradient
                          : LinearGradient(
                              colors: [
                                AppColors.primary.withOpacity(0.35),
                                AppColors.primaryLight.withOpacity(0.2),
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(4.r),
                      ),
                      boxShadow: isCurrent
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.3),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    '${h.hour}',
                    style: TextStyle(
                      fontFamily: 'Sarabun',
                      fontSize: 8.sp,
                      fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                      color: isCurrent
                          ? AppColors.primary
                          : isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textTertiary,
                    ),
                  ),
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
          icon: Icons.point_of_sale_rounded,
          label: 'ເປີດບິນໃໝ່',
          gradient: AppColors.primaryGradient,
          onTap: () => context.push('/pos'),
        ),
        _ActionBtn(
          icon: Icons.table_restaurant_rounded,
          label: 'ຜັງໂຕະ',
          gradient: AppColors.secondaryGradient,
          onTap: () => context.push('/tables'),
        ),
        _ActionBtn(
          icon: Icons.restaurant_rounded,
          label: 'ໜ້າຈໍຄົວ',
          gradient: AppColors.accentGradient,
          onTap: () => context.push('/kitchen'),
        ),
        _ActionBtn(
          icon: Icons.timer_rounded,
          label: 'ເປີດ/ປິດກະ',
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
          ),
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
    required this.gradient,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final LinearGradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceElevatedDark : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: isDark ? AppShadows.cardDark : AppShadows.card,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: Icon(icon, color: Colors.white, size: 22.sp),
            ),
            SizedBox(height: 8.h),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: List.generate(
        3,
        (i) => Expanded(
          child: Container(
            height: 110.h,
            margin: EdgeInsets.only(right: i < 2 ? 12.w : 0),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceElevatedDark : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
          ),
        ),
      ),
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
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.error.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: AppColors.error, size: 20.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontFamily: 'Sarabun',
                fontSize: 13.sp,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
