import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/marketing_case_reports_list_provider.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/infra/marketing_case_reports_lookup_adapter.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';

void main() {
  test('published + plano expirado marca pinOcultoNoMapa no snapshot', () async {
    final published = _case(status: 'published');
    final container = ProviderContainer(
      overrides: [
        marketingCaseRepositoryProvider.overrideWithValue(_EmptyRepo()),
        marketingCasesProvider.overrideWith((ref) {
          final sync = ref.watch(marketingSyncServiceProvider);
          return _StubCasesNotifier(sync, [published]);
        }),
        currentUserRoleProvider.overrideWith((ref) => UserRole.consultor),
        planoAtivoProvider.overrideWith(
          (ref) async => _plan(expiraEm: DateTime.utc(2020, 1, 1)),
        ),
        marketingCaseReportsListProvider.overrideWith(
          (ref) => ref.watch(marketingCaseReportsListImplProvider),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(planoAtivoProvider.future);
    final list = container.read(marketingCaseReportsListProvider).requireValue;
    expect(list, hasLength(1));
    expect(list.single.pinOcultoNoMapa, isTrue);
    expect(list.single.statusValue, 'published');
  });

  test('published + plano ativo não marca pinOcultoNoMapa', () async {
    final published = _case(status: 'published');
    final container = ProviderContainer(
      overrides: [
        marketingCaseRepositoryProvider.overrideWithValue(_EmptyRepo()),
        marketingCasesProvider.overrideWith((ref) {
          final sync = ref.watch(marketingSyncServiceProvider);
          return _StubCasesNotifier(sync, [published]);
        }),
        currentUserRoleProvider.overrideWith((ref) => UserRole.consultor),
        planoAtivoProvider.overrideWith(
          (ref) async => _plan(expiraEm: DateTime.utc(2028, 1, 1)),
        ),
        marketingCaseReportsListProvider.overrideWith(
          (ref) => ref.watch(marketingCaseReportsListImplProvider),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(planoAtivoProvider.future);
    final list = container.read(marketingCaseReportsListProvider).requireValue;
    expect(list.single.pinOcultoNoMapa, isFalse);
  });
}

UserPlan _plan({required DateTime expiraEm}) {
  return UserPlan(
    id: 'p1',
    userId: 'u1',
    plano: PlanoTipo.bronze,
    origem: PlanoOrigem.pagamento,
    ativo: true,
    iniciouEm: DateTime.utc(2026, 1, 1),
    expiraEm: expiraEm,
    criadoEm: DateTime.utc(2026, 1, 1),
  );
}

MarketingCase _case({required String status}) {
  return MarketingCase.fromJson({
    'id': 'c1',
    'tipo': 'resultado',
    'visibilidade': 'ouro',
    'lat': -10.1,
    'lng': -48.2,
    'localizacao_texto': 'Palmas, TO',
    'produtor_fazenda': 'Fazenda Teste',
    'produto_utilizado': 'Produto X',
    'status': status,
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
