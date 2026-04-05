import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/theme/theme_notifier.dart';

class ThemeSettingsPage extends ConsumerWidget {
  const ThemeSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentMode = ref.watch(themeNotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('ຕັ້ງຄ່າທີມ')),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Text(
            'ເລືອກລູບແບບສີຂອງແອັບ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 12.h),

          // ── Mode options ──────────────────────────────────────────
          Card(
            child: Column(
              children: [
                _ThemeOptionTile(
                  icon: Icons.brightness_auto_outlined,
                  title: 'ຕາມລະບົບ',
                  subtitle: 'ປ່ຽນຕາມການຕັ້ງຄ່າຂອງອຸປະກອນ',
                  value: AppThemeMode.system,
                  groupValue: currentMode,
                  onChanged: (v) =>
                      ref.read(themeNotifierProvider.notifier).setMode(v),
                ),
                const Divider(height: 1),
                _ThemeOptionTile(
                  icon: Icons.light_mode_outlined,
                  title: 'ໂໝດສະຫວ່າງ',
                  subtitle: 'ພື້ນຫຼັງສີຂາວ',
                  value: AppThemeMode.light,
                  groupValue: currentMode,
                  onChanged: (v) =>
                      ref.read(themeNotifierProvider.notifier).setMode(v),
                ),
                const Divider(height: 1),
                _ThemeOptionTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'ໂໝດມືດ',
                  subtitle: 'ພື້ນຫຼັງສີເຂັ້ມ ຖະຫນອມສາຍຕາ',
                  value: AppThemeMode.dark,
                  groupValue: currentMode,
                  onChanged: (v) =>
                      ref.read(themeNotifierProvider.notifier).setMode(v),
                ),
              ],
            ),
          ),

          SizedBox(height: 24.h),

          // ── Preview ───────────────────────────────────────────────
          Text('ຕົວຢ່າງ', style: theme.textTheme.titleSmall),
          SizedBox(height: 8.h),
          _ThemePreview(theme: theme),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Option tile
// ─────────────────────────────────────────────────────────────────────────────

class _ThemeOptionTile extends StatelessWidget {
  const _ThemeOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final AppThemeMode value;
  final AppThemeMode groupValue;
  final void Function(AppThemeMode) onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSelected = value == groupValue;

    return ListTile(
      leading: Icon(icon,
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.onSurface.withValues(alpha: 0.5)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: isSelected
          ? Icon(Icons.check_circle, color: theme.colorScheme.primary)
          : const Icon(Icons.radio_button_unchecked),
      selected: isSelected,
      onTap: () => onChanged(value),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Preview widget
// ─────────────────────────────────────────────────────────────────────────────

class _ThemePreview extends StatelessWidget {
  const _ThemePreview({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fake AppBar
          Container(
            width: double.infinity,
            height: 40.h,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(4.r),
            ),
            child: Text(
              'ແຖບດ້ານເທິງ',
              style: TextStyle(
                color: theme.colorScheme.onPrimary,
                fontSize: 12.sp,
              ),
            ),
          ),
          SizedBox(height: 8.h),
          // Fake cards
          Row(
            children: [
              Expanded(
                child: _FakeCard(
                  color: theme.colorScheme.primaryContainer,
                  label: 'ກາດ',
                  theme: theme,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _FakeCard(
                  color: theme.colorScheme.secondaryContainer,
                  label: 'ຂໍ້ມູນ',
                  theme: theme,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FakeCard extends StatelessWidget {
  const _FakeCard({
    required this.color,
    required this.label,
    required this.theme,
  });

  final Color color;
  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.h,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4.r),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(fontSize: 11.sp),
      ),
    );
  }
}
