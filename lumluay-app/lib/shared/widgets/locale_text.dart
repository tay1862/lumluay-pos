import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/localization/locale_notifier.dart';

class LocaleText extends ConsumerWidget {
  const LocaleText(
    this.value, {
    super.key,
    this.style,
    this.maxLines,
    this.overflow,
    this.fallback = '',
  });

  final dynamic value;
  final TextStyle? style;
  final int? maxLines;
  final TextOverflow? overflow;
  final String fallback;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localeCode = ref.watch(appLocaleProvider).languageCode;
    final text = _pickLocaleText(value, localeCode) ?? fallback;
    return Text(
      text,
      style: style,
      maxLines: maxLines,
      overflow: overflow,
    );
  }

  String? _pickLocaleText(dynamic raw, String localeCode) {
    if (raw == null) return null;
    if (raw is String) return raw;
    if (raw is Map) {
      final m = raw.map((k, v) => MapEntry('$k', '$v'));
      return m[localeCode] ?? m['th'] ?? m['en'] ?? m.values.firstOrNull;
    }
    return '$raw';
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull => isEmpty ? null : first;
}
