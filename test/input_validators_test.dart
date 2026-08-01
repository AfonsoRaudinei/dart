import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/utils/input_validators.dart';

void main() {
  group('validateEmail', () {
    test('rejects empty', () {
      expect(InputValidators.validateEmail(''), isNotNull);
    });

    test('accepts valid email', () {
      expect(InputValidators.validateEmail('user@soloforte.app'), isNull);
    });

    test('rejects invalid email', () {
      expect(InputValidators.validateEmail('not-an-email'), isNotNull);
    });
  });

  group('validatePassword', () {
    test('requires minimum 8 characters', () {
      expect(InputValidators.validatePassword('1234567'), isNotNull);
      expect(InputValidators.validatePassword('12345678'), isNull);
    });
  });
}
