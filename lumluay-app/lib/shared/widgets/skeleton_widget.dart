import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A shimmer-effect skeleton loading widget.
///
/// Usage:
/// ```dart
/// SkeletonBox(width: 200, height: 20)
/// SkeletonListTile()
/// SkeletonCard(lines: 3)
/// ```
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height.h,
        decoration: BoxDecoration(
          borderRadius: widget.borderRadius ?? BorderRadius.circular(4.r),
          gradient: LinearGradient(
            colors: [
              Color.lerp(Colors.grey.shade300, Colors.grey.shade100, _anim.value)!,
              Color.lerp(Colors.grey.shade100, Colors.grey.shade300, _anim.value)!,
            ],
          ),
        ),
      ),
    );
  }
}

/// A skeleton for a ListTile (icon + two lines).
class SkeletonListTile extends StatelessWidget {
  const SkeletonListTile({super.key, this.hasAvatar = true});
  final bool hasAvatar;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      child: Row(
        children: [
          if (hasAvatar) ...[
            SkeletonBox(width: 40.w, height: 40, borderRadius: BorderRadius.circular(20.r)),
            SizedBox(width: 12.w),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14),
                SizedBox(height: 6.h),
                SkeletonBox(width: 120.w, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A skeleton card with [lines] lines of text.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.lines = 3, this.showHeader = true});
  final int lines;
  final bool showHeader;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showHeader) ...[
              SkeletonBox(width: 140.w, height: 16),
              SizedBox(height: 12.h),
            ],
            ...List.generate(lines, (i) => Padding(
                  padding: EdgeInsets.only(bottom: 8.h),
                  child: SkeletonBox(
                    width: i == lines - 1 ? 100.w : null,
                    height: 13,
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

/// A skeleton grid of [count] product-card shaped items.
class SkeletonProductGrid extends StatelessWidget {
  const SkeletonProductGrid({super.key, this.count = 6});
  final int count;

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.all(8.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.85,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.w,
      ),
      itemCount: count,
      itemBuilder: (_, __) => Column(
        children: [
          Expanded(
            child: SkeletonBox(
              borderRadius: BorderRadius.circular(8.r),
            ),
          ),
          SizedBox(height: 6.h),
          SkeletonBox(height: 12),
          SizedBox(height: 4.h),
          SkeletonBox(width: 60.w, height: 11),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EmptyStateWidget — 18.5.3
// ─────────────────────────────────────────────────────────────────────────────

/// Generic empty-state placeholder.
///
/// ```dart
/// EmptyStateWidget(
///   icon: Icons.inventory_2_outlined,
///   message: 'ບໍ່ມີສິນຄ້າ',
///   actionLabel: 'ເພີ່ມສິນຄ້າ',
///   onAction: () { ... },
/// )
/// ```
class EmptyStateWidget extends StatelessWidget {
  const EmptyStateWidget({
    super.key,
    required this.icon,
    required this.message,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String message;
  final String? subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64.sp, color: Colors.grey[400]),
            SizedBox(height: 16.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              SizedBox(height: 6.h),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 13.sp, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: 24.h),
              FilledButton.icon(
                onPressed: onAction,
                icon: const Icon(Icons.add),
                label: Text(actionLabel!),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ErrorStateWidget — 18.5.4
// ─────────────────────────────────────────────────────────────────────────────

/// Generic error-state with an optional retry button.
///
/// ```dart
/// ErrorStateWidget(
///   message: 'ບໍ່ສາມາດໂຫຼດຂໍ້ມູນໄດ້',
///   onRetry: () { ref.invalidate(myProvider); },
/// )
/// ```
class ErrorStateWidget extends StatelessWidget {
  const ErrorStateWidget({
    super.key,
    this.message = 'ເກີດຂໍ້ຜິດພາດ ກະລຸນາລອງໃໝ່ອີກຄັ້ງ',
    this.detail,
    this.onRetry,
  });

  final String message;
  final String? detail;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 64.sp, color: Colors.red[300]),
            SizedBox(height: 16.h),
            Text(
              message,
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
            if (detail != null) ...[
              SizedBox(height: 6.h),
              Text(
                detail!,
                style: TextStyle(fontSize: 12.sp, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],
            if (onRetry != null) ...[
              SizedBox(height: 24.h),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('ລອງໃໝ່'),
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
