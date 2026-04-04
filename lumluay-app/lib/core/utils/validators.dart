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
      return '${fieldName ?? 'ช่องนี้'}ไม่สามารถว่างได้';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String? fieldName]) {
    final r = required(value, fieldName);
    if (r != null) return r;
    if (value!.length < min) return '${fieldName ?? 'ช่องนี้'}ต้องมีอย่างน้อย $min ตัวอักษร';
    return null;
  }

  static String? maxLength(String? value, int max, [String? fieldName]) {
    if (value != null && value.length > max) {
      return '${fieldName ?? 'ช่องนี้'}ต้องไม่เกิน $max ตัวอักษร';
    }
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Numeric validators
  // ──────────────────────────────────────────────────────────────────────────

  static String? numeric(String? value, [String? fieldName]) {
    final r = required(value, fieldName);
    if (r != null) return r;
    if (double.tryParse(value!) == null) return '${fieldName ?? 'ช่องนี้'}ต้องเป็นตัวเลข';
    return null;
  }

  static String? positiveNumber(String? value, [String? fieldName]) {
    final r = numeric(value, fieldName);
    if (r != null) return r;
    if (double.parse(value!) <= 0) return '${fieldName ?? 'ช่องนี้'}ต้องมากกว่า 0';
    return null;
  }

  static String? price(String? value) {
    final r = numeric(value, 'ราคา');
    if (r != null) return r;
    final d = double.parse(value!);
    if (d < 0) return 'ราคาต้องไม่ติดลบ';
    return null;
  }

  static String? percentage(String? value) {
    final r = numeric(value, 'เปอร์เซ็นต์');
    if (r != null) return r;
    final d = double.parse(value!);
    if (d < 0 || d > 100) return 'เปอร์เซ็นต์ต้องอยู่ระหว่าง 0-100';
    return null;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Contact validators
  // ──────────────────────────────────────────────────────────────────────────

  static String? phone(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    final digits = value.replaceAll(RegExp(r'[\s\-\+\(\)]'), '');
    if (!RegExp(r'^\d{9,15}$').hasMatch(digits)) {
      return 'รูปแบบเบอร์โทรไม่ถูกต้อง';
    }
    return null;
  }

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return null; // optional
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value.trim())) {
      return 'รูปแบบอีเมลไม่ถูกต้อง';
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
      return 'PIN ต้องเป็นตัวเลข $length หลัก';
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
      return 'เลขประจำตัวผู้เสียภาษีต้องเป็นตัวเลข 13 หลัก';
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
