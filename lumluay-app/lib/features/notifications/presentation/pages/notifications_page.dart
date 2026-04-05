import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import '../../data/notifications_repository.dart';
import '../../../../core/theme/app_theme.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(notificationsListProvider);
    final unreadOnly = ref.watch(notificationsUnreadOnlyProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        title: const Text('ການແຈ້ງເຕືອນ'),
        actions: [
          FilterChip(
            label: const Text('ຍັງບໍ່ໄດ້ອ່ານ'),
            selected: unreadOnly,
            onSelected: (v) =>
                ref.read(notificationsUnreadOnlyProvider.notifier).state = v,
            selectedColor: AppColors.primary.withValues(alpha: 0.15),
            checkmarkColor: AppColors.primary,
          ),
          SizedBox(width: 4.w),
          PopupMenuButton(
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'readAll',
                child: Row(
                  children: [
                    Icon(Icons.done_all, size: 18),
                    SizedBox(width: 8),
                    Text('ອ່ານທັງໝົດ'),
                  ],
                ),
              ),
            ],
            onSelected: (v) async {
              if (v == 'readAll') {
                await ref
                    .read(notificationsRepositoryProvider)
                    .markAllAsRead();
                ref.invalidate(notificationsListProvider);
              }
            },
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('ເກີດຂໍ້ຜິດພາດ: $e')),
        data: (notifications) {
          if (notifications.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.notifications_none,
                      size: 64, color: Colors.black26),
                  SizedBox(height: 12.h),
                  Text(
                    unreadOnly ? 'ບໍ່ມີແຈ້ງເຕືອນທີ່ຍັງບໍ່ໄດ້ອ່ານ' : 'ຍັງບໍ່ມີການແຈ້ງເຕືອນ',
                    style: const TextStyle(color: Colors.black45),
                  ),
                ],
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                ref.invalidate(notificationsListProvider),
            child: ListView.separated(
              padding: EdgeInsets.all(12.w),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => SizedBox(height: 6.h),
              itemBuilder: (ctx, i) =>
                  _NotificationCard(notification: notifications[i]),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Notification card
// ─────────────────────────────────────────────────────────────────────────────
class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});
  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeFmt = DateFormat('d MMM HH:mm', 'th_TH');

    return Dismissible(
      key: Key(notification.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: 20.w),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) async {
        await ref
            .read(notificationsRepositoryProvider)
            .deleteNotification(notification.id);
        ref.invalidate(notificationsListProvider);
      },
      child: GestureDetector(
        onTap: () async {
          if (!notification.isRead) {
            await ref
                .read(notificationsRepositoryProvider)
                .markAsRead(notification.id);
            ref.invalidate(notificationsListProvider);
          }
        },
        child: Container(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: notification.isRead ? Colors.white : AppColors.primary.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(14.r),
            border: notification.isRead
                ? null
                : Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 42.w,
                height: 42.w,
                decoration: BoxDecoration(
                  color: _typeColor(notification.type)
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(
                  _typeIcon(notification.type),
                  color: _typeColor(notification.type),
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.sp),
                          ),
                        ),
                        if (!notification.isRead)
                          Container(
                            width: 8.w,
                            height: 8.w,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      notification.body,
                      style: TextStyle(
                          fontSize: 11.sp, color: Colors.black54),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      timeFmt.format(notification.createdAt),
                      style: TextStyle(
                          fontSize: 10.sp, color: Colors.black38),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'order':
        return Icons.receipt_long_outlined;
      case 'stock':
        return Icons.inventory_2_outlined;
      case 'kitchen':
        return Icons.restaurant_outlined;
      case 'payment':
        return Icons.payment_outlined;
      case 'system':
        return Icons.settings_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'order':
        return Colors.blue;
      case 'stock':
        return Colors.orange;
      case 'kitchen':
        return Colors.green;
      case 'payment':
        return const Color(0xFF1A7F64);
      case 'system':
        return Colors.grey.shade600;
      default:
        return AppColors.primary;
    }
  }
}
