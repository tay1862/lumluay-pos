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
  String get add => 'Add';

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

  @override
  String get setupWizardCompleted => 'Setup wizard completed.';

  @override
  String get setupWizardStoreNameRequired => 'Please enter a store name';

  @override
  String get setupWizardSeedSampleDataFailed => 'Could not seed sample data';

  @override
  String get setupWizardStaffInfoIncomplete =>
      'Complete the staff information (password must be at least 8 characters)';

  @override
  String get setupWizardStepStoreInfo => 'Store Information';

  @override
  String get setupWizardStepCurrencyTax => 'Currency and Tax';

  @override
  String get setupWizardStepPrinters => 'Printers';

  @override
  String get setupWizardStepProductImport => 'Import Products';

  @override
  String get setupWizardStepCreateStaff => 'Create Staff';

  @override
  String setupWizardStepProgress(int currentStep, int totalSteps) {
    return 'Setup Wizard • Step $currentStep/$totalSteps';
  }

  @override
  String get setupWizardStoreName => 'Store Name';

  @override
  String get setupWizardOwnerName => 'Owner / Administrator';

  @override
  String get setupWizardPhone => 'Phone Number';

  @override
  String get setupWizardAddress => 'Address';

  @override
  String get setupWizardTaxId => 'Tax ID';

  @override
  String get setupWizardDefaultCurrency => 'Default Currency';

  @override
  String get setupWizardVatRate => 'VAT';

  @override
  String get setupWizardCurrencyThb => 'THB - Thai Baht';

  @override
  String get setupWizardCurrencyLak => 'LAK - Lao Kip';

  @override
  String get setupWizardCurrencyUsd => 'USD - US Dollar';

  @override
  String get setupWizardPrinterHint => 'Add at least one printer (optional)';

  @override
  String get setupWizardAddPrinter => 'Add Printer';

  @override
  String get setupWizardPrinterName => 'Printer Name';

  @override
  String get setupWizardPrinterType => 'Type';

  @override
  String get setupWizardUseSampleData => 'Use sample data (recommended)';

  @override
  String get setupWizardUseSampleDataHint =>
      '5 categories, 20 sample products for restaurants';

  @override
  String get setupWizardImportCsv => 'Import CSV';

  @override
  String get setupWizardImportCsvHint => 'Will be supported in the next step';

  @override
  String get setupWizardAddLater => 'Add later';

  @override
  String get setupWizardUsername => 'Username';

  @override
  String get setupWizardDisplayName => 'Display Name';

  @override
  String get setupWizardPassword => 'Password (8+ characters)';

  @override
  String get setupWizardPinOptional => 'PIN (optional)';

  @override
  String get setupWizardPinHint => '4-6 digits';

  @override
  String get setupWizardRole => 'Role';

  @override
  String get setupWizardRoleCashier => 'Cashier';

  @override
  String get setupWizardRoleWaiter => 'Waiter';

  @override
  String get setupWizardRoleKitchen => 'Kitchen';

  @override
  String get setupWizardRoleManager => 'Manager';
}
