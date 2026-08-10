import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_case_client_id_backfill_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';

void main() {
  test('backfill preenche client_id ausente sem sobrescrever existente', () async {
    final repository = _FakeMarketingCaseRepository();
    final service = MarketingCaseClientIdBackfillService(
      clientLookup: _FakeClientLookup(),
      farmLookup: _FakeFarmLookup(),
      repository: repository,
    );

    final cases = [
      _case(id: 'm1', produtorFazenda: 'Produtor A - Fazenda Norte'),
      _case(
        id: 'm2',
        produtorFazenda: 'Outro',
        clientId: 'cli-existing',
        syncStatus: 'synced',
      ),
    ];

    final result = await service.backfillIfNeeded(cases);

    expect(result[0].clientId, 'cli-a');
    expect(result[0].syncStatus, 'local_only');
    expect(result[1].clientId, 'cli-existing');
    expect(repository.savedIds, ['m1']);
  });

  test('backfill synced marca pending_sync ao preencher client_id', () async {
    final repository = _FakeMarketingCaseRepository();
    final service = MarketingCaseClientIdBackfillService(
      clientLookup: _FakeClientLookup(),
      farmLookup: _FakeFarmLookup(),
      repository: repository,
    );

    final cases = [
      _case(
        id: 'm-synced',
        produtorFazenda: 'Produtor B - Fazenda Sul',
        syncStatus: 'synced',
      ),
    ];

    final result = await service.backfillIfNeeded(cases);

    expect(result.single.clientId, 'cli-b');
    expect(result.single.syncStatus, 'pending_sync');
  });
}

MarketingCase _case({
  required String id,
  required String produtorFazenda,
  String? clientId,
  String syncStatus = 'local_only',
}) {
  return MarketingCase(
    id: id,
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.ouro,
    lat: -10,
    lng: -48,
    localizacaoTexto: 'Local',
    produtorFazenda: produtorFazenda,
    produtoUtilizado: 'Produto',
    clientId: clientId,
    criadoEm: DateTime.utc(2026, 6, 1),
    atualizadoEm: DateTime.utc(2026, 6, 1),
    syncStatus: syncStatus,
  );
}

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async {
    for (final client in await listAtivos()) {
      if (client.id == id) return client;
    }
    return null;
  }

  @override
  Future<List<ClientSummary>> listAtivos() async {
    return const [
      ClientSummary(id: 'cli-a', name: 'Produtor A', active: true),
      ClientSummary(id: 'cli-b', name: 'Produtor B', active: true),
    ];
  }
}

class _FakeFarmLookup implements IFarmLookup {
  @override
  Future<FarmSummary?> findById(String farmId) async => null;

  @override
  Future<List<FarmSummary>> getFarmsByClient(String clientId) async {
    switch (clientId) {
      case 'cli-a':
        return const [
          FarmSummary(id: 'farm-a1', clientId: 'cli-a', name: 'Fazenda Norte'),
        ];
      case 'cli-b':
        return const [
          FarmSummary(id: 'farm-b1', clientId: 'cli-b', name: 'Fazenda Sul'),
        ];
      default:
        return const [];
    }
  }

  @override
  Future<void> saveFarm({
    required String clientId,
    required String farmId,
    required String name,
    required String city,
    required String state,
    required double areaHa,
  }) async {}
}

class _FakeMarketingCaseRepository implements IMarketingCaseRepository {
  final savedIds = <String>[];

  @override
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<void> saveSingleToCache(MarketingCase marketingCase) async {
    savedIds.add(marketingCase.id);
  }

  @override
  Future<void> saveToCache(List<MarketingCase> cases) async {}

  @override
  Future<List<MarketingCase>> fetchMarketingCases() async => [];

  @override
  Future<List<MarketingCase>> getLocalCases() async => [];

  @override
  Future<MarketingCase> getById(String id) async => throw UnimplementedError();

  @override
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<void> updateCase(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> softDelete(String id) async => throw UnimplementedError();
}
