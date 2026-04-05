import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_lo.dart';
import 'app_localizations_th.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('lo'),
    Locale('th'),
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'LUMLUAY POS'**
  String get appTitle;

  /// No description provided for @languageSettingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Language Settings'**
  String get languageSettingsTitle;

  /// No description provided for @languageSettingsDescription.
  ///
  /// In en, this message translates to:
  /// **'Select your preferred language'**
  String get languageSettingsDescription;

  /// No description provided for @languageChanged.
  ///
  /// In en, this message translates to:
  /// **'Language changed to {language}'**
  String languageChanged(Object language);

  /// No description provided for @localeThai.
  ///
  /// In en, this message translates to:
  /// **'Thai'**
  String get localeThai;

  /// No description provided for @localeEnglish.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get localeEnglish;

  /// No description provided for @localeLao.
  ///
  /// In en, this message translates to:
  /// **'Lao'**
  String get localeLao;

  /// No description provided for @languageSupportHint.
  ///
  /// In en, this message translates to:
  /// **'Some content may still appear in Thai depending on source support.'**
  String get languageSupportHint;

  /// No description provided for @setupWizardTitle.
  ///
  /// In en, this message translates to:
  /// **'Setup Wizard'**
  String get setupWizardTitle;

  /// No description provided for @next.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;

  /// No description provided for @finish.
  ///
  /// In en, this message translates to:
  /// **'Finish'**
  String get finish;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get confirm;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No description provided for @loading.
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// No description provided for @errorOccurred.
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get errorOccurred;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @setupWizardCompleted.
  ///
  /// In en, this message translates to:
  /// **'Setup wizard completed.'**
  String get setupWizardCompleted;

  /// No description provided for @setupWizardStoreNameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a store name'**
  String get setupWizardStoreNameRequired;

  /// No description provided for @setupWizardSeedSampleDataFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not seed sample data'**
  String get setupWizardSeedSampleDataFailed;

  /// No description provided for @setupWizardStaffInfoIncomplete.
  ///
  /// In en, this message translates to:
  /// **'Complete the staff information (password must be at least 8 characters)'**
  String get setupWizardStaffInfoIncomplete;

  /// No description provided for @setupWizardStepStoreInfo.
  ///
  /// In en, this message translates to:
  /// **'Store Information'**
  String get setupWizardStepStoreInfo;

  /// No description provided for @setupWizardStepCurrencyTax.
  ///
  /// In en, this message translates to:
  /// **'Currency and Tax'**
  String get setupWizardStepCurrencyTax;

  /// No description provided for @setupWizardStepPrinters.
  ///
  /// In en, this message translates to:
  /// **'Printers'**
  String get setupWizardStepPrinters;

  /// No description provided for @setupWizardStepProductImport.
  ///
  /// In en, this message translates to:
  /// **'Import Products'**
  String get setupWizardStepProductImport;

  /// No description provided for @setupWizardStepCreateStaff.
  ///
  /// In en, this message translates to:
  /// **'Create Staff'**
  String get setupWizardStepCreateStaff;

  /// No description provided for @setupWizardStepProgress.
  ///
  /// In en, this message translates to:
  /// **'Setup Wizard • Step {currentStep}/{totalSteps}'**
  String setupWizardStepProgress(int currentStep, int totalSteps);

  /// No description provided for @setupWizardStoreName.
  ///
  /// In en, this message translates to:
  /// **'Store Name'**
  String get setupWizardStoreName;

  /// No description provided for @setupWizardOwnerName.
  ///
  /// In en, this message translates to:
  /// **'Owner / Administrator'**
  String get setupWizardOwnerName;

  /// No description provided for @setupWizardPhone.
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get setupWizardPhone;

  /// No description provided for @setupWizardAddress.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get setupWizardAddress;

  /// No description provided for @setupWizardTaxId.
  ///
  /// In en, this message translates to:
  /// **'Tax ID'**
  String get setupWizardTaxId;

  /// No description provided for @setupWizardDefaultCurrency.
  ///
  /// In en, this message translates to:
  /// **'Default Currency'**
  String get setupWizardDefaultCurrency;

  /// No description provided for @setupWizardVatRate.
  ///
  /// In en, this message translates to:
  /// **'VAT'**
  String get setupWizardVatRate;

  /// No description provided for @setupWizardCurrencyThb.
  ///
  /// In en, this message translates to:
  /// **'THB - Thai Baht'**
  String get setupWizardCurrencyThb;

  /// No description provided for @setupWizardCurrencyLak.
  ///
  /// In en, this message translates to:
  /// **'LAK - Lao Kip'**
  String get setupWizardCurrencyLak;

  /// No description provided for @setupWizardCurrencyUsd.
  ///
  /// In en, this message translates to:
  /// **'USD - US Dollar'**
  String get setupWizardCurrencyUsd;

  /// No description provided for @setupWizardPrinterHint.
  ///
  /// In en, this message translates to:
  /// **'Add at least one printer (optional)'**
  String get setupWizardPrinterHint;

  /// No description provided for @setupWizardAddPrinter.
  ///
  /// In en, this message translates to:
  /// **'Add Printer'**
  String get setupWizardAddPrinter;

  /// No description provided for @setupWizardPrinterName.
  ///
  /// In en, this message translates to:
  /// **'Printer Name'**
  String get setupWizardPrinterName;

  /// No description provided for @setupWizardPrinterType.
  ///
  /// In en, this message translates to:
  /// **'Type'**
  String get setupWizardPrinterType;

  /// No description provided for @setupWizardUseSampleData.
  ///
  /// In en, this message translates to:
  /// **'Use sample data (recommended)'**
  String get setupWizardUseSampleData;

  /// No description provided for @setupWizardUseSampleDataHint.
  ///
  /// In en, this message translates to:
  /// **'5 categories, 20 sample products for restaurants'**
  String get setupWizardUseSampleDataHint;

  /// No description provided for @setupWizardImportCsv.
  ///
  /// In en, this message translates to:
  /// **'Import CSV'**
  String get setupWizardImportCsv;

  /// No description provided for @setupWizardImportCsvHint.
  ///
  /// In en, this message translates to:
  /// **'Will be supported in the next step'**
  String get setupWizardImportCsvHint;

  /// No description provided for @setupWizardAddLater.
  ///
  /// In en, this message translates to:
  /// **'Add later'**
  String get setupWizardAddLater;

  /// No description provided for @setupWizardUsername.
  ///
  /// In en, this message translates to:
  /// **'Username'**
  String get setupWizardUsername;

  /// No description provided for @setupWizardDisplayName.
  ///
  /// In en, this message translates to:
  /// **'Display Name'**
  String get setupWizardDisplayName;

  /// No description provided for @setupWizardPassword.
  ///
  /// In en, this message translates to:
  /// **'Password (8+ characters)'**
  String get setupWizardPassword;

  /// No description provided for @setupWizardPinOptional.
  ///
  /// In en, this message translates to:
  /// **'PIN (optional)'**
  String get setupWizardPinOptional;

  /// No description provided for @setupWizardPinHint.
  ///
  /// In en, this message translates to:
  /// **'4-6 digits'**
  String get setupWizardPinHint;

  /// No description provided for @setupWizardRole.
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get setupWizardRole;

  /// No description provided for @setupWizardRoleCashier.
  ///
  /// In en, this message translates to:
  /// **'Cashier'**
  String get setupWizardRoleCashier;

  /// No description provided for @setupWizardRoleWaiter.
  ///
  /// In en, this message translates to:
  /// **'Waiter'**
  String get setupWizardRoleWaiter;

  /// No description provided for @setupWizardRoleKitchen.
  ///
  /// In en, this message translates to:
  /// **'Kitchen'**
  String get setupWizardRoleKitchen;

  /// No description provided for @setupWizardRoleManager.
  ///
  /// In en, this message translates to:
  /// **'Manager'**
  String get setupWizardRoleManager;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'lo', 'th'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'lo':
      return AppLocalizationsLo();
    case 'th':
      return AppLocalizationsTh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
