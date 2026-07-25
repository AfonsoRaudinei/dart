import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/session/session_models.dart';
import 'package:soloforte_app/ui/components/public_map/public_access_cta_policy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  group('shouldShowPublicAccessCta', () {
    test('true apenas para SessionPublic (visitante confirmado)', () {
      expect(shouldShowPublicAccessCta(const SessionPublic()), isTrue);
    });

    test('false no bootstrap (SessionUnknown) — evita card fantasma no reopen',
        () {
      expect(shouldShowPublicAccessCta(const SessionUnknown()), isFalse);
    });

    test('false quando autenticado — evita CTA duplicado com SmartButton', () {
      final user = User(
        id: 'u1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.utc(2024, 1, 1).toIso8601String(),
      );
      expect(shouldShowPublicAccessCta(SessionAuthenticated(user)), isFalse);
    });

    test('false em SessionPasswordRecovery', () {
      final user = User(
        id: 'u1',
        appMetadata: const {},
        userMetadata: const {},
        aud: 'authenticated',
        createdAt: DateTime.utc(2024, 1, 1).toIso8601String(),
      );
      expect(
        shouldShowPublicAccessCta(SessionPasswordRecovery(user)),
        isFalse,
      );
    });
  });

  group('shouldShowShellChrome', () {
    test('autenticado em rota privada → SmartButton/SideMenu visíveis', () {
      expect(
        shouldShowShellChrome(isAuthenticated: true, isPublicRoute: false),
        isTrue,
      );
    });

    test('autenticado ainda em /public-map → chrome oculto (anti-regressão)',
        () {
      expect(
        shouldShowShellChrome(isAuthenticated: true, isPublicRoute: true),
        isFalse,
      );
    });

    test('visitante nunca vê SmartButton do shell', () {
      expect(
        shouldShowShellChrome(isAuthenticated: false, isPublicRoute: true),
        isFalse,
      );
      expect(
        shouldShowShellChrome(isAuthenticated: false, isPublicRoute: false),
        isFalse,
      );
    });
  });
}
