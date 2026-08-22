import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';

const _kAuthUser = '11111111-1111-4111-8111-111111111111';

void main() {
  final now = DateTime.utc(2026, 8, 22);

  MarketingCase localCase({
    required String id,
    String syncStatus = 'pending_sync',
    MarketingCaseStatus status = MarketingCaseStatus.published,
  }) {
    return MarketingCase(
      id: id,
      tipo: CaseTipo.resultado,
      visibilidade: PlanoMarketing.ouro,
      lat: -15.0,
      lng: -47.0,
      localizacaoTexto: 'Fazenda Teste',
      produtorFazenda: 'Produtor',
      produtoUtilizado: 'Produto',
      status: status,
      criadoEm: now,
      atualizadoEm: now,
      syncStatus: syncStatus,
    );
  }

  group('MarketingSyncService.syncNow', () {
    test('sem JWT nao chama fetchMarketingCases nem saveCase', () async {
      final repo = _FakeMarketingCaseRepository(
        localCases: [localCase(id: 'pending-1')],
      );
      final service = MarketingSyncService(
        repo,
        currentUserId: () => '',
      );

      await service.syncNow();

      expect(repo.fetchCalls, 0);
      expect(repo.saveCaseCalls, isEmpty);
    });

    test('com JWT empurra so pending_sync; ignora local_only e draft', () async {
      final pending = localCase(id: 'pending-1');
      final localOnly = localCase(id: 'local-1', syncStatus: 'local_only');
      final draft = localCase(
        id: 'draft-1',
        syncStatus: 'local_only',
        status: MarketingCaseStatus.draft,
      );
      final draftPending = localCase(
        id: 'draft-pending',
        syncStatus: 'pending_sync',
        status: MarketingCaseStatus.draft,
      );
      final repo = _FakeMarketingCaseRepository(
        localCases: [pending, localOnly, draft, draftPending],
      );
      final service = MarketingSyncService(
        repo,
        currentUserId: () => _kAuthUser,
      );

      await service.syncNow();

      expect(repo.saveCaseCalls.map((c) => c.id), ['pending-1']);
    });

    test('com JWT o pull chama fetchMarketingCases via forceSync', () async {
      final repo = _FakeMarketingCaseRepository();
      final service = MarketingSyncService(
        repo,
        currentUserId: () => _kAuthUser,
      );

      await service.syncNow();

      expect(repo.fetchCalls, 1);
      expect(repo.saveToCacheCalls, 1);
    });
  });
}

class _FakeMarketingCaseRepository implements IMarketingCaseRepository {
  _FakeMarketingCaseRepository({
    List<MarketingCase> localCases = const [],
    List<MarketingCase> remoteCases = const [],
  }) : localCases = List.of(localCases),
       remoteCases = List.of(remoteCases);

  final List<MarketingCase> localCases;
  final List<MarketingCase> remoteCases;
  final List<MarketingCase> saveCaseCalls = [];
  int fetchCalls = 0;
  int saveToCacheCalls = 0;

  @override
  Future<List<MarketingCase>> fetchMarketingCases() async {
    fetchCalls++;
    return remoteCases;
  }

  @override
  Future<List<MarketingCase>> getLocalCases() async => localCases;

  @override
  Future<void> saveToCache(List<MarketingCase> cases) async {
    saveToCacheCalls++;
  }

  @override
  Future<void> saveSingleToCache(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async {
    saveCaseCalls.add(marketingCase);
    return marketingCase;
  }

  @override
  Future<void> updateCase(MarketingCase marketingCase) async {
    throw UnimplementedError();
  }

  @override
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async {
    throw UnimplementedError();
  }

  @override
  Future<MarketingCase> getById(String id) async {
    throw UnimplementedError();
  }

  @override
  Future<MarketingCase> softDelete(String id) async {
    throw UnimplementedError();
  }
}
