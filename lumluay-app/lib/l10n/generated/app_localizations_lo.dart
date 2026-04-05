// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Lao (`lo`).
class AppLocalizationsLo extends AppLocalizations {
  AppLocalizationsLo([String locale = 'lo']) : super(locale);

  @override
  String get appTitle => 'LUMLUAY POS';

  @override
  String get languageSettingsTitle => 'ຕັ້ງຄ່າພາສາ';

  @override
  String get languageSettingsDescription => 'ເລືອກພາສາທີ່ທ່ານຕ້ອງການ';

  @override
  String languageChanged(Object language) {
    return 'ປ່ຽນພາສາເປັນ $language ແລ້ວ';
  }

  @override
  String get localeThai => 'ໄທ';

  @override
  String get localeEnglish => 'ອັງກິດ';

  @override
  String get localeLao => 'ລາວ';

  @override
  String get languageSupportHint =>
      'ຂໍ້ຄວາມບາງສ່ວນອາດຈະຍັງເປັນພາສາໄທຕາມແຫຼ່ງຂໍ້ມູນ';

  @override
  String get setupWizardTitle => 'ຕັ້ງຄ່າເບື້ອງຕົ້ນ';

  @override
  String get next => 'ຕໍ່ໄປ';

  @override
  String get back => 'ກັບຄືນ';

  @override
  String get finish => 'ສໍາເລັດ';

  @override
  String get add => 'ເພີ່ມ';

  @override
  String get save => 'ບັນທຶກ';

  @override
  String get cancel => 'ຍົກເລີກ';

  @override
  String get delete => 'ລົບ';

  @override
  String get confirm => 'ຢືນຢັນ';

  @override
  String get retry => 'ລອງໃໝ່';

  @override
  String get loading => 'ກໍາລັງໂຫຼດ...';

  @override
  String get errorOccurred => 'ເກີດຂໍ້ຜິດພາດ';

  @override
  String get settings => 'ການຕັ້ງຄ່າ';

  @override
  String get setupWizardCompleted => 'ການຕັ້ງຄ່າເບື້ອງຕົ້ນສໍາເລັດແລ້ວ.';

  @override
  String get setupWizardStoreNameRequired => 'ກະລຸນາໃສ່ຊື່ຮ້ານ';

  @override
  String get setupWizardSeedSampleDataFailed => 'ບໍ່ສາມາດເພີ່ມຂໍ້ມູນຕົວຢ່າງໄດ້';

  @override
  String get setupWizardStaffInfoIncomplete =>
      'ກະລຸນາໃສ່ຂໍ້ມູນພະນັກງານໃຫ້ຄົບ (ລະຫັດຜ່ານຢ່າງນ້ອຍ 8 ຕົວ)';

  @override
  String get setupWizardStepStoreInfo => 'ຂໍ້ມູນຮ້ານ';

  @override
  String get setupWizardStepCurrencyTax => 'ສະກຸນເງິນ ແລະ ພາສີ';

  @override
  String get setupWizardStepPrinters => 'ເຄື່ອງພິມ';

  @override
  String get setupWizardStepProductImport => 'ນໍາເຂົ້າສິນຄ້າ';

  @override
  String get setupWizardStepCreateStaff => 'ສ້າງພະນັກງານ';

  @override
  String setupWizardStepProgress(int currentStep, int totalSteps) {
    return 'ຕັ້ງຄ່າເບື້ອງຕົ້ນ • ຂັ້ນຕອນ $currentStep/$totalSteps';
  }

  @override
  String get setupWizardStoreName => 'ຊື່ຮ້ານ';

  @override
  String get setupWizardOwnerName => 'ຊື່ເຈົ້າຂອງ / ຜູ້ດູແລ';

  @override
  String get setupWizardPhone => 'ເບີໂທ';

  @override
  String get setupWizardAddress => 'ທີ່ຢູ່';

  @override
  String get setupWizardTaxId => 'ເລກປະຈໍາຕົວຜູ້ເສຍພາສີ';

  @override
  String get setupWizardDefaultCurrency => 'ສະກຸນເງິນເລີ່ມຕົ້ນ';

  @override
  String get setupWizardVatRate => 'VAT';

  @override
  String get setupWizardCurrencyThb => 'THB - ບາດໄທ';

  @override
  String get setupWizardCurrencyLak => 'LAK - ກີບລາວ';

  @override
  String get setupWizardCurrencyUsd => 'USD - ໂດລາສະຫະລັດ';

  @override
  String get setupWizardPrinterHint =>
      'ເພີ່ມເຄື່ອງພິມຢ່າງນ້ອຍ 1 ເຄື່ອງ (ຂ້າມໄດ້)';

  @override
  String get setupWizardAddPrinter => 'ເພີ່ມເຄື່ອງພິມ';

  @override
  String get setupWizardPrinterName => 'ຊື່ເຄື່ອງພິມ';

  @override
  String get setupWizardPrinterType => 'ປະເພດ';

  @override
  String get setupWizardUseSampleData => 'ໃຊ້ຂໍ້ມູນຕົວຢ່າງ (ແນະນໍາ)';

  @override
  String get setupWizardUseSampleDataHint =>
      '5 ໝວດ, 20 ສິນຄ້າຕົວຢ່າງສໍາລັບຮ້ານອາຫານ';

  @override
  String get setupWizardImportCsv => 'ນໍາເຂົ້າ CSV';

  @override
  String get setupWizardImportCsvHint => 'ຈະຮອງຮັບໃນຂັ້ນຕອນຖັດໄປ';

  @override
  String get setupWizardAddLater => 'ເພີ່ມພາຍຫຼັງ';

  @override
  String get setupWizardUsername => 'ຊື່ຜູ້ໃຊ້';

  @override
  String get setupWizardDisplayName => 'ຊື່ທີ່ສະແດງ';

  @override
  String get setupWizardPassword => 'ລະຫັດຜ່ານ (8+ ຕົວອັກສອນ)';

  @override
  String get setupWizardPinOptional => 'PIN (ທາງເລືອກ)';

  @override
  String get setupWizardPinHint => '4-6 ຫຼັກ';

  @override
  String get setupWizardRole => 'ບົດບາດ';

  @override
  String get setupWizardRoleCashier => 'ແຄດເຊຍ';

  @override
  String get setupWizardRoleWaiter => 'ພະນັກງານເສີບ';

  @override
  String get setupWizardRoleKitchen => 'ຄົວ';

  @override
  String get setupWizardRoleManager => 'ຜູ້ຈັດການ';
}
