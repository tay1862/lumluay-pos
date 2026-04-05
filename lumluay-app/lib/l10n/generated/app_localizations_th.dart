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
  String get languageSupportHint =>
      'บางข้อความอาจยังแสดงเป็นภาษาไทย ขึ้นอยู่กับการรองรับของเนื้อหา';

  @override
  String get setupWizardTitle => 'Setup Wizard';

  @override
  String get next => 'ถัดไป';

  @override
  String get back => 'ย้อนกลับ';

  @override
  String get finish => 'เสร็จสิ้น';

  @override
  String get add => 'เพิ่ม';

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

  @override
  String get setupWizardCompleted => 'ตั้งค่าเริ่มต้นเสร็จสมบูรณ์แล้ว';

  @override
  String get setupWizardStoreNameRequired => 'กรุณากรอกชื่อร้าน';

  @override
  String get setupWizardSeedSampleDataFailed =>
      'ไม่สามารถเพิ่มข้อมูลตัวอย่างได้';

  @override
  String get setupWizardStaffInfoIncomplete =>
      'กรอกข้อมูลพนักงานให้ครบ (รหัสผ่านอย่างน้อย 8 ตัว)';

  @override
  String get setupWizardStepStoreInfo => 'ข้อมูลร้าน';

  @override
  String get setupWizardStepCurrencyTax => 'สกุลเงินและภาษี';

  @override
  String get setupWizardStepPrinters => 'เครื่องพิมพ์';

  @override
  String get setupWizardStepProductImport => 'นำเข้าสินค้า';

  @override
  String get setupWizardStepCreateStaff => 'สร้างพนักงาน';

  @override
  String setupWizardStepProgress(int currentStep, int totalSteps) {
    return 'Setup Wizard • ขั้นตอน $currentStep/$totalSteps';
  }

  @override
  String get setupWizardStoreName => 'ชื่อร้าน';

  @override
  String get setupWizardOwnerName => 'ชื่อเจ้าของ / ผู้ดูแล';

  @override
  String get setupWizardPhone => 'เบอร์โทร';

  @override
  String get setupWizardAddress => 'ที่อยู่';

  @override
  String get setupWizardTaxId => 'เลขผู้เสียภาษี';

  @override
  String get setupWizardDefaultCurrency => 'สกุลเงินเริ่มต้น';

  @override
  String get setupWizardVatRate => 'VAT';

  @override
  String get setupWizardCurrencyThb => 'THB - บาทไทย';

  @override
  String get setupWizardCurrencyLak => 'LAK - กีบลาว';

  @override
  String get setupWizardCurrencyUsd => 'USD - ดอลลาร์สหรัฐ';

  @override
  String get setupWizardPrinterHint =>
      'เพิ่มเครื่องพิมพ์อย่างน้อย 1 เครื่อง (ข้ามได้)';

  @override
  String get setupWizardAddPrinter => 'เพิ่มเครื่องพิมพ์';

  @override
  String get setupWizardPrinterName => 'ชื่อเครื่องพิมพ์';

  @override
  String get setupWizardPrinterType => 'ประเภท';

  @override
  String get setupWizardUseSampleData => 'ใช้ข้อมูลตัวอย่าง (แนะนำ)';

  @override
  String get setupWizardUseSampleDataHint =>
      '5 หมวดหมู่, 20 สินค้า ตัวอย่างสำหรับร้านอาหาร';

  @override
  String get setupWizardImportCsv => 'นำเข้า CSV';

  @override
  String get setupWizardImportCsvHint => 'จะรองรับขั้นถัดไป';

  @override
  String get setupWizardAddLater => 'เพิ่มทีหลัง';

  @override
  String get setupWizardUsername => 'Username';

  @override
  String get setupWizardDisplayName => 'ชื่อที่แสดง';

  @override
  String get setupWizardPassword => 'รหัสผ่าน (8+ ตัวอักษร)';

  @override
  String get setupWizardPinOptional => 'PIN (ตัวเลือก)';

  @override
  String get setupWizardPinHint => '4-6 หลัก';

  @override
  String get setupWizardRole => 'บทบาท';

  @override
  String get setupWizardRoleCashier => 'Cashier';

  @override
  String get setupWizardRoleWaiter => 'Waiter';

  @override
  String get setupWizardRoleKitchen => 'Kitchen';

  @override
  String get setupWizardRoleManager => 'Manager';
}
