import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/infra/marketing_case_reports_lookup_adapter.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/planos/domain/plano_cache_unavailable_exception.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';

final _adapterProvider = Provider<MarketingCaseReportsLookupAdapter>((ref) {
  return MarketingCaseReportsLookupAdapter(ref);
});

void main() {
  testWidgets(
    'publishDraftCase não bloqueia localmente quando plano indisponível',
    (tester) async {
      final draft = _draftCase('draft-1');
      final repo = _RecordingRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketingCaseRepositoryProvider.overrideWithValue(repo),
            planoAtivoProvider.overrideWith(
              (ref) async => throw const PlanoCacheUnavailableException(
                expired: true,
              ),
            ),
            marketingCasesProvider.overrideWith((ref) {
              final sync = ref.watch(marketingSyncServiceProvider);
              return _SeedNotifier(repo, sync, ref, [draft]);
            }),
          ],
          child: const MaterialApp(home: _PublishDraftHarness('draft-1')),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('ok'), findsOneWidget);
      expect(repo.saveCalls, 1);
    },
  );
}

class _PublishDraftHarness extends ConsumerStatefulWidget {
  const _PublishDraftHarness(this.caseId);

  final String caseId;

  @override
  ConsumerState<_PublishDraftHarness> createState() =>
      _PublishDraftHarnessState();
}

class _PublishDraftHarnessState extends ConsumerState<_PublishDraftHarness> {
  String label = 'pending';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    final adapter = ref.read(_adapterProvider);
    final published =
        await adapter.publishDraftCase(context, widget.caseId);
    if (!mounted) return;
    setState(() => label = published ? 'ok' : 'blocked');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: Text(label));
  }
}

MarketingCase _draftCase(String id) {
  return MarketingCase.fromJson({
    'id': id,
    'tipo': 'resultado',
    'visibilidade': 'ouro',
    'lat': -10.2,
    'lng': -48.3,
    'localizacao_texto': 'Palmas, TO',
    'produtor_fazenda': 'Fazenda',
    'produto_utilizado': 'Produto',
    'status': MarketingCaseStatus.draft.toValue(),
    'ativo': true,
    'criado_em': '2026-06-05T12:00:00.000Z',
    'atualizado_em': '2026-06-05T12:00:00.000Z',
    'sync_status': 'local_only',
  });
}

class _SeedNotifier extends MarketingCasesNotifier {
  _SeedNotifier(
    IMarketingCaseRepository repository,
    MarketingSyncService syncService,
    Ref ref,
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
  Future<MarketingCase> softDelete(String id) async =>
      throw UnimplementedError();
}