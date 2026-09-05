import 'dart:io';

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
import 'package:supabase_flutter/supabase_flutter.dart';

/// Garante que o fluxo do mapa promove o case para `published` antes de publicar,
/// para que o pin apareça em [IsolatedMarketingMarkersLayer].
void main() {
  group('novo_case_publish_status_regression', () {
    testWidgets('submitCaseFromMap publica com status published', (
      tester,
    ) async {
      final repo = _StatusTrackingRepo();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketingCaseRepositoryProvider.overrideWithValue(repo),
            marketingCasesProvider.overrideWith((ref) {
              final sync = ref.watch(marketingSyncServiceProvider);
              return _StubMarketingCasesNotifier(repo, sync, const []);
            }),
            planoAtivoProvider.overrideWith(
              (ref) async => UserPlan.free(userId: 'test-user'),
            ),
          ],
          child: const MaterialApp(home: _PublishHarness()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_case')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(repo.lastSavedCase, isNotNull);
      expect(repo.lastSavedCase!.status.toValue(), 'published');
      expect(
        find.text('Case publicado com sucesso! 📈'),
        findsOneWidget,
      );
    });

    test('case published passa no filtro da camada de pins', () {
      final published = MarketingCase.fromJson({
        'id': 'mkt-pin',
        'tipo': 'resultado',
        'visibilidade': 'ouro',
        'lat': -10.1,
        'lng': -48.2,
        'localizacao_texto': 'Palmas, TO',
        'produtor_fazenda': 'Fazenda',
        'produto_utilizado': 'Produto X',
        'status': 'published',
        'ativo': true,
        'criado_em': '2026-06-04T12:00:00.000Z',
        'atualizado_em': '2026-06-04T12:00:00.000Z',
        'sync_status': 'synced',
      });

      final draft = MarketingCase.fromJson({
        ...published.toJson(),
        'id': 'mkt-draft',
        'status': 'draft',
      });

      bool isPinVisible(MarketingCase c) =>
          c.status.toValue() == 'published' &&
          c.ativo &&
          c.deletadoEm == null;

      expect(isPinVisible(published), isTrue);
      expect(isPinVisible(draft), isFalse);
    });
  });
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

class _StatusTrackingRepo implements IMarketingCaseRepository {
  MarketingCase? lastSavedCase;

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
    lastSavedCase = marketingCase;
    return MarketingCase.fromJson({
      ...marketingCase.toJson(),
      'sync_status': 'synced',
    });
  }

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
