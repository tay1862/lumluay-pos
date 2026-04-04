import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lumluay_pos/l10n/generated/app_localizations.dart';
import '../../../../core/localization/locale_notifier.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Page
// ─────────────────────────────────────────────────────────────────────────────

const _kLocales = [
  _LocaleOption(
    code: 'th',
    label: 'ภาษาไทย',
    flag: '🇹🇭',
    nativeName: 'ไทย',
  ),
  _LocaleOption(
    code: 'en',
    label: 'English',
    flag: '🇺🇸',
    nativeName: 'English',
  ),
  _LocaleOption(
    code: 'lo',
    label: 'ພາສາລາວ',
    flag: '🇱🇦',
    nativeName: 'ລາວ',
  ),
];

class _LocaleOption {
  final String code;
  final String label;
  final String flag;
  final String nativeName;

  const _LocaleOption({
    required this.code,
    required this.label,
    required this.flag,
    required this.nativeName,
  });
}

class LanguageSettingsPage extends ConsumerWidget {
  const LanguageSettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final currentLocale = ref.watch(appLocaleProvider).languageCode;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.languageSettingsTitle)),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          Text(
            l10n.languageSettingsDescription,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          SizedBox(height: 12.h),
          Card(
            child: Column(
              children: _kLocales.asMap().entries.map((entry) {
                final i = entry.key;
                final opt = entry.value;
                final isSelected = opt.code == currentLocale;

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (i > 0) const Divider(height: 1),
                    ListTile(
                      leading: Text(
                        opt.flag,
                        style: TextStyle(fontSize: 28.sp),
                      ),
                      title: Text(opt.label),
                      subtitle: Text(opt.nativeName),
                      trailing: isSelected
                          ? Icon(Icons.check_circle,
                              color: theme.colorScheme.primary)
                          : const Icon(Icons.radio_button_unchecked),
                      selected: isSelected,
                      onTap: () async {
                        await ref
                            .read(appLocaleProvider.notifier)
                            .setLocaleCode(opt.code);
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10n.languageChanged(opt.label)),
                            ),
                          );
                        }
                      },
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16.h),
          Card(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.4),
            child: Padding(
              padding: EdgeInsets.all(12.w),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 16.sp,
                      color: theme.colorScheme.primary),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      l10n.languageSupportHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
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
