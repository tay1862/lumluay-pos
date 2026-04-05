import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../core/services/connectivity_bloc.dart';
import '../../core/sync/sync_engine.dart';
import '../../core/sync/sync_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// 16.2.10 — Sync Status Indicator
// ─────────────────────────────────────────────────────────────────────────────

class SyncStatusIndicator extends ConsumerWidget {
  const SyncStatusIndicator({super.key, required this.expanded});

  final bool expanded;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityBlocStreamProvider);
    final syncState = ref.watch(syncNotifierProvider);

    final isOnline =
        connectivityAsync.maybeWhen(data: (s) => s is ConnectivityOnline, orElse: () => false);

    final Color dotColor;
    final String label;
    final Widget? trailingWidget;

    if (!isOnline) {
      dotColor = Theme.of(context).colorScheme.error;
      label = 'ອອບໄລນ໌';
      trailingWidget = null;
    } else if (syncState.isSyncing) {
      dotColor = Theme.of(context).colorScheme.primary;
      label = 'ກຳລັງຊິງຄ໌...';
      trailingWidget = SizedBox(
        width: 12.w,
        height: 12.w,
        child: CircularProgressIndicator(strokeWidth: 2, color: dotColor),
      );
    } else if (syncState.hasError) {
      dotColor = Colors.orange;
      label = 'ຊິງຄ໌ລົ້ມເຫຼວ';
      trailingWidget = null;
    } else if (syncState.pendingCount > 0) {
      dotColor = Colors.orange;
      label = 'ລໍຊິງຄ໌ ${syncState.pendingCount}';
      trailingWidget = null;
    } else {
      dotColor = Colors.green;
      label = syncState.lastSyncAt != null ? 'ຊິງຄ໌ແລ້ວ' : 'ອອນໄລນ໌';
      trailingWidget = null;
    }

    final dot = Container(
      width: 8.w,
      height: 8.w,
      decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
    );

    if (!expanded) {
      return Tooltip(
        message: label,
        child: GestureDetector(
          onTap: isOnline ? () => ref.read(syncEngineProvider).performSync() : null,
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 6.h),
            child: dot,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: isOnline && !syncState.isSyncing
          ? () => ref.read(syncEngineProvider).performSync()
          : null,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 6.h),
        child: Row(
          children: [
            dot,
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                label,
                style: TextStyle(fontSize: 11.sp, color: Colors.black54),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (trailingWidget != null) ...[
              SizedBox(width: 4.w),
              trailingWidget,
            ],
          ],
        ),
      ),
    );
  }
}
