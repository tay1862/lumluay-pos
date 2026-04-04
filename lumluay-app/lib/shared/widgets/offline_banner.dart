import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/services/connectivity_bloc.dart';

/// Animated banner that slides in when the device goes offline.
class OfflineBanner extends ConsumerWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectAsync = ref.watch(connectivityBlocStreamProvider);
    final state = connectAsync.valueOrNull;
    final isOnline = state is! ConnectivityOffline;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 300),
      offset: isOnline ? const Offset(0, -1) : Offset.zero,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isOnline ? 0 : 1,
        child: Container(
          width: double.infinity,
          color: Colors.grey.shade800,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            children: [
              Icon(Icons.wifi_off, color: Colors.white70, size: 16.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'ออฟไลน์ — ข้อมูลจะ sync เมื่อกลับมาออนไลน์',
                  style: TextStyle(
                      color: Colors.white, fontSize: 12.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
