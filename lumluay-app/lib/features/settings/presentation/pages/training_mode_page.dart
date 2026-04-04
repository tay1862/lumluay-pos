import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

/// Whether the app is running in training (demo) mode.
/// In this mode, all transactions are marked with `_training: true`
/// and data is never sent to production.
final trainingModeProvider = StateNotifierProvider<_TrainingModeNotifier, bool>(
  (ref) => _TrainingModeNotifier(),
);

class _TrainingModeNotifier extends StateNotifier<bool> {
  static const _kKey = 'training_mode';

  _TrainingModeNotifier() : super(false) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = prefs.getBool(_kKey) ?? false;
  }

  Future<void> setTrainingMode(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kKey, value);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

class TrainingModePage extends ConsumerWidget {
  const TrainingModePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTraining = ref.watch(trainingModeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('โหมดฝึกอบรม')),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // ── Status banner ─────────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isTraining
                  ? Colors.orange.withValues(alpha: 0.15)
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isTraining
                    ? Colors.orange
                    : theme.colorScheme.outline.withValues(alpha: 0.3),
                width: isTraining ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isTraining ? Icons.school : Icons.school_outlined,
                  size: 32.sp,
                  color: isTraining ? Colors.orange : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isTraining ? 'โหมดฝึกอบรมเปิดอยู่' : 'โหมดฝึกอบรมปิดอยู่',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: isTraining ? Colors.orange.shade800 : null,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isTraining
                            ? 'ข้อมูลทุกอย่างจะถูกทำเครื่องหมายว่าเป็นการฝึกอบรม'
                            : 'แอปทำงานในโหมดปกติ',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          SizedBox(height: 16.h),

          // ── Toggle ────────────────────────────────────────────────
          Card(
            child: SwitchListTile(
              secondary: Icon(
                Icons.school,
                color: isTraining ? Colors.orange : null,
              ),
              title: const Text('เปิดโหมดฝึกอบรม'),
              subtitle: const Text('สำหรับฝึกพนักงานใหม่'),
              value: isTraining,
              activeColor: Colors.orange,
              onChanged: (value) async {
                if (value) {
                  // Confirm before enabling
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: const Text('เปิดโหมดฝึกอบรม?'),
                      content: const Text(
                        'ในโหมดนี้:\n'
                        '• ออเดอร์และการชำระเงินจะถูกทำเครื่องหมาย "ฝึกอบรม"\n'
                        '• ข้อมูลจะไม่กระทบกับรายงานยอดขายจริง\n'
                        '• เหมาะสำหรับฝึกพนักงานใหม่\n\n'
                        'ต้องการเปิดโหมดฝึกอบรมใช่ไหม?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: const Text('ยกเลิก'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.orange,
                          ),
                          onPressed: () => Navigator.pop(context, true),
                          child: const Text('เปิดโหมดฝึกอบรม'),
                        ),
                      ],
                    ),
                  );
                  if (confirmed != true) return;
                }
                await ref
                    .read(trainingModeProvider.notifier)
                    .setTrainingMode(value);
              },
            ),
          ),

          SizedBox(height: 16.h),

          // ── Description ───────────────────────────────────────────
          Card(
            child: Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('โหมดฝึกอบรมคืออะไร?',
                      style: theme.textTheme.titleSmall),
                  SizedBox(height: 8.h),
                  _BulletPoint(
                    icon: Icons.check_circle_outline,
                    text: 'ฝึกพนักงานใหม่โดยไม่กระทบข้อมูลจริง',
                    theme: theme,
                  ),
                  _BulletPoint(
                    icon: Icons.check_circle_outline,
                    text: 'สร้างออเดอร์ทดลองได้อย่างปลอดภัย',
                    theme: theme,
                  ),
                  _BulletPoint(
                    icon: Icons.check_circle_outline,
                    text: 'ยอดขายและรายงานจะแยกออกจากข้อมูลจริง',
                    theme: theme,
                  ),
                  _BulletPoint(
                    icon: Icons.warning_amber_outlined,
                    text: 'ข้อมูลฝึกอบรมไม่สามารถนำมาคิดเงินจริงได้',
                    theme: theme,
                    color: Colors.orange,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BulletPoint extends StatelessWidget {
  const _BulletPoint({
    required this.icon,
    required this.text,
    required this.theme,
    this.color,
  });

  final IconData icon;
  final String text;
  final ThemeData theme;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 16.sp,
            color: color ?? theme.colorScheme.primary,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(text, style: theme.textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
