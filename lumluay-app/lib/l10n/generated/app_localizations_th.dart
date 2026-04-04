// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get appTitle => 'LUMLUAY POS';

  @override
  String get languageSettingsTitle => 'ตั้งค่าภาษา';

  @override
  String get languageSettingsDescription => 'เลือกภาษาที่ต้องการใช้งาน';

  @override
  String languageChanged(Object language) {
    return 'เปลี่ยนภาษาเป็น $language แล้ว';
  }

  @override
  String get localeThai => 'ภาษาไทย';

  @override
  String get localeEnglish => 'English';

  @override
  String get localeLao => 'ພາສາລາວ';

  @override
  String get languageSupportHint => 'บางข้อความอาจยังแสดงเป็นภาษาไทย ขึ้นอยู่กับการรองรับของเนื้อหา';

  @override
  String get setupWizardTitle => 'Setup Wizard';

  @override
  String get next => 'ถัดไป';

  @override
  String get back => 'ย้อนกลับ';

  @override
  String get finish => 'เสร็จสิ้น';

  @override
  String get save => 'บันทึก';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get delete => 'ลบ';

  @override
  String get confirm => 'ยืนยัน';

  @override
  String get retry => 'ลองใหม่';

  @override
  String get loading => 'กำลังโหลด...';

  @override
  String get errorOccurred => 'เกิดข้อผิดพลาด';

  @override
  String get settings => 'ตั้งค่า';
}
