import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';
import 'package:soloforte_app/modules/planos/domain/plano_cache_unavailable_exception.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';

void main() {
  group('marketingPublishBlockedByPlan', () {
    test('plano free bloqueia no limite bronze', () {
      final plano = UserPlan.free(userId: 'u1');
      final cases = List.generate(
        PlanoTipo.bronze.limiteCases,
        (i) => _publishedCase('existing-$i'),
      );

      expect(
        marketingPublishBlockedByPlan(
          plano: plano,
          cases: cases,
          publishingCaseId: 'new-case',
        ),
        isTrue,
      );
    });
  });

  group('publishCaseDetailed plano fail-open', () {
    test(
      'PlanoCacheUnavailableException usa bronze e segue para saveCase',
      () async {
        final repo = _RecordingRepo();
        final container = _container(
          repo: repo,
          planoOverride: (ref) async =>
              throw const PlanoCacheUnavailableException(expired: true),
          seed: const [],
        );
        addTearDown(container.dispose);

        final published = _publishedCase('mkt-new');
        final outcome = await container
            .read(marketingCasesProvider.notifier)
            .publishCaseDetailed(published);

        expect(outcome.isSuccess, isTrue);
        expect(outcome.error, isNull);
        expect(repo.saveCalls, 1);
        expect(
          container.read(marketingCasesProvider).valueOrNull,
          contains(published),
        );
      },
    );

    test(
      'falha de plano ainda bloqueia no limite bronze antes do optimistic',
      () async {
        final repo = _RecordingRepo();
        final atLimit = List.generate(
          PlanoTipo.bronze.limiteCases,
          (i) => _publishedCase('on-map-$i'),
        );
        final container = _container(
          repo: repo,
          planoOverride: (ref) async =>
              throw const PlanoCacheUnavailableException(expired: false),
          seed: atLimit,
        );
        addTearDown(container.dispose);

        final publishing = _publishedCase('mkt-sixth');
        final outcome = await container
            .read(marketingCasesProvider.notifier)
            .publishCaseDetailed(publishing);

        expect(outcome.isSuccess, isFalse);
        expect(outcome.error, isA<MarketingPlanLimitException>());
        expect(repo.saveCalls, 0);
        expect(
          container.read(marketingCasesProvider).valueOrNull,
          isNot(contains(publishing)),
        );
      },
    );
  });
}

ProviderContainer _container({
  required IMarketingCaseRepository repo,
  required Future<UserPlan> Function(Ref ref) planoOverride,
  required List<MarketingCase> seed,
}) {
  return ProviderContainer(
    overrides: [
      marketingCaseRepositoryProvider.overrideWithValue(repo),
      planoAtivoProvider.overrideWith(planoOverride),
      marketingCasesProvider.overrideWith((ref) {
        final sync = ref.watch(marketingSyncServiceProvider);
        return _RefMarketingCasesNotifier(ref, repo, sync, seed);
      }),
    ],
  );
}

MarketingCase _publishedCase(String id) {
  return MarketingCase.fromJson({
    'id': id,
    'tipo': 'resultado',
    'visibilidade': 'ouro',
    'lat': -10.2,
    'lng': -48.3,
    'localizacao_texto': 'Palmas, TO',
    'produtor_fazenda': 'Fazenda',
    'produto_utilizado': 'Produto',
    'status': MarketingCaseStatus.published.toValue(),
    'ativo': true,
    'criado_em': '2026-06-05T12:00:00.000Z',
    'atualizado_em': '2026-06-05T12:00:00.000Z',
    'sync_status': 'local_only',
  });
}

class _RefMarketingCasesNotifier extends MarketingCasesNotifier {
  _RefMarketingCasesNotifier(
    Ref ref,
    IMarketingCaseRepository repository,
    MarketingSyncService syncService,
    List<MarketingCase> seed,
  ) : super(repository, syncService, ref) {
    state = AsyncData(seed);
  }

  @override
  Future<void> load({bool forceSync = false}) async {}
}

class _RecordingRepo implements IMarketingCaseRepository {
  int saveCalls = 0;

  @override
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async {
    saveCalls++;
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
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<MarketingCase> getById(String id) async => throw UnimplementedError();

  @override
  Future<void> updateCase(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> softDelete(String id) async => throw UnimplementedError();
}
