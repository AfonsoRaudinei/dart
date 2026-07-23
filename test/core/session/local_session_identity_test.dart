import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';

Future<PreferencesService> _preferencesWith(Map<String, Object> values) async {
  SharedPreferences.setMockInitialValues(values);
  final prefs = await SharedPreferences.getInstance();
  return PreferencesService(prefs);
}

void main() {
  tearDown(LocalSessionIdentity.resetForTesting);

  test('usa ultimo usuario conhecido quando Supabase ainda nao hidratou', () {
    LocalSessionIdentity.remember('user-123');

    expect(LocalSessionIdentity.resolveUserId(), 'user-123');
  });

  test('limpa fallback apos logout explicito', () {
    LocalSessionIdentity.remember('user-123');
    LocalSessionIdentity.clear();

    expect(LocalSessionIdentity.resolveUserId(), isEmpty);
    expect(LocalSessionIdentity.canUseLastKnownFallback, isFalse);
  });

  test(
    'sessao publica bloqueia fallback sem apagar valor persistido',
    () async {
      final preferences = await _preferencesWith({
        'session_last_known_user_id_v1': 'user-456',
      });
      LocalSessionIdentity.configure(preferences);

      LocalSessionIdentity.markSessionPublic();

      expect(LocalSessionIdentity.resolveUserId(), isEmpty);
      expect(
        preferences.getString('session_last_known_user_id_v1'),
        'user-456',
      );
    },
  );

  test('restaura ultimo usuario conhecido persistido no cold start', () async {
    final preferences = await _preferencesWith({
      'session_last_known_user_id_v1': 'user-456',
    });
    LocalSessionIdentity.configure(preferences);

    expect(LocalSessionIdentity.resolveUserId(), 'user-456');
    expect(LocalSessionIdentity.canUseLastKnownFallback, isTrue);
  });

  test(
    'bootstrap: markSessionPublic NAO deve ser o estado default — '
    'lastKnown permanece legivel ate signedOut',
    () async {
      final preferences = await _preferencesWith({
        'session_last_known_user_id_v1': 'user-789',
      });
      LocalSessionIdentity.configure(preferences);

      // Simula janela SessionUnknown (initialSession ainda sem user).
      expect(LocalSessionIdentity.resolveUserId(), 'user-789');

      // Só clear (logout) remove de vez.
      LocalSessionIdentity.clear();
      expect(LocalSessionIdentity.resolveUserId(), isEmpty);
    },
  );
}
