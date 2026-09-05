import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';
import 'package:soloforte_app/ui/screens/map/handlers/novo_case_modal_launcher.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Garante que erros não-rede não sejam rotulados como "offline".
void main() {
  group('novo_case_publish_error_classification', () {
    test('classificadores distinguem sessão, rede e genérico', () {
      expect(
        NovoCaseModalLauncher.isSessionOrRlsError(
          const AuthException('JWT expired'),
        ),
        isTrue,
      );
      expect(
        NovoCaseModalLauncher.isSessionOrRlsError(
          StateError('Usuario nao autenticado.'),
        ),
        isTrue,
      );
      expect(
        NovoCaseModalLauncher.isSessionOrRlsError(
          const PostgrestException(code: '42501', message: 'RLS'),
        ),
        isTrue,
      );
      expect(
        NovoCaseModalLauncher.isNetworkError(
          const SocketException('Failed host lookup'),
        ),
        isTrue,
      );
      expect(
        NovoCaseModalLauncher.isNetworkError(
          Exception('PGRST204 column missing'),
        ),
        isFalse,
      );
    });

    testWidgets('erro de sessão na publicação não exibe offline', (
      tester,
    ) async {
      final repo = _ThrowingRepo(StateError('Usuario nao autenticado.'));

      await tester.pumpWidget(
        _buildHarness(
          repo: repo,
          connectivity: const AsyncData(true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_case')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.text('Sessão expirada. Entre novamente para publicar.'),
        findsOneWidget,
      );
      expect(find.textContaining('Sem conexão'), findsNothing);
    });

    testWidgets('erro genérico na publicação não exibe offline', (
      tester,
    ) async {
      final repo = _ThrowingRepo(
        Exception('PGRST204: column marketing_cases.foo does not exist'),
      );

      await tester.pumpWidget(
        _buildHarness(
          repo: repo,
          connectivity: const AsyncData(true),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_case')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.text('Não foi possível publicar o case. Tente novamente.'),
        findsOneWidget,
      );
      expect(find.textContaining('Sem conexão'), findsNothing);
    });

    testWidgets('erro de rede na publicação exibe offline', (tester) async {
      final repo = _ThrowingRepo(const SocketException('Network unreachable'));

      await tester.pumpWidget(
        _buildHarness(
          repo: repo,
          connectivity: const AsyncData(false),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_case')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.text(
          'Sem conexão — case salvo localmente e será sincronizado.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('planoAtivoProvider em erro de sessão não exibe offline', (
      tester,
    ) async {
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
              (ref) async => throw const AuthException('JWT expired'),
            ),
            connectivityStateProvider.overrideWith(
              (ref) => Stream.value(true),
            ),
          ],
          child: const MaterialApp(home: _PublishHarness()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('submit_case')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(
        find.text('Sessão expirada. Entre novamente para publicar.'),
        findsOneWidget,
      );
      expect(find.textContaining('Sem conexão'), findsNothing);
      expect(repo.saveCalls, 0);
    });

    testWidgets('planoAtivoProvider em erro de rede exibe mensagem honesta', (
      tester,
    ) async {
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
              (ref) async => throw const SocketException('Failed host lookup'),
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

      expect(
        find.text('Sem conexão. Não foi possível verificar seu plano.'),
        findsOneWidget,
      );
      expect(repo.saveCalls, 0);
    });

    test('falha permanente reverte case para draft no state', () async {
      final repo = _ThrowingRepo(
        const PostgrestException(code: '42501', message: 'RLS'),
      );
      final sync = MarketingSyncService(repo);
      final notifier = _StubMarketingCasesNotifier(repo, sync, const []);

      final published = MarketingCase.fromJson({
        ..._draftCase().toJson(),
        'status': 'published',
      });

      final outcome = await notifier.publishCaseDetailed(published);
      expect(outcome.isSuccess, isFalse);

      final stored = notifier.state.valueOrNull!.singleWhere(
        (c) => c.id == published.id,
      );
      expect(stored.status.toValue(), 'draft');
      expect(stored.syncStatus, 'local_only');
    });
  });
}

Widget _buildHarness({
  required IMarketingCaseRepository repo,
  required AsyncValue<bool> connectivity,
}) {
  return ProviderScope(
    overrides: [
      marketingCaseRepositoryProvider.overrideWithValue(repo),
      marketingCasesProvider.overrideWith((ref) {
        final sync = ref.watch(marketingSyncServiceProvider);
        return _StubMarketingCasesNotifier(repo, sync, const []);
      }),
      planoAtivoProvider.overrideWith(
        (ref) async => UserPlan.free(userId: 'test-user'),
      ),
      connectivityStateProvider.overrideWith(
        (ref) => Stream.value(connectivity.value ?? true),
      ),
    ],
    child: const MaterialApp(home: _PublishHarness()),
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

class _ThrowingRepo implements IMarketingCaseRepository {
  _ThrowingRepo(this.error);

  final Object error;

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
    throw error;
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

class _StatusOkRepo implements IMarketingCaseRepository {
  int saveCalls = 0;

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
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<MarketingCase> getById(String id) async => throw UnimplementedError();

  @override
  Future<void> updateCase(MarketingCase marketingCase) async {}

  @override
  Future<MarketingCase> softDelete(String id) async => throw UnimplementedError();
}
