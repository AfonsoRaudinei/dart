import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('persiste somente buffer limitado de erros críticos', () async {
    for (var index = 0; index < 35; index++) {
      await AppLogger.persistError('erro $index');
    }

    final errors = await AppLogger.readPersistedErrors();

    expect(errors, hasLength(30));
    expect(errors.first['message'], 'erro 5');
    expect(errors.last['message'], 'erro 34');
  });

  test('remove URL, email e segredos antes de persistir', () async {
    await AppLogger.persistError(
      'POST https://api.example.com/items?access_token=abc '
      'email=user@example.com password=segredo',
    );

    final errors = await AppLogger.readPersistedErrors();
    final message = errors.single['message'] as String;

    expect(message, isNot(contains('https://')));
    expect(message, isNot(contains('user@example.com')));
    expect(message, isNot(contains('segredo')));
    expect(message, contains('[REDACTED_URL]'));
    expect(message, contains('[REDACTED_EMAIL]'));
    expect(message, contains('[REDACTED_SECRET]'));
  });

  test(
    'remove documentos, telefones, coordenadas e ids antes de persistir',
    () async {
      await AppLogger.persistError(
        'cliente=João Silva cpf=123.456.789-09 telefone=(63)99999-0000 '
        'lat=-10.182300 lng=-48.333100 '
        'session_id=550e8400-e29b-41d4-a716-446655440000',
        error: StateError('cpf=123.456.789-09'),
        stackTrace: StackTrace.fromString(
          'linha com token=abc e telefone=(63)99999-0000',
        ),
      );

      final errors = await AppLogger.readPersistedErrors();
      final entry = errors.single;
      final message = entry['message'] as String;

      expect(message, isNot(contains('123.456.789-09')));
      expect(message, isNot(contains('(63)99999-0000')));
      expect(message, isNot(contains('-10.182300')));
      expect(message, isNot(contains('550e8400-e29b-41d4-a716-446655440000')));
      expect(message, contains('[REDACTED_DOCUMENT]'));
      expect(message, contains('[REDACTED_PHONE]'));
      expect(message, contains('[REDACTED_COORD]'));
      expect(message, contains('[REDACTED_ID]'));
      expect(entry['errorType'], 'StateError');
      expect(entry.containsKey('error'), isFalse);
      expect(entry.containsKey('stackTrace'), isFalse);
      expect(entry.containsKey('stackTraceHash'), isTrue);
    },
  );

  test('limpa erros persistidos', () async {
    await AppLogger.persistError('erro');

    await AppLogger.clearPersistedErrors();

    expect(await AppLogger.readPersistedErrors(), isEmpty);
  });
}
