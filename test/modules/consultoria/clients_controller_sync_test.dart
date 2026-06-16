import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/data/clients_repository.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client_cultura.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart';

void main() {
  group('ClientsController sync', () {
    test('saveClient salva local, invalida lista e dispara sync', () async {
      final repo = _FakeClientsRepository();
      var syncCalls = 0;
      final container = ProviderContainer(
        overrides: [
          clientsRepositoryProvider.overrideWithValue(repo),
          clientSyncTriggerProvider.overrideWithValue(() async {
            syncCalls++;
          }),
        ],
      );
      addTearDown(container.dispose);

      expect(await container.read(clientsListProvider.future), isEmpty);
      expect(repo.getClientsCalls, 1);

      final client = _client('client-1');
      await container
          .read(clientsControllerProvider)
          .saveClient(client, culturas: const []);

      final clients = await container.read(clientsListProvider.future);
      expect(clients.map((c) => c.id), ['client-1']);
      expect(repo.savedClientIds, ['client-1']);
      expect(repo.getClientsCalls, 2);
      expect(syncCalls, 1);
    });

    test('sync falhando nao falha saveClient local', () async {
      final repo = _FakeClientsRepository();
      final container = ProviderContainer(
        overrides: [
          clientsRepositoryProvider.overrideWithValue(repo),
          clientSyncTriggerProvider.overrideWithValue(() async {
            throw StateError('offline');
          }),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(clientsControllerProvider)
          .saveClient(_client('client-offline'), culturas: const []);

      expect(repo.savedClientIds, ['client-offline']);
    });
  });
}

class _FakeClientsRepository extends ClientsRepository {
  final List<Client> _clients = [];
  final List<String> savedClientIds = [];
  int getClientsCalls = 0;

  @override
  Future<List<Client>> getClients() async {
    getClientsCalls++;
    return List<Client>.unmodifiable(_clients);
  }

  @override
  Future<void> saveClient(
    Client client, {
    List<ClientCultura> culturas = const [],
  }) async {
    savedClientIds.add(client.id);
    _clients.add(client);
  }
}

Client _client(String id) {
  return Client(
    id: id,
    name: 'Cliente $id',
    phone: '63999990000',
    city: 'Crixas',
    state: 'TO',
    createdAt: DateTime(2026, 6, 12),
    updatedAt: DateTime(2026, 6, 12),
  );
}
