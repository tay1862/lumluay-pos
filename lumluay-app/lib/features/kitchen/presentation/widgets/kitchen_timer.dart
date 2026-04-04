import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class KitchenTimer extends StatefulWidget {
  final DateTime startedAt;

  const KitchenTimer({super.key, required this.startedAt});

  @override
  State<KitchenTimer> createState() => _KitchenTimerState();
}

class _KitchenTimerState extends State<KitchenTimer> {
  late Timer _timer;
  bool _blink = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _blink = !_blink;
      });
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(widget.startedAt);
    final minutes = elapsed.inMinutes;
    final seconds = elapsed.inSeconds % 60;

    Color color;
    if (minutes >= 10) {
      color = _blink ? Colors.redAccent : Colors.red[300]!;
    } else if (minutes >= 5) {
      color = Colors.amber;
    } else {
      color = Colors.lightGreenAccent;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: color),
      ),
      child: Text(
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
        style: TextStyle(
          color: color,
          fontSize: 12.sp,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
