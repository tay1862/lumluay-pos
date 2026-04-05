import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../../data/coupons_repository.dart';

class CouponsPage extends ConsumerWidget {
  const CouponsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(couponsFilterProvider);
    final couponsAsync = ref.watch(couponsListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('ຄູປອງ'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'ເພີ່ມຄູປອງ',
            onPressed: () => context.push('/coupons/new'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(48.h),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            child: SegmentedButton<bool?>(
              segments: const [
                ButtonSegment(value: null, label: Text('ທັງໝົດ')),
                ButtonSegment(value: true, label: Text('ໃຊ້ງານ')),
                ButtonSegment(value: false, label: Text('ໝົດອາຍຸ')),
              ],
              selected: {filter},
              onSelectionChanged: (s) =>
                  ref.read(couponsFilterProvider.notifier).state = s.first,
            ),
          ),
        ),
      ),
      body: couponsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (all) {
          final coupons = filter == null
              ? all
              : filter == true
                  ? all.where((c) => c.isEffectivelyActive).toList()
                  : all.where((c) => !c.isEffectivelyActive).toList();

          if (coupons.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.confirmation_number_outlined,
                      size: 56.sp, color: Colors.black26),
                  SizedBox(height: 12.h),
                  const Text('ຍັງບໍ່ມີຄູປອງ',
                      style: TextStyle(color: Colors.black54)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(couponsListProvider.future),
            child: ListView.separated(
              padding: EdgeInsets.symmetric(vertical: 8.h),
              itemCount: coupons.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 16),
              itemBuilder: (ctx, i) => _CouponTile(
                coupon: coupons[i],
                onEdit: () async {
                  await context.push('/coupons/${coupons[i].id}/edit',
                      extra: coupons[i]);
                  ref.invalidate(couponsListProvider);
                },
                onDelete: () => _confirmDelete(ctx, ref, coupons[i]),
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, Coupon coupon) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('ລົບຄູປອງ'),
        content: Text('ຕ້ອງການລົບຄູປອງ "${coupon.code}" ໃຊ່ຫຼືບໍ່?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('ຍົກເລີກ')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('ລົບ'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(couponsRepositoryProvider).deleteCoupon(coupon.id);
      ref.invalidate(couponsListProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('ລົບບໍ່ສຳເລັດ: $e')));
      }
    }
  }
}

// ─── Coupon Tile ──────────────────────────────────────────────────────────────

class _CouponTile extends StatelessWidget {
  const _CouponTile({
    required this.coupon,
    required this.onEdit,
    required this.onDelete,
  });

  final Coupon coupon;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final active = coupon.isEffectivelyActive;
    final fmt = NumberFormat('#,##0.##');

    return ListTile(
      contentPadding:
          EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: CircleAvatar(
        backgroundColor:
            active ? theme.colorScheme.primary : Colors.grey.shade300,
        foregroundColor:
            active ? theme.colorScheme.onPrimary : Colors.grey,
        child: const Icon(Icons.confirmation_number_outlined, size: 20),
      ),
      title: Row(
        children: [
          Expanded(
            child: Text(
              coupon.code,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: coupon.code));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('ຄັດລອກລະຫັດຄູປອງແລ້ວ'),
                    duration: Duration(seconds: 1)),
              );
            },
            child: const Icon(Icons.copy, size: 16, color: Colors.grey),
          ),
        ],
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(coupon.name, style: TextStyle(fontSize: 12.sp)),
          SizedBox(height: 2.h),
          Row(
            children: [
              _Chip(
                label: coupon.type == CouponType.percent
                    ? '${fmt.format(coupon.value)}%'
                    : '₭${fmt.format(coupon.value)}',
                color: theme.colorScheme.secondaryContainer,
              ),
              SizedBox(width: 4.w),
              _Chip(
                label: coupon.typeLabel,
                color: theme.colorScheme.tertiaryContainer,
              ),
              SizedBox(width: 4.w),
              if (coupon.usageLimit != null)
                _Chip(
                  label:
                      '${coupon.usageCount}/${coupon.usageLimit}',
                  color: Colors.grey.shade200,
                ),
            ],
          ),
          if (coupon.expiresAt != null) ...[
            SizedBox(height: 2.h),
            Text(
              coupon.isExpired
                  ? 'ໝົດອາຍຸ ${DateFormat('dd/MM/yy').format(coupon.expiresAt!)}'
                  : 'ໝົດອາຍຸ ${DateFormat('dd/MM/yy').format(coupon.expiresAt!)}',
              style: TextStyle(
                  fontSize: 11.sp,
                  color: coupon.isExpired ? Colors.red : Colors.black54),
            ),
          ],
        ],
      ),
      trailing: PopupMenuButton<String>(
        onSelected: (v) {
          if (v == 'edit') onEdit();
          if (v == 'delete') onDelete();
        },
        itemBuilder: (_) => const [
          PopupMenuItem(value: 'edit', child: Text('ແກ້ໄຂ')),
          PopupMenuItem(
              value: 'delete',
              child: Text('ລົບ', style: TextStyle(color: Colors.red))),
        ],
      ),
      isThreeLine: true,
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.h),
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(4.r)),
      child: Text(label, style: TextStyle(fontSize: 10.sp)),
    );
  }
}
