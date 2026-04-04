import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/locale_notifier.dart';

class LanguageSwitcher extends ConsumerWidget {
  const LanguageSwitcher({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(appLocaleProvider).languageCode;

    if (compact) {
      return SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'th', label: Text('TH')),
          ButtonSegment(value: 'en', label: Text('EN')),
          ButtonSegment(value: 'lo', label: Text('LO')),
        ],
        selected: {current},
        onSelectionChanged: (s) {
          ref.read(appLocaleProvider.notifier).setLocaleCode(s.first);
        },
      );
    }

    return DropdownButton<String>(
      value: current,
      underline: const SizedBox.shrink(),
      items: const [
        DropdownMenuItem(value: 'th', child: Text('TH')),
        DropdownMenuItem(value: 'en', child: Text('EN')),
        DropdownMenuItem(value: 'lo', child: Text('LO')),
      ],
      onChanged: (v) {
        if (v != null) {
          ref.read(appLocaleProvider.notifier).setLocaleCode(v);
        }
      },
    );
  }
}
