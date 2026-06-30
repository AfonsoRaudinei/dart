import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/session/pending_signup_role_store.dart';

void main() {
  group('PendingSignupRoleStore', () {
    test('recupera role consultor pelo email normalizado', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = PendingSignupRoleStore(PreferencesService(prefs));

      await store.save(email: ' Consultor@Teste.COM ', role: 'consultor');

      expect(await store.readValidRole('consultor@teste.com'), 'consultor');
    });

    test('ignora role invalido', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = PendingSignupRoleStore(PreferencesService(prefs));

      await store.save(email: 'user@teste.com', role: 'admin');

      expect(await store.readValidRole('user@teste.com'), isNull);
    });

    test('clear remove role pendente', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final store = PendingSignupRoleStore(PreferencesService(prefs));

      await store.save(email: 'user@teste.com', role: 'consultor');
      await store.clear('user@teste.com');

      expect(await store.readValidRole('user@teste.com'), isNull);
    });
  });
}
