import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/session/pending_signup_avatar_store.dart';

void main() {
  late Directory tmp;
  late PreferencesService prefs;
  late PendingSignupAvatarStore store;
  late File picked;

  setUp(() async {
    tmp = await Directory.systemTemp.createTemp('avatar_store_test_');
    SharedPreferences.setMockInitialValues({});
    prefs = PreferencesService(await SharedPreferences.getInstance());
    store = PendingSignupAvatarStore(
      prefs,
      directoryProvider: () async => Directory('${tmp.path}/support'),
    );
    picked = File('${tmp.path}/picker_cache.jpg')..writeAsBytesSync([1, 2, 3]);
  });

  tearDown(() async {
    if (await tmp.exists()) await tmp.delete(recursive: true);
  });

  group('PendingSignupAvatarStore', () {
    test('copia a foto e recupera pelo e-mail normalizado', () async {
      await store.save(email: ' Maria@Teste.COM ', source: picked);

      final file = await store.readValid('maria@teste.com');

      expect(file, isNotNull);
      expect(file!.path, isNot(picked.path));
      expect(file.readAsBytesSync(), [1, 2, 3]);
    });

    test('sobrevive à remoção do arquivo original do picker', () async {
      await store.save(email: 'a@teste.com', source: picked);
      picked.deleteSync();

      expect(await store.readValid('a@teste.com'), isNotNull);
    });

    test('ignora arquivo de origem inexistente', () async {
      await store.save(
        email: 'a@teste.com',
        source: File('${tmp.path}/nao_existe.jpg'),
      );

      expect(await store.readValid('a@teste.com'), isNull);
    });

    test('não vaza foto de um e-mail para outro', () async {
      await store.save(email: 'a@teste.com', source: picked);

      expect(await store.readValid('b@teste.com'), isNull);
    });

    test('clear remove a entrada e o arquivo copiado', () async {
      await store.save(email: 'a@teste.com', source: picked);
      final stored = (await store.readValid('a@teste.com'))!;

      await store.clear('a@teste.com');

      expect(await store.readValid('a@teste.com'), isNull);
      expect(stored.existsSync(), isFalse);
    });

    test('novo cadastro com o mesmo e-mail substitui a foto', () async {
      await store.save(email: 'a@teste.com', source: picked);
      final second = File('${tmp.path}/second.png')..writeAsBytesSync([9, 9]);

      await store.save(email: 'a@teste.com', source: second);

      final file = await store.readValid('a@teste.com');
      expect(file!.readAsBytesSync(), [9, 9]);
    });

    test('expira após 7 dias e limpa a entrada', () async {
      await store.save(email: 'a@teste.com', source: picked);
      final key = prefs.getKeys().firstWhere(
        (k) => k.startsWith('auth.pending_signup_avatar.'),
      );
      final entry = jsonDecode(prefs.getString(key)!) as Map<String, dynamic>;
      entry['created_at'] = DateTime.now()
          .toUtc()
          .subtract(const Duration(days: 8))
          .toIso8601String();
      await prefs.setString(key, jsonEncode(entry));

      expect(await store.readValid('a@teste.com'), isNull);
      expect(prefs.getString(key), isNull);
    });

    test('descarta entrada cujo arquivo sumiu do disco', () async {
      await store.save(email: 'a@teste.com', source: picked);
      (await store.readValid('a@teste.com'))!.deleteSync();

      expect(await store.readValid('a@teste.com'), isNull);
    });

    test('descarta entrada corrompida', () async {
      await prefs.setString('auth.pending_signup_avatar.a@teste.com', 'lixo');

      expect(await store.readValid('a@teste.com'), isNull);
      expect(prefs.getString('auth.pending_signup_avatar.a@teste.com'), isNull);
    });
  });
}
