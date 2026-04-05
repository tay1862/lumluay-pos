/// Validation utilities for form fields.
///
/// Each function returns an error string or null (valid).
class Validators {
  Validators._();

  // ──────────────────────────────────────────────────────────────────────────
  // Basic validators
  // ──────────────────────────────────────────────────────────────────────────

  static String? required(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'ຊ່ອງນີ້'}ບໍ່ສາມາດວ່າງໄດ້';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? fieldName]) {
    final r = required(value, fieldName);
    if (r != null) return r;
    if (value!.length < min) return '${fieldName ?? 'ຊ່ອງນີ້'}ຕ້ອງມີຢ່າງນ້ອຍ $min ຕົວອັກສອນ';
    return null;
  }

  static String? maxLength(String? value, int max, [String? fieldName]) {
    if (value != null && value.length > max) {
      return '${fieldName ?? 'ຊ່ອງນີ້'}ຕ້ອງບໍ່ເກີນ $max ຕົວອັກສອນ';
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Numeric validators
  // ──────────────────────────────────────────────────────────────────────────

  static String? numeric(String? value, [String? fieldName]) {
    final r = required(value, fieldName);
    if (r != null) return r;
    if (double.tryParse(value!) == null) return '${fieldName ?? 'ຊ່ອງນີ້'}ຕ້ອງເປັນຕົວເລກ';
    return null;
  }

  static String? positiveNumber(String? value, [String? fieldName]) {
    final r = numeric(value, fieldName);
    if (r != null) return r;
    if (double.parse(value!) <= 0) return '${fieldName ?? 'ຊ່ອງນີ້'}ຕ້ອງຫຼາຍກວ່າ 0';
    return null;
  }

  static String? price(String? value) {
    final r = numeric(value, 'ລາຄາ');
    if (r != null) return r;
    final d = double.parse(value!);
    if (d < 0) return 'ລາຄາຕ້ອງບໍ່ຕິດລົບ';
    return null;
  }

  static String? percentage(String? value) {
    final r = numeric(value, 'ເປີເຊັນ');
    if (r != null) return r;
    final d = double.parse(value!);
    if (d < 0 || d > 100) return 'ເປີເຊັນຕ້ອງຢູ່ລະຫວ່າງ 0-100';
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Contact validators
  // ──────────────────────────────────────────────────────────────────────────

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final digits = value.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (!RegExp(r'^\d{9,15}$').hasMatch(digits)) {
      return 'ລູບແບບເບີໂທລບໍ່ຖືກຕ້ອງ';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'ລູບແບບອີເມລບໍ່ຖືກຕ້ອງ';
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PIN validators
  // ──────────────────────────────────────────────────────────────────────────

  static String? pin(String? value, {int length = 4}) {
    final r = required(value, 'PIN');
    if (r != null) return r;
    if (!RegExp(r'^\d{' + length.toString() + r'}$').hasMatch(value!)) {
      return 'PIN ຕ້ອງເປັນຕົວເລກ $length ຫຼັກ';
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Tax ID / Registration validators
  // ──────────────────────────────────────────────────────────────────────────

  static String? taxId(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final digits = value.replaceAll(RegExp(r'[\s\-]'), '');
    if (!RegExp(r'^\d{13}$').hasMatch(digits)) {
      return 'ເລກປະຈຳຕົວຜູ້ເສຍພາສີຕ້ອງເປັນຕົວເລກ 13 ຫຼັກ';
    }
    return null;
  }

  /// Compose multiple validators (returns first error).
  static String? Function(String?) compose(
    List<String? Function(String?)> validators,
  ) {
    return (value) {
      for (final v in validators) {
        final error = v(value);
        if (error != null) return error;
      }
      return null;
    };
  }
}
