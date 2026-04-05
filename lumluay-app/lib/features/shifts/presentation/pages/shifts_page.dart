import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/shifts_repository.dart';

class ShiftsPage extends ConsumerWidget {
  const ShiftsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentAsync = ref.watch(currentShiftProvider);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('ກະການເຮັດວຽກ'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.timer_outlined), text: 'ກະປັດຈຸບັນ'),
              Tab(icon: Icon(Icons.history), text: 'ປະຫວັດກະ'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Current shift
            currentAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('$e')),
              data: (shift) => shift == null || shift.status == ShiftStatus.closed
                  ? _OpenShiftPanel()
                  : _ActiveShiftPanel(shift: shift),
            ),
            // Tab 2: History
            _ShiftHistoryTab(),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Open shift panel
// ─────────────────────────────────────────────────────────────────────────────
class _OpenShiftPanel extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OpenShiftPanel> createState() =>
      _OpenShiftPanelState();
}

class _OpenShiftPanelState extends ConsumerState<_OpenShiftPanel> {
  final _cashCtrl = TextEditingController(text: '0');
  bool _loading = false;

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  Future<void> _openShift() async {
    final cash = double.tryParse(_cashCtrl.text) ?? 0;
    setState(() => _loading = true);
    try {
      await ref.read(shiftsRepositoryProvider).openShift(cash);
      ref.invalidate(currentShiftProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        margin: EdgeInsets.all(24.w),
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_open_outlined,
                  size: 56.sp, color: Colors.green),
              SizedBox(height: 16.h),
              Text(
                'ຍັງບໍ່ໄດ້ເປີດກະ',
                style: TextStyle(
                    fontSize: 18.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 8.h),
              Text(
                'ປ້ອນຍອດເງິນເປີດກະ ແລ້ວກົດເປີດກະ',
                style: TextStyle(
                    fontSize: 13.sp, color: Colors.black54),
              ),
              SizedBox(height: 24.h),
              TextFormField(
                controller: _cashCtrl,
                keyboardType: const TextInputType.numberWithOptions(
                    decimal: true),
                decoration: const InputDecoration(
                  labelText: 'ຍອດເງິນເປີດກະ (ກີບ)',
                  prefixIcon: Icon(Icons.payments_outlined),
                  prefixText: '₭ ',
                ),
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('ເປີດກະ'),
                  onPressed: _loading ? null : _openShift,
                  style: FilledButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: EdgeInsets.symmetric(vertical: 14.h)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Active shift panel
// ─────────────────────────────────────────────────────────────────────────────
class _ActiveShiftPanel extends ConsumerStatefulWidget {
  const _ActiveShiftPanel({required this.shift});
  final Shift shift;

  @override
  ConsumerState<_ActiveShiftPanel> createState() =>
      _ActiveShiftPanelState();
}

class _ActiveShiftPanelState extends ConsumerState<_ActiveShiftPanel> {
  final _cashCtrl = TextEditingController(text: '0');
  bool _loading = false;

  @override
  void dispose() {
    _cashCtrl.dispose();
    super.dispose();
  }

  Future<void> _closeShift() async {
    final cash = double.tryParse(_cashCtrl.text) ?? 0;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ປິດກະ'),
        content: Text(
            'ຢືນຢັນປິດກະດ້ວຍຍອດເງິນ ₭${NumberFormat('#,##0.00').format(cash)}?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ຍົກເລີກ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ປິດກະ'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    setState(() => _loading = true);
    try {
      await ref.read(shiftsRepositoryProvider).closeShift(cash);
      ref.invalidate(currentShiftProvider);
      ref.invalidate(shiftHistoryProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ເກີດຂໍ້ຜິດພາດ: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,##0.00');
    final durFmt = DateFormat('HH:mm');
    final shift = widget.shift;
    final elapsed = DateTime.now().difference(shift.openedAt);
    final hours = elapsed.inHours;
    final minutes = elapsed.inMinutes % 60;

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        // Status card
        Card(
          color: Colors.green[50],
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.green[100],
                  child: const Icon(Icons.timer, color: Colors.green),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ກະເປີດຢູ່',
                          style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                              color: Colors.green[800])),
                      Text(
                          'ເລີ່ມ ${durFmt.format(shift.openedAt)} · ຜ່ານມາ $hours ຊມ. $minutes ນ.',
                          style: TextStyle(
                              fontSize: 12.sp,
                              color: Colors.green[700])),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Stats
        Row(
          children: [
            Expanded(
                child: _ShiftStatCard(
                    label: 'ເງິນເປີດກະ',
                    value: '₭${fmt.format(shift.openingCash)}',
                    icon: Icons.account_balance_wallet_outlined)),
            SizedBox(width: 8.w),
            Expanded(
                child: _ShiftStatCard(
                    label: 'ຍອດຂາຍ',
                    value: shift.totalSales != null
                        ? '₭${fmt.format(shift.totalSales!)}'
                        : '-',
                    icon: Icons.trending_up)),
            SizedBox(width: 8.w),
            Expanded(
                child: _ShiftStatCard(
                    label: 'ອໍເດີ',
                    value: shift.totalOrders != null
                        ? '${shift.totalOrders}'
                        : '-',
                    icon: Icons.receipt_long_outlined)),
          ],
        ),
        SizedBox(height: 24.h),

        // Close shift
        Text('ປິດກະ',
            style: TextStyle(
                fontSize: 15.sp, fontWeight: FontWeight.w700)),
        SizedBox(height: 8.h),
        TextFormField(
          controller: _cashCtrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'ຍອດເງິນນັບໄດ້ (ກີບ)',
            prefixIcon: Icon(Icons.payments_outlined),
            prefixText: '₭ ',
          ),
          textAlign: TextAlign.right,
          style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 16.h),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            icon: const Icon(Icons.lock_outlined),
            label: const Text('ປິດກະ'),
            onPressed: _loading ? null : _closeShift,
            style: FilledButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(vertical: 14.h)),
          ),
        ),
      ],
    );
  }
}

class _ShiftStatCard extends StatelessWidget {
  const _ShiftStatCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: EdgeInsets.all(12.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18.sp, color: Colors.black45),
              SizedBox(height: 6.h),
              Text(value,
                  style: TextStyle(
                      fontSize: 15.sp, fontWeight: FontWeight.w700)),
              Text(label,
                  style:
                      TextStyle(fontSize: 10.sp, color: Colors.black54)),
            ],
          ),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Shift history tab
// ─────────────────────────────────────────────────────────────────────────────
class _ShiftHistoryTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(shiftHistoryProvider);
    return historyAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('$e')),
      data: (shifts) {
        if (shifts.isEmpty) {
          return const Center(
              child: Text('ບໍ່ມີປະຫວັດກະ',
                  style: TextStyle(color: Colors.black54)));
        }
        final fmt = NumberFormat('#,##0.00');
        final dateFmt = DateFormat('d/M/yy HH:mm');
        return ListView.separated(
          itemCount: shifts.length,
          separatorBuilder: (_, __) =>
              const Divider(height: 1, indent: 16, endIndent: 16),
          itemBuilder: (ctx, i) {
            final s = shifts[i];
            final isOpen = s.status == ShiftStatus.open;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor:
                    isOpen ? Colors.green[50] : Colors.grey[100],
                child: Icon(
                  isOpen ? Icons.timer : Icons.lock_outlined,
                  color: isOpen ? Colors.green : Colors.grey,
                  size: 18.sp,
                ),
              ),
              title: Text(
                '${dateFmt.format(s.openedAt)}'
                '${s.closedAt != null ? ' → ${dateFmt.format(s.closedAt!)}' : ''}',
                style: TextStyle(fontSize: 12.sp),
              ),
              subtitle: Text(
                '${s.openedByName} · ເງິນເປີດ ₭${fmt.format(s.openingCash)}',
                style: TextStyle(fontSize: 11.sp, color: Colors.black54),
              ),
              trailing: s.totalSales != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₭${fmt.format(s.totalSales!)}',
                            style: TextStyle(
                                fontSize: 13.sp,
                                fontWeight: FontWeight.w700)),
                        Text('${s.totalOrders ?? 0} ອໍເດີ',
                            style: TextStyle(
                                fontSize: 10.sp, color: Colors.black45)),
                      ],
                    )
                  : null,
            );
          },
        );
      },
    );
  }
}
