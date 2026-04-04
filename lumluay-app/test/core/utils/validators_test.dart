import 'package:flutter_test/flutter_test.dart';
import 'package:lumluay_pos/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('required returns error when empty', () {
      expect(Validators.required(''), isNotNull);
      expect(Validators.required('ok'), isNull);
    });

    test('price validates non-negative numbers', () {
      expect(Validators.price('-1'), isNotNull);
      expect(Validators.price('0'), isNull);
      expect(Validators.price('10.50'), isNull);
    });

    test('phone validates optional and digit length', () {
      expect(Validators.phone(null), isNull);
      expect(Validators.phone('0812345678'), isNull);
      expect(Validators.phone('12'), isNotNull);
    });

    test('pin validates fixed length digits', () {
      expect(Validators.pin('1234'), isNull);
      expect(Validators.pin('12ab'), isNotNull);
      expect(Validators.pin('12345', length: 4), isNotNull);
    });
  });
}
