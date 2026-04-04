import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Centered circular progress indicator with optional overlay.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({super.key, this.overlay = false, this.message});

  /// If true, renders a semi-transparent overlay over the full screen.
  final bool overlay;
  final String? message;

  static Future<T> wrap<T>(
    BuildContext context,
    Future<T> Function() action, {
    String? message,
  }) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppLoadingIndicator(overlay: true, message: message),
    );
    try {
      final result = await action();
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      return result;
    } catch (e) {
      if (context.mounted) Navigator.of(context, rootNavigator: true).pop();
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final indicator = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 40.w,
          height: 40.w,
          child: const CircularProgressIndicator(),
        ),
        if (message != null) ...[
          SizedBox(height: 12.h),
          Text(
            message!,
            style: TextStyle(fontSize: 14.sp),
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );

    if (!overlay) {
      return Center(child: Padding(padding: EdgeInsets.all(24.w), child: indicator));
    }

    return Material(
      color: Colors.transparent,
      child: Container(
        color: Colors.black.withValues(alpha: 0.4),
        alignment: Alignment.center,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
          child: Padding(padding: EdgeInsets.all(24.w), child: indicator),
        ),
      ),
    );
  }
}
