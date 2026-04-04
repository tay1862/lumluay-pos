import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// A PIN dialog that collects a 4- or 6-digit PIN for permission verification.
///
/// Returns the entered PIN string, or null if cancelled.
class PinDialog extends StatefulWidget {
  const PinDialog({
    super.key,
    this.title = 'ยืนยัน PIN',
    this.subtitle,
    this.pinLength = 4,
    this.verifyPin,
  });

  final String title;
  final String? subtitle;
  final int pinLength;

  /// Optional async validator. Return true if PIN is accepted.
  final Future<bool> Function(String pin)? verifyPin;

  static Future<String?> show(
    BuildContext context, {
    String title = 'ยืนยัน PIN',
    String? subtitle,
    int pinLength = 4,
    Future<bool> Function(String pin)? verifyPin,
  }) =>
      showDialog<String>(
        context: context,
        builder: (_) => PinDialog(
          title: title,
          subtitle: subtitle,
          pinLength: pinLength,
          verifyPin: verifyPin,
        ),
      );

  @override
  State<PinDialog> createState() => _PinDialogState();
}

class _PinDialogState extends State<PinDialog> {
  String _pin = '';
  String? _error;
  bool _loading = false;

  void _press(String key) {
    if (_loading) return;
    setState(() {
      _error = null;
      if (key == '⌫') {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      } else {
        if (_pin.length < widget.pinLength) _pin += key;
      }
    });
    HapticFeedback.lightImpact();
    if (_pin.length == widget.pinLength) _submit();
  }

  Future<void> _submit() async {
    if (widget.verifyPin == null) {
      Navigator.of(context).pop(_pin);
      return;
    }
    setState(() => _loading = true);
    final ok = await widget.verifyPin!(_pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(_pin);
    } else {
      setState(() {
        _error = 'PIN ไม่ถูกต้อง';
        _pin = '';
        _loading = false;
      });
      HapticFeedback.heavyImpact();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 320.w),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.title,
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center),
              if (widget.subtitle != null) ...[
                SizedBox(height: 4.h),
                Text(widget.subtitle!,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: Colors.black54),
                    textAlign: TextAlign.center),
              ],
              SizedBox(height: 20.h),

              // Dot indicators
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(widget.pinLength, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.symmetric(horizontal: 6.w),
                    width: 14.w,
                    height: 14.w,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled
                          ? (_error != null
                              ? Colors.red
                              : theme.colorScheme.primary)
                          : Colors.grey.shade300,
                    ),
                  );
                }),
              ),

              if (_error != null) ...[
                SizedBox(height: 8.h),
                Text(_error!,
                    style: TextStyle(
                        color: Colors.red.shade600, fontSize: 12.sp),
                    textAlign: TextAlign.center),
              ],
              SizedBox(height: 16.h),

              // Keypad
              if (_loading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 24.h),
                  child: const CircularProgressIndicator(),
                )
              else
                _buildKeypad(theme),

              SizedBox(height: 8.h),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ยกเลิก'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    final keys = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];
    return Column(
      children: keys.map((row) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: row.map((k) {
            if (k.isEmpty) return SizedBox(width: 72.w, height: 56.h);
            return _PinKey(label: k, onTap: () => _press(k));
          }).toList(),
        );
      }).toList(),
    );
  }
}

class _PinKey extends StatelessWidget {
  const _PinKey({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(4.w),
      child: SizedBox(
        width: 64.w,
        height: 52.h,
        child: Material(
          color: Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10.r),
          child: InkWell(
            borderRadius: BorderRadius.circular(10.r),
            onTap: onTap,
            child: Center(
              child: label == '⌫'
                  ? Icon(Icons.backspace_outlined,
                      size: 20.sp, color: Colors.orange.shade700)
                  : Text(label,
                      style: TextStyle(
                          fontSize: 20.sp, fontWeight: FontWeight.w600)),
            ),
          ),
        ),
      ),
    );
  }
}
