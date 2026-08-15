import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';
import 'package:soloforte_app/ui/screens/map/handlers/novo_case_modal_launcher.dart';

void main() {
  testWidgets('no limite do plano Publicar salva rascunho e exibe snackbar', (
    tester,
  ) async {
    final repo = _LauncherFakeMarketingRepo([
      _publishedCase('mkt-1'),
      _publishedCase('mkt-2'),
      _publishedCase('mkt-3'),
    ]);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketingCaseRepositoryProvider.overrideWithValue(repo),
          marketingCasesProvider.overrideWith((ref) {
            final sync = ref.watch(marketingSyncServiceProvider);
            return _StubMarketingCasesNotifier(
              repo,
              sync,
              [
                _publishedCase('mkt-1'),
                _publishedCase('mkt-2'),
                _publishedCase('mkt-3'),
              ],
            );
          }),
          planoAtivoProvider.overrideWith(
            (ref) async => UserPlan.free(userId: 'test-user'),
          ),
        ],
        child: MaterialApp(
          home: const _LauncherHarness(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('open_sheet')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('submit_case')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));

    expect(
      find.textContaining('Salvo como Não gerado em Relatórios → Marketing'),
      findsOneWidget,
    );
    expect(repo.cases.length, 4);
    expect(
      repo.cases.singleWhere((c) => c.id == 'mkt-new').status.toValue(),
      'draft',
    );

    expect(find.text('Case salvo com sucesso!'), findsOneWidget);
    await tester.tap(find.text('Ok, entendi'));
    await tester.pumpAndSettle();
  });
}

class _LauncherHarness extends ConsumerWidget {
  const _LauncherHarness();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ElevatedButton(
        key: const Key('open_sheet'),
        onPressed: () {
          showModalBottomSheet<void>(
            context: context,
            builder: (sheetContext) => SizedBox(
              height: 200,
              child: Center(
                child: ElevatedButton(
                  key: const Key('submit_case'),
                  onPressed: () {
                    NovoCaseModalLauncher.submitCaseFromMap(
                      context: sheetContext,
                      ref: ref,
                      newCase: _newDraftCase(),
                    );
                  },
                  child: const Text('Publicar'),
                ),
              ),
            ),
          );
        },
        child: const Text('Abrir sheet'),
      ),
    );
  }
}

MarketingCase _publishedCase(String id) {
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
    'atualizado_em': '2026-06-04T12:00:00.000Z',
    'sync_status': 'synced',
  });
}

MarketingCase _newDraftCase() {
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

class _StubMarketingCasesNotifier extends MarketingCasesNotifier {
  _StubMarketingCasesNotifier(
    IMarketingCaseRepository repo,
    MarketingSyncService sync,
    List<MarketingCase> seed,
  ) : super(repo, sync) {
    state = AsyncData(seed);
  }

  @override
  Future<void> load({bool forceSync = false}) async {}
}

class _LauncherFakeMarketingRepo implements IMarketingCaseRepository {
  _LauncherFakeMarketingRepo(List<MarketingCase> seed) : cases = List.of(seed);

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
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async {
    cases.add(marketingCase);
    return marketingCase;
  }

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
