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
}
