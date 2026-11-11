import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/presentation/relatorios_page.dart';

void main() {
  const rows = <_ClientRow>[_ClientRow('jonata'), _ClientRow('adriano')];

  String? clientIdOf(_ClientRow row) => row.clientId;

  test('produtor com allowedReady false devolve vazio', () {
    final scoped = scopeRowsToAllowedClients(
      isProdutor: true,
      allowedReady: false,
      allowedClientIds: const {'jonata'},
      rows: rows,
      clientIdOf: clientIdOf,
    );

    expect(scoped, isEmpty);
  });

  test('produtor com allowed jonata derruba clientId adriano', () {
    final scoped = scopeRowsToAllowedClients(
      isProdutor: true,
      allowedReady: true,
      allowedClientIds: const {'jonata'},
      rows: rows,
      clientIdOf: clientIdOf,
    );

    expect(scoped.map((row) => row.clientId), ['jonata']);
  });

  test('authorized sem valor não está pronto', () {
    final resolved = resolveProducerAllowedClients(
      authorizedHasValue: false,
      authorizedHasError: false,
      authorizedIds: const {'jonata'},
      ownHasValue: true,
      ownHasError: false,
      ownClientId: 'jonathan',
    );

    expect(resolved.ready, isFalse);
    expect(resolved.ids, isEmpty);
  });

  test('authorized jonata com own ainda sem valor mantém o vínculo', () {
    final resolved = resolveProducerAllowedClients(
      authorizedHasValue: true,
      authorizedHasError: false,
      authorizedIds: const {'jonata'},
      ownHasValue: false,
      ownHasError: false,
      ownClientId: null,
    );

    expect(resolved.ready, isTrue);
    expect(resolved.ids, {'jonata'});
  });

  test('authorized jonata e own jonathan entram os dois', () {
    final resolved = resolveProducerAllowedClients(
      authorizedHasValue: true,
      authorizedHasError: false,
      authorizedIds: const {'jonata'},
      ownHasValue: true,
      ownHasError: false,
      ownClientId: 'jonathan',
    );

    expect(resolved.ready, isTrue);
    expect(resolved.ids, {'jonata', 'jonathan'});
  });

  test('authorized com erro não está pronto', () {
    final resolved = resolveProducerAllowedClients(
      authorizedHasValue: true,
      authorizedHasError: true,
      authorizedIds: const {'jonata'},
      ownHasValue: true,
      ownHasError: false,
      ownClientId: 'jonathan',
    );

    expect(resolved.ready, isFalse);
    expect(resolved.ids, isEmpty);
  });

  test('consultor mantém as duas linhas', () {
    final scoped = scopeRowsToAllowedClients(
      isProdutor: false,
      allowedReady: false,
      allowedClientIds: const {'jonata'},
      rows: rows,
      clientIdOf: clientIdOf,
    );

    expect(scoped.map((row) => row.clientId), ['jonata', 'adriano']);
  });
}

class _ClientRow {
  const _ClientRow(this.clientId);

  final String? clientId;
}
