import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';

void main() {
  group('publishedCasesProvider — gate de plano (leitura)', () {
    test('plano expirado oculta pins; status published inalterado na fonte', () async {
      final published = _publishedCase('c1');
      final container = _container(
        cases: [published],
        plano: (ref) async => _userPlan(expiraEm: DateTime.utc(2020, 1, 1)),
      );
      addTearDown(container.dispose);

      await container.read(planoAtivoProvider.future);

      expect(container.read(publishedCasesProvider), isEmpty);
      expect(
        container.read(marketingCasesProvider).value!.single.status.toValue(),
        'published',
      );
    });

    test('plano reativado exibe todos os pins de volta', () async {
      final cases = [
        _publishedCase('c1'),
        _publishedCase('c2'),
      ];

      final expiredContainer = _container(
        cases: cases,
        plano: (ref) async => _userPlan(expiraEm: DateTime.utc(2020, 1, 1)),
      );
      addTearDown(expiredContainer.dispose);
      await expiredContainer.read(planoAtivoProvider.future);
      expect(expiredContainer.read(publishedCasesProvider), isEmpty);

      final activeContainer = _container(
        cases: cases,
        plano: (ref) async => _userPlan(expiraEm: DateTime.utc(2027, 1, 1)),
      );
      addTearDown(activeContainer.dispose);
      await activeContainer.read(planoAtivoProvider.future);
      expect(activeContainer.read(publishedCasesProvider).length, 2);
    });

    test('plano carregando mantém pins visíveis', () {
      final published = _publishedCase('c1');
      final planCompleter = Completer<UserPlan>();
      final container = ProviderContainer(
        overrides: [
          marketingCaseRepositoryProvider.overrideWithValue(_EmptyRepo()),
          marketingCasesProvider.overrideWith((ref) {
            final sync = ref.watch(marketingSyncServiceProvider);
            return _StubCasesNotifier(sync, [published]);
          }),
          planoAtivoProvider.overrideWith((ref) => planCompleter.future),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(publishedCasesProvider).length, 1);
    });

    test('erro ao ler plano mantém pins visíveis (fail-open)', () async {
      final published = _publishedCase('c1');
      final container = _container(
        cases: [published],
        plano: (ref) async => throw Exception('plano indisponível'),
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(planoAtivoProvider.future),
        throwsA(isA<Exception>()),
      );

      expect(container.read(publishedCasesProvider).length, 1);
    });

    test('admin com plano expirado não oculta pins', () async {
      final published = _publishedCase('c1');
      final container = _container(
        cases: [published],
        plano: (ref) async => _userPlan(
          expiraEm: DateTime.utc(2020, 1, 1),
          isAdmin: true,
        ),
      );
      addTearDown(container.dispose);

      await container.read(planoAtivoProvider.future);

      expect(container.read(publishedCasesProvider).length, 1);
    });
  });
}

ProviderContainer _container({
  required List<MarketingCase> cases,
  required Future<UserPlan> Function(PlanoAtivoRef ref) plano,
}) {
  return ProviderContainer(
    overrides: [
      marketingCaseRepositoryProvider.overrideWithValue(_EmptyRepo()),
      marketingCasesProvider.overrideWith((ref) {
        final sync = ref.watch(marketingSyncServiceProvider);
        return _StubCasesNotifier(sync, cases);
      }),
      planoAtivoProvider.overrideWith(plano),
    ],
  );
}

UserPlan _userPlan({
  required DateTime expiraEm,
  bool isAdmin = false,
  bool ativo = true,
}) {
  return UserPlan(
    id: 'plan-1',
    userId: 'user-1',
    plano: PlanoTipo.bronze,
    origem: PlanoOrigem.pagamento,
    ativo: ativo,
    isAdmin: isAdmin,
    iniciouEm: DateTime.utc(2026, 1, 1),
    expiraEm: expiraEm,
    criadoEm: DateTime.utc(2026, 1, 1),
  );
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

class _StubCasesNotifier extends MarketingCasesNotifier {
  _StubCasesNotifier(MarketingSyncService sync, List<MarketingCase> seed)
    : super(_EmptyRepo(), sync, null) {
    state = AsyncData(seed);
  }

  @override
  Future<void> load({bool forceSync = false}) async {}
}

class _EmptyRepo implements IMarketingCaseRepository {
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
