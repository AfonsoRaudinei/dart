import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';

MarketingCase _fonteConsultor() {
  final t = DateTime.utc(2026, 5, 1);
  return MarketingCase(
    id: 'consultor-case',
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.prata,
    lat: -15,
    lng: -47,
    localizacaoTexto: 'Local',
    produtorFazenda: 'Fazenda',
    produtoUtilizado: 'Produto',
    clientId: 'client-vinculo',
    ownerUserId: 'consultor-user',
    liberadoEm: DateTime.utc(2026, 6, 1),
    publicoAte: DateTime.utc(2026, 10, 1),
    status: MarketingCaseStatus.published,
    criadoEm: t,
    atualizadoEm: t,
  );
}

void main() {
  group('MarketingCasesNotifier.republicarComoProdutor', () {
    setUp(() {
      LocalSessionIdentity.resetForTesting();
      LocalSessionIdentity.remember('produtor-user');
    });

    tearDown(LocalSessionIdentity.resetForTesting);

    test('define sourceCaseId e owner do produtor', () async {
      final repo = _RecordingRepo();
      final sync = MarketingSyncService(repo);
      final notifier = MarketingCasesNotifier(
        repo,
        sync,
        null,
      );
      notifier.state = AsyncData([_fonteConsultor()]);

      final draft = await notifier.republicarComoProdutor(
        _fonteConsultor(),
        authorizedClientIds: {'client-vinculo'},
      );

      expect(draft.sourceCaseId, 'consultor-case');
      expect(draft.ownerUserId, 'produtor-user');
      expect(draft.status, MarketingCaseStatus.draft);
      expect(draft.liberadoEm, isNull);
      expect(draft.id, isNot('consultor-case'));
      expect(repo.lastDraft?.sourceCaseId, 'consultor-case');
    });
  });
}

class _RecordingRepo implements IMarketingCaseRepository {
  MarketingCase? lastDraft;

  @override
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async {
    lastDraft = marketingCase;
    return marketingCase;
  }

  @override
  Future<List<MarketingCase>> fetchMarketingCases() async => const [];

  @override
  Future<List<MarketingCase>> getLocalCases() async => const [];

  @override
  Future<void> saveToCache(List<MarketingCase> cases) async {}

  @override
  Future<void> saveSingleToCache(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<MarketingCase> getById(String id) async => throw UnimplementedError();

  @override
  Future<void> updateCase(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> softDelete(String id) async => throw UnimplementedError();
}