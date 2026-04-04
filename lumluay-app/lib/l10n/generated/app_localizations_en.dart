// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'LUMLUAY POS';

  @override
  String get languageSettingsTitle => 'Language Settings';

  @override
  String get languageSettingsDescription => 'Select your preferred language';

  @override
  String languageChanged(Object language) {
    return 'Language changed to $language';
  }

  @override
  String get localeThai => 'Thai';

  @override
  String get localeEnglish => 'English';

  @override
  String get localeLao => 'Lao';

  @override
  String get languageSupportHint =>
      'Some content may still appear in Thai depending on source support.';

  @override
  String get setupWizardTitle => 'Setup Wizard';

  @override
  String get next => 'Next';

  @override
  String get back => 'Back';

  @override
  String get finish => 'Finish';

  @override
  String get save => 'Save';

  @override
  String get cancel => 'Cancel';

  @override
  String get delete => 'Delete';

  @override
  String get confirm => 'Confirm';

  @override
  String get retry => 'Retry';

  @override
  String get loading => 'Loading...';

  @override
  String get errorOccurred => 'An error occurred';

  @override
  String get settings => 'Settings';
}
