import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Reusable Numpad Widget
// ─────────────────────────────────────────────────────────────────────────────
/// A standard 0-9 numpad with C (clear), backspace, and optional decimal.
/// [onChanged] fires each time the value changes.
/// [maxDecimalPlaces] limits decimal input (0 = integer only).
class NumpadWidget extends StatelessWidget {
  const NumpadWidget({
    super.key,
    required this.value,
    required this.onChanged,
    this.maxDecimalPlaces = 2,
    this.showDecimal = true,
    this.quickAmounts,
  });

  final String value;
  final ValueChanged<String> onChanged;
  final int maxDecimalPlaces;
  final bool showDecimal;
  /// Optional quick-tap amount buttons shown above the numpad (e.g. [100, 500, 1000]).
  final List<double>? quickAmounts;

  void _press(String key) {
    String val = value;
    if (key == 'C') {
      onChanged('0');
    } else if (key == '⌫') {
      if (val.length <= 1) {
        onChanged('0');
      } else {
        onChanged(val.substring(0, val.length - 1));
      }
    } else if (key == '.') {
      if (!showDecimal || val.contains('.')) return;
      onChanged('$val.');
    } else {
      if (val == '0') {
        onChanged(key);
      } else {
        // Enforce decimal places
        if (val.contains('.')) {
          final decimals = val.split('.').last.length;
          if (decimals >= maxDecimalPlaces) return;
        }
        onChanged('$val$key');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Quick amount buttons
        if (quickAmounts != null) ...[
          Row(
            children: quickAmounts!
                .map((a) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: OutlinedButton(
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            onChanged(a == a.truncateToDouble()
                                ? a.toInt().toString()
                                : a.toString());
                          },
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: 8.h),
                            textStyle: TextStyle(fontSize: 12.sp),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          ),
                          child: Text(a == a.truncateToDouble()
                              ? a.toInt().toString()
                              : a.toString()),
                        ),
                      ),
                    ))
                .toList(),
          ),
          SizedBox(height: 6.h),
        ],
        // Numpad grid
        for (final row in [
          ['7', '8', '9'],
          ['4', '5', '6'],
          ['1', '2', '3'],
          [showDecimal ? '.' : 'C', '0', '⌫'],
        ])
          Row(
            children: row.map((k) => _NumpadKey(label: k, onTap: () => _press(k))).toList(),
          ),
      ],
    );
  }
}

class _NumpadKey extends StatelessWidget {
  const _NumpadKey({
    required this.label,
    required this.onTap,
  });
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDanger = label == 'C';
    final isBackspace = label == '⌫';
    return Expanded(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Material(
          color: isDanger
              ? Colors.red.shade50
              : isBackspace
                  ? Colors.orange.shade50
                  : const Color(0xFFF5F5F7),
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: SizedBox(
              height: 52.h,
              child: Center(
                child: isBackspace
                    ? Icon(Icons.backspace_outlined,
                        size: 20.sp, color: Colors.orange.shade700)
                    : Text(
                        label,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                          color: isDanger ? Colors.red.shade700 : Colors.black87,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
