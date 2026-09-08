import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';
import 'package:soloforte_app/modules/planos/domain/plano_cache_unavailable_exception.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';
import 'package:soloforte_app/ui/screens/map/handlers/novo_case_modal_launcher.dart';

void main() {
  const cacheMessage =
      'Conecte-se à internet ao menos uma vez a cada 24h para continuar publicando cases offline';

  group('novo_case_offline_plan_cache_regression', () {
    testWidgets(
      'PlanoCacheUnavailableException exibe mensagem de 24h, não "Sem conexão"',
      (tester) async {
        final repo = _StatusOkRepo();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              marketingCaseRepositoryProvider.overrideWithValue(repo),
              marketingCasesProvider.overrideWith((ref) {
                final sync = ref.watch(marketingSyncServiceProvider);
                return _StubMarketingCasesNotifier(repo, sync, const []);
              }),
              planoAtivoProvider.overrideWith(
                (ref) async => throw const PlanoCacheUnavailableException(
                  expired: false,
                ),
              ),
              connectivityStateProvider.overrideWith(
                (ref) => Stream.value(false),
              ),
            ],
            child: const MaterialApp(home: _PublishHarness()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('submit_case')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.textContaining(cacheMessage), findsOneWidget);
        expect(
          find.textContaining(
            'Case salvo como rascunho em Relatórios → Marketing',
          ),
          findsOneWidget,
        );
        expect(
          find.text('Sem conexão. Não foi possível verificar seu plano.'),
          findsNothing,
        );
        expect(repo.saveCalls, 0);
        expect(repo.draftSaveCalls, 1);
      },
    );

    testWidgets(
      'falha ao salvar rascunho após erro de plano exibe mensagem explícita',
      (tester) async {
        final repo = _StatusOkRepo();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              marketingCaseRepositoryProvider.overrideWithValue(repo),
              marketingCasesProvider.overrideWith((ref) {
                return _ThrowingDraftNotifier(repo, const []);
              }),
              planoAtivoProvider.overrideWith(
                (ref) async => throw const PlanoCacheUnavailableException(
                  expired: false,
                ),
              ),
              connectivityStateProvider.overrideWith(
                (ref) => Stream.value(false),
              ),
            ],
            child: const MaterialApp(home: _PublishHarness()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('submit_case')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 250));

        expect(find.textContaining(cacheMessage), findsOneWidget);
        expect(
          find.textContaining('Não foi possível salvar o rascunho. Tente novamente.'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Case salvo como rascunho em Relatórios → Marketing',
          ),
          findsNothing,
        );
      },
    );

    test('plano expirado rebaixa pending_sync published para draft', () async {
      final pending = _publishedCase('pend-1', syncStatus: 'pending_sync');
      final synced = _publishedCase('sync-1', syncStatus: 'synced');
      final repo = _DraftAwareRepo([pending, synced]);
      final notifier = _StubMarketingCasesNotifier(
        repo,
        MarketingSyncService(repo),
        [pending, synced],
      );

      await notifier.reconcileOfflinePublishes(
        _plan(ativo: true, expiraEm: DateTime.utc(2020, 1, 1)),
      );

      expect(
        notifier.state.valueOrNull!.firstWhere((c) => c.id == 'pend-1').status
            .toValue(),
        'draft',
      );
      expect(
        notifier.state.valueOrNull!.firstWhere((c) => c.id == 'sync-1').status
            .toValue(),
        'published',
      );
    });

    test(
      'acima do limite rebaixa pending_sync mais novos e preserva synced',
      () async {
        final cases = [
          _publishedCase(
            'synced-1',
            syncStatus: 'synced',
            atualizadoEm: '2026-09-01T10:00:00.000Z',
          ),
          _publishedCase(
            'synced-2',
            syncStatus: 'synced',
            atualizadoEm: '2026-09-01T11:00:00.000Z',
          ),
          _publishedCase(
            'pend-old',
            syncStatus: 'pending_sync',
            atualizadoEm: '2026-09-02T10:00:00.000Z',
          ),
          _publishedCase(
            'pend-mid',
            syncStatus: 'pending_sync',
            atualizadoEm: '2026-09-03T10:00:00.000Z',
          ),
          _publishedCase(
            'pend-new',
            syncStatus: 'pending_sync',
            atualizadoEm: '2026-09-04T10:00:00.000Z',
          ),
        ];
        final repo = _DraftAwareRepo(cases);
        final notifier = _StubMarketingCasesNotifier(
          repo,
          MarketingSyncService(repo),
          cases,
        );

        await notifier.reconcileOfflinePublishes(
          _plan(plano: PlanoTipo.bronze),
        );

        final state = notifier.state.valueOrNull!;
        expect(
          state.firstWhere((c) => c.id == 'pend-new').status.toValue(),
          'draft',
        );
        expect(
          state.firstWhere((c) => c.id == 'pend-mid').status.toValue(),
          'draft',
        );
        expect(
          state.firstWhere((c) => c.id == 'pend-old').status.toValue(),
          'published',
        );
        expect(
          state.firstWhere((c) => c.id == 'synced-1').status.toValue(),
          'published',
        );
        expect(
          state.firstWhere((c) => c.id == 'synced-2').status.toValue(),
          'published',
        );
      },
    );
  });
}

UserPlan _plan({
  PlanoTipo plano = PlanoTipo.prata,
  bool ativo = true,
  DateTime? expiraEm,
}) {
  return UserPlan(
    id: 'plan-1',
    userId: 'user-1',
    plano: plano,
    origem: PlanoOrigem.pagamento,
    ativo: ativo,
    iniciouEm: DateTime.utc(2026, 1, 1),
    expiraEm: expiraEm ?? DateTime.utc(2027, 1, 1),
    criadoEm: DateTime.utc(2026, 1, 1),
  );
}

class _PublishHarness extends ConsumerWidget {
  const _PublishHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ElevatedButton(
        key: const Key('submit_case'),
        onPressed: () {
          NovoCaseModalLauncher.submitCaseFromMap(
            context: context,
            ref: ref,
            newCase: _draftCase(),
          );
        },
        child: const Text('Publicar'),
      ),
    );
  }
}

MarketingCase _draftCase() {
  return MarketingCase.fromJson({
    'id': 'mkt-new',
    'tipo': 'resultado',
    'visibilidade': 'ouro',
    'lat': -10.2,
    'lng': -48.3,
    'localizacao_texto': 'Palmas, TO',
    'produtor_fazenda': 'Fazenda nova',
    'produto_utilizado': 'Produto Y',
    'status': 'draft',
    'ativo': true,
    'criado_em': '2026-06-05T12:00:00.000Z',
    'atualizado_em': '2026-06-05T12:00:00.000Z',
    'sync_status': 'local_only',
  });
}

MarketingCase _publishedCase(
  String id, {
  required String syncStatus,
  String atualizadoEm = '2026-06-04T12:00:00.000Z',
}) {
  return MarketingCase.fromJson({
    'id': id,
    'tipo': 'resultado',
    'visibilidade': 'ouro',
    'lat': -10.1,
    'lng': -48.2,
    'localizacao_texto': 'Palmas, TO',
    'produtor_fazenda': 'Fazenda $id',
    'produto_utilizado': 'Produto X',
    'status': 'published',
    'ativo': true,
    'criado_em': '2026-06-04T12:00:00.000Z',
    'atualizado_em': atualizadoEm,
    'sync_status': syncStatus,
  });
}

class _StubMarketingCasesNotifier extends MarketingCasesNotifier {
  _StubMarketingCasesNotifier(
    super._repository,
    super._syncService,
    List<MarketingCase> seed,
  ) {
    state = AsyncData(seed);
  }

  @override
  Future<void> load({bool forceSync = false}) async {}
}

class _ThrowingDraftNotifier extends MarketingCasesNotifier {
  _ThrowingDraftNotifier(
    IMarketingCaseRepository repo,
    List<MarketingCase> seed,
  ) : super(repo, MarketingSyncService(repo)) {
    state = AsyncData(seed);
  }

  @override
  Future<void> load({bool forceSync = false}) async {}

  @override
  Future<MarketingCase> saveAsDraft(MarketingCase newCase) async {
    throw Exception('Falha ao persistir rascunho');
  }
}

class _StatusOkRepo implements IMarketingCaseRepository {
  int saveCalls = 0;
  int draftSaveCalls = 0;

  @override
  Future<List<MarketingCase>> fetchMarketingCases() async => const [];

  @override
  Future<List<MarketingCase>> getLocalCases() async => const [];

  @override
  Future<void> saveToCache(List<MarketingCase> cases) async {}

  @override
  Future<void> saveSingleToCache(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async {
    saveCalls++;
    return marketingCase;
  }

  @override
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async {
    draftSaveCalls++;
    return marketingCase;
  }

  @override
  Future<MarketingCase> getById(String id) async => throw UnimplementedError();

  @override
  Future<void> updateCase(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> softDelete(String id) async =>
      throw UnimplementedError();
}

class _DraftAwareRepo implements IMarketingCaseRepository {
  _DraftAwareRepo(List<MarketingCase> seed) : cases = List.of(seed);

  final List<MarketingCase> cases;

  @override
  Future<List<MarketingCase>> fetchMarketingCases() async => cases;

  @override
  Future<List<MarketingCase>> getLocalCases() async => cases;

  @override
  Future<void> saveToCache(List<MarketingCase> cases) async {}

  @override
  Future<void> saveSingleToCache(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async {
    final draft = MarketingCase.fromJson({
      ...marketingCase.toJson(),
      'status': 'draft',
      'sync_status': 'local_only',
    });
    final index = cases.indexWhere((item) => item.id == draft.id);
    if (index >= 0) {
      cases[index] = draft;
    } else {
      cases.add(draft);
    }
    return draft;
  }

  @override
  Future<MarketingCase> getById(String id) async =>
      cases.firstWhere((item) => item.id == id);

  @override
  Future<void> updateCase(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> softDelete(String id) async =>
      cases.firstWhere((item) => item.id == id);
}
