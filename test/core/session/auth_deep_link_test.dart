import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/session/auth_deep_link.dart';

void main() {
  group('AuthDeepLinkIntent', () {
    test('interpreta recovery com tokens no fragmento', () {
      final intent = AuthDeepLinkIntent.parse(
        Uri.parse(
          'soloforte://reset-password#type=recovery&access_token=a&refresh_token=b',
        ),
      );

      expect(intent.type, AuthDeepLinkType.recovery);
      expect(intent.hasCredentials, true);
      expect(intent.hasError, false);
    });

    test('interpreta signup PKCE com código na query', () {
      final intent = AuthDeepLinkIntent.parse(
        Uri.parse('soloforte://login?type=signup&code=auth-code'),
      );

      expect(intent.type, AuthDeepLinkType.signup);
      expect(intent.hasCredentials, true);
    });

    test('marca erro remoto sem expor sua descrição', () {
      final intent = AuthDeepLinkIntent.parse(
        Uri.parse(
          'soloforte://login?type=recovery&error=access_denied&error_description=internal',
        ),
      );

      expect(intent.hasError, true);
    });

    test('rejeita tipo desconhecido e link sem credencial', () {
      final unknown = AuthDeepLinkIntent.parse(
        Uri.parse('soloforte://login?type=admin&code=x'),
      );
      final incomplete = AuthDeepLinkIntent.parse(
        Uri.parse('soloforte://login?type=signup'),
      );

      expect(unknown.type, AuthDeepLinkType.unknown);
      expect(incomplete.type, AuthDeepLinkType.signup);
      expect(incomplete.hasCredentials, false);
    });
  });
}
