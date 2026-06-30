import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/auth/utils/auth_validators.dart';

void main() {
  group('AuthValidators Tests', () {
    // 1. Validar Nome
    test('validateName should reject names with less than 3 chars', () {
      expect(AuthValidators.validateName('Jo'), 'Mínimo de 3 caracteres');
    });

    test('validateName should reject only numbers', () {
      expect(AuthValidators.validateName('12345'), 'Nome deve conter letras');
    });

    test('validateName should accept valid names', () {
      expect(AuthValidators.validateName('João Silva'), null);
    });

    // 2. Validar Email
    test('validateEmail should reject malformed email', () {
      expect(AuthValidators.validateEmail('joao.com'), 'Email inválido');
    });

    test('validateEmail should accept valid email', () {
      expect(AuthValidators.validateEmail('joao@teste.com'), null);
    });

    // 3. Validar Senha Completa
    test('validatePassword should reject short passwords', () {
      expect(AuthValidators.validatePassword('Web1'), 'Mínimo de 8 caracteres');
    });

    test('validatePassword should reject password without uppercase', () {
      expect(
        AuthValidators.validatePassword('webmobile1'),
        'Deve conter uma letra maiúscula',
      );
    });

    test('validatePassword should reject password without lowercase', () {
      expect(
        AuthValidators.validatePassword('WEBMOBILE1'),
        'Deve conter uma letra minúscula',
      );
    });

    test('validatePassword should reject password without digits', () {
      expect(
        AuthValidators.validatePassword('WebMobile'),
        'Deve conter um número',
      );
    });

    test('validatePassword should accept strong password', () {
      expect(AuthValidators.validatePassword('WebMobile1'), null);
    });

    // 4. Teste de Força de Senha
    test('evaluatePasswordStrength should be weak for obvious sequences', () {
      expect(
        AuthValidators.evaluatePasswordStrength('password123'),
        PasswordStrength.weak,
      );
      expect(
        AuthValidators.evaluatePasswordStrength('12345678'),
        PasswordStrength.weak,
      );
    });

    test(
      'evaluatePasswordStrength should be medium for reasonable password',
      () {
        expect(
          AuthValidators.evaluatePasswordStrength('SoloForte1'),
          PasswordStrength.medium,
        );
      },
    );

    test('evaluatePasswordStrength should be strong for complex password', () {
      expect(
        AuthValidators.evaluatePasswordStrength('SoloForte1@2025!'),
        PasswordStrength.strong,
      );
    });
  });
}
