import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/auth/auth_exception.dart';

void main() {
  test('maps invalid login credentials', () {
    expect(
      mapAuthError(Exception('Invalid login credentials')),
      'E-mail ou senha incorretos.',
    );
  });

  test('returns AuthException message directly', () {
    expect(
      mapAuthError(const AuthException('Mensagem customizada')),
      'Mensagem customizada',
    );
  });
}
