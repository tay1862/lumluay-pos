import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../data/queue_repository.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../tables/data/tables_repository.dart';
import '../../../pos/providers/cart_provider.dart';

class QueuePage extends ConsumerWidget {
  const QueuePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final queueAsync = ref.watch(queueListProvider);
    final statusFilter = ref.watch(queueStatusFilterProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('จัดการคิว'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(queueListProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showNewQueueDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('รับคิวใหม่'),
        backgroundColor: AppColors.primary,
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            color: Colors.white,
            padding:
                EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusChip(
                    label: 'ทั้งหมด',
                    selected: statusFilter == null,
                    onSelected: () => ref
                        .read(queueStatusFilterProvider.notifier)
                        .state = null,
                  ),
                  ...[
                    QueueStatus.waiting,
                    QueueStatus.called,
                    QueueStatus.serving,
                  ].map((s) => _StatusChip(
                        label: _statusLabel(s),
                        selected: statusFilter == s,
                        color: _statusColor(s),
                        onSelected: () => ref
                            .read(queueStatusFilterProvider.notifier)
                            .state = s,
                      )),
                ],
              ),
            ),
          ),

          // Queue list
          Expanded(
            child: queueAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('เกิดข้อผิดพลาด: $e')),
              data: (tickets) {
                if (tickets.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline,
                            size: 64, color: Colors.black26),
                        SizedBox(height: 12),
                        Text('ยังไม่มีคิว',
                            style: TextStyle(color: Colors.black45)),
                      ],
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(queueListProvider),
                  child: ListView.separated(
                    padding: EdgeInsets.all(12.w),
                    itemCount: tickets.length,
                    separatorBuilder: (_, __) => SizedBox(height: 8.h),
                    itemBuilder: (ctx, i) =>
                        _QueueCard(ticket: tickets[i]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showNewQueueDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => _NewQueueDialog(ref: ref),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Queue card
// ─────────────────────────────────────────────────────────────────────────────
class _QueueCard extends ConsumerWidget {
  const _QueueCard({required this.ticket});
  final QueueTicket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFmt = DateFormat('HH:mm', 'th_TH');

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
        border: Border(
          left: BorderSide(
              color: _statusColor(ticket.status), width: 4),
        ),
      ),
      child: Row(
        children: [
          // Ticket number badge
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              color: _statusColor(ticket.status).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14.r),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(ticket.ticketNumber,
                    style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16.sp,
                        color: _statusColor(ticket.status))),
                Text('คิว',
                    style: TextStyle(
                        fontSize: 9.sp,
                        color: _statusColor(ticket.status))),
              ],
            ),
          ),
          SizedBox(width: 12.w),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(ticket.customerName ?? 'ลูกค้าทั่วไป',
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13.sp)),
                    SizedBox(width: 6.w),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 8.w, vertical: 2.h),
                      decoration: BoxDecoration(
                        color:
                            _statusColor(ticket.status).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(ticket.statusLabel,
                          style: TextStyle(
                              fontSize: 9.sp,
                              color: _statusColor(ticket.status),
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.people, size: 12.sp, color: Colors.black45),
                    SizedBox(width: 3.w),
                    Text('${ticket.partySize} คน',
                        style: TextStyle(
                            fontSize: 11.sp, color: Colors.black54)),
                    SizedBox(width: 10.w),
                    Icon(Icons.access_time,
                        size: 12.sp, color: Colors.black45),
                    SizedBox(width: 3.w),
                    Text(timeFmt.format(ticket.createdAt),
                        style: TextStyle(
                            fontSize: 11.sp, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),

          // Actions based on status
          _ActionButtons(ticket: ticket),
        ],
      ),
    );
  }
}

class _ActionButtons extends ConsumerWidget {
  const _ActionButtons({required this.ticket});
  final QueueTicket ticket;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final repo = ref.read(queueRepositoryProvider);

    Future<void> refresh() async => ref.invalidate(queueListProvider);

    switch (ticket.status) {
      case QueueStatus.waiting:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            FilledButton(
              onPressed: () async {
                await repo.callTicket(ticket.id);
                await refresh();
              },
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: Size(60.w, 34.h),
                  padding: EdgeInsets.zero),
              child: Text('เรียก', style: TextStyle(fontSize: 11.sp)),
            ),
            SizedBox(width: 6.w),
            IconButton(
              icon: const Icon(Icons.cancel_outlined,
                  color: Colors.red, size: 20),
              onPressed: () async {
                await repo.cancelTicket(ticket.id);
                await refresh();
              },
            ),
          ],
        );
      case QueueStatus.called:
        return FilledButton(
          onPressed: () => showDialog(
            context: context,
            builder: (_) => _QueueSeatDialog(ticket: ticket, outerRef: ref),
          ),
          style: FilledButton.styleFrom(
              backgroundColor: Colors.green,
              minimumSize: Size(70.w, 34.h),
              padding: EdgeInsets.symmetric(horizontal: 8.w)),
          child: Text('จัดโต๊ะ', style: TextStyle(fontSize: 11.sp)),
        );
      case QueueStatus.serving:
        return FilledButton(
          onPressed: () async {
            await repo.completeTicket(ticket.id);
            await refresh();
          },
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              minimumSize: Size(70.w, 34.h),
              padding: EdgeInsets.symmetric(horizontal: 8.w)),
          child: Text('เสร็จสิ้น', style: TextStyle(fontSize: 11.sp)),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Queue seat dialog (14.2.4) — pick an available table, seat the guest, go POS
// ─────────────────────────────────────────────────────────────────────────────
class _QueueSeatDialog extends ConsumerWidget {
  const _QueueSeatDialog({required this.ticket, required this.outerRef});
  final QueueTicket ticket;
  final WidgetRef outerRef;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablesAsync = ref.watch(tablesProvider(null));

    return AlertDialog(
      title: Text('เลือกโต๊ะ — คิว ${ticket.ticketNumber}'),
      content: SizedBox(
        width: 320.w,
        child: tablesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('โหลดโต๊ะไม่ได้: $e'),
          data: (tables) {
            final available = tables
                .where((t) => t.status == TableStatus.available)
                .toList();
            if (available.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('ไม่มีโต๊ะว่างในขณะนี้',
                    textAlign: TextAlign.center),
              );
            }
            return SingleChildScrollView(
              child: Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: available.map((t) {
                  return ActionChip(
                    avatar:
                        const Icon(Icons.table_restaurant, size: 16),
                    label: Text('${t.name} (${t.seats} ที่)'),
                    onPressed: () async {
                      Navigator.pop(context);
                      try {
                        await ref
                            .read(queueRepositoryProvider)
                            .seatTicket(ticket.id, t.id);
                        outerRef.invalidate(queueListProvider);
                        // Set table in cart and navigate to POS
                        outerRef
                            .read(cartProvider.notifier)
                            .setTable(t.id, t.name);
                        if (context.mounted) context.go('/pos');
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('เกิดข้อผิดพลาด: $e')));
                        }
                      }
                    },
                  );
                }).toList(),
              ),
            );
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('ยกเลิก'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// New queue dialog
// ─────────────────────────────────────────────────────────────────────────────
class _NewQueueDialog extends ConsumerStatefulWidget {
  const _NewQueueDialog({required this.ref});
  final WidgetRef ref;

  @override
  ConsumerState<_NewQueueDialog> createState() => _NewQueueDialogState();
}

class _NewQueueDialogState extends ConsumerState<_NewQueueDialog> {
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  int _partySize = 1;
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    try {
      await ref.read(queueRepositoryProvider).createTicket(
            customerName: _nameCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            partySize: _partySize,
          );
      ref.invalidate(queueListProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('รับคิวใหม่'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
                labelText: 'ชื่อลูกค้า (ไม่บังคับ)'),
          ),
          SizedBox(height: 8.h),
          TextField(
            controller: _phoneCtrl,
            decoration: const InputDecoration(
                labelText: 'เบอร์โทร (ไม่บังคับ)'),
            keyboardType: TextInputType.phone,
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              const Text('จำนวนคน:'),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                onPressed: _partySize > 1
                    ? () => setState(() => _partySize--)
                    : null,
              ),
              Text('$_partySize',
                  style: TextStyle(
                      fontSize: 18.sp, fontWeight: FontWeight.w700)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                onPressed: () => setState(() => _partySize++),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ยกเลิก')),
        FilledButton(
          onPressed: _loading ? null : _save,
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary),
          child: _loading
              ? const CircularProgressIndicator(color: Colors.white)
              : const Text('รับคิว'),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────
Color _statusColor(QueueStatus s) {
  switch (s) {
    case QueueStatus.waiting:
      return Colors.orange;
    case QueueStatus.called:
      return Colors.blue;
    case QueueStatus.serving:
      return Colors.green;
    case QueueStatus.done:
      return Colors.grey;
    case QueueStatus.cancelled:
      return Colors.red;
  }
}

String _statusLabel(QueueStatus s) {
  switch (s) {
    case QueueStatus.waiting:
      return 'รอเรียก';
    case QueueStatus.called:
      return 'เรียกแล้ว';
    case QueueStatus.serving:
      return 'กำลังบริการ';
    case QueueStatus.done:
      return 'เสร็จสิ้น';
    case QueueStatus.cancelled:
      return 'ยกเลิก';
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    return Padding(
      padding: EdgeInsets.only(right: 6.w),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        selectedColor: activeColor.withValues(alpha: 0.15),
        checkmarkColor: activeColor,
        labelStyle: TextStyle(
          color: selected ? activeColor : Colors.black54,
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          fontSize: 11.sp,
        ),
        side: selected
            ? BorderSide(color: activeColor.withValues(alpha: 0.3))
            : BorderSide.none,
      ),
    );
  }
}
