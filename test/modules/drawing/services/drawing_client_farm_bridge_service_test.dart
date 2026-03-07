import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/domain/repositories/i_clients_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/services/drawing_client_farm_bridge_service.dart';

// =============================================================================
// Fake colaboradores
// =============================================================================

class _FakeClientsRepository implements IClientsRepository {
  List<Client> clients;
  List<Farm> farms;
  Farm? lastSavedFarm;
  String? lastSavedClientId;

  _FakeClientsRepository({
    this.clients = const [],
    this.farms = const [],
  });

  @override
  Future<List<Client>> getClients() async => clients;

  @override
  Future<List<Farm>> getFarms(String clientId) async => farms;

  @override
  Future<void> saveFarm(Farm farm, String clientId) async {
    lastSavedFarm = farm;
    lastSavedClientId = clientId;
  }
}

// =============================================================================
// Fixtures
// =============================================================================

Client _makeClient(String id) => Client(
      id: id,
      name: 'Cliente $id',
      phone: '11999990000',
      city: 'Sao Paulo',
      state: 'SP',
      createdAt: DateTime(2024, 1, 1),
    );

Farm _makeFarm(String id) => Farm(
      id: id,
      name: 'Fazenda $id',
      city: 'Ribeirao',
      state: 'SP',
      totalAreaHa: 100.0,
      fields: [],
    );

// =============================================================================
// Testes
// =============================================================================

void main() {
  group('DrawingClientFarmBridgeService', () {
    test('loadClients retorna lista do repositório', () async {
      final repo = _FakeClientsRepository(
        clients: [_makeClient('c1'), _makeClient('c2')],
      );
      final service = DrawingClientFarmBridgeService(repo);

      final result = await service.loadClients();

      expect(result.length, equals(2));
      expect(result.first.id, equals('c1'));
    });

    test('loadClients retorna lista vazia quando repositório é null', () async {
      final service = const DrawingClientFarmBridgeService(null);
      final result = await service.loadClients();
      expect(result, isEmpty);
    });

    test('loadFarms retorna fazendas do repositório', () async {
      final repo = _FakeClientsRepository(
        farms: [_makeFarm('f1'), _makeFarm('f2'), _makeFarm('f3')],
      );
      final service = DrawingClientFarmBridgeService(repo);

      final result = await service.loadFarms('cli-1');
      expect(result.length, equals(3));
    });

    test('loadFarms retorna lista vazia quando repositório é null', () async {
      final service = const DrawingClientFarmBridgeService(null);
      final result = await service.loadFarms('qualquer');
      expect(result, isEmpty);
    });

    test('createFarm invoca saveFarm com Farm correto', () async {
      final repo = _FakeClientsRepository();
      final service = DrawingClientFarmBridgeService(repo);

      await service.createFarm('Fazenda Nova', 'cli-42', 'Uberlandia', 'MG');

      expect(repo.lastSavedFarm, isNotNull);
      expect(repo.lastSavedFarm!.name, equals('Fazenda Nova'));
      expect(repo.lastSavedFarm!.city, equals('Uberlandia'));
      expect(repo.lastSavedFarm!.state, equals('MG'));
      expect(repo.lastSavedClientId, equals('cli-42'));
    });

    test('createFarm nao lança exceção quando repositório é null', () async {
      final service = const DrawingClientFarmBridgeService(null);
      // Não deve lançar
      await expectLater(
        service.createFarm('X', 'y', 'z', 'w'),
        completes,
      );
    });

    test('createFarm gera id nao vazio para nova fazenda', () async {
      final repo = _FakeClientsRepository();
      final service = DrawingClientFarmBridgeService(repo);

      await service.createFarm('FazNova', 'cli-1', 'Cidade', 'UF');

      expect(repo.lastSavedFarm!.id, isNotEmpty);
    });
  });
}
