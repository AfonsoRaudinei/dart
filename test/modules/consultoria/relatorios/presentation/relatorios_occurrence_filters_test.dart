import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_marketing_case_reports_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/marketing_case_reports_list_provider.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/modules/consultoria/quick_photo/presentation/providers/quick_photo_list_provider.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/presentation/relatorios_page.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/providers/relatorio_combinado_providers.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/providers/relatorio_providers.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/providers/relatorio_repository_provider.dart'
    as publish_repo;
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/infra/marketing_case_reports_lookup_adapter.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/settings/data/settings_repository.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/settings_providers.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';

import '../../helpers/fake_relatorio_combinado_repository.dart';
import '../../helpers/fake_relatorio_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('pt_BR');
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://mock-supabase-for-tests.co',
        anonKey: 'mock-anon-key-1234567890abcdef',
      );
    }
  });

  testWidgets('linha do tempo inverte a ordem das datas', (tester) async {
    await _pumpOccurrences(tester, [
      _occurrence(
        id: 'occ-nova',
        category: 'nutricional',
        createdAt: DateTime(2026, 11, 4, 12),
      ),
      _occurrence(
        id: 'occ-antiga',
        category: 'daninhas',
        createdAt: DateTime(2026, 4, 1, 12),
      ),
    ]);

    expect(
      _dateOffset(tester, '04/11/2026'),
      lessThan(_dateOffset(tester, '01/04/2026')),
    );

    await _tapChip(tester, 'Linha do tempo');

    expect(
      _dateOffset(tester, '01/04/2026'),
      lessThan(_dateOffset(tester, '04/11/2026')),
    );
  });

  testWidgets('categoria filtra a lista e o subtítulo, e zera com andamento', (
    tester,
  ) async {
    await _pumpOccurrences(tester, [
      _occurrence(
        id: 'occ-nutri',
        category: 'nutricional',
        createdAt: DateTime(2026, 11, 4, 12),
      ),
      _occurrence(
        id: 'occ-daninha',
        category: 'daninhas',
        createdAt: DateTime(2026, 4, 1, 12),
      ),
    ]);

    expect(find.text('Lista de Ocorrências'), findsOneWidget);
    expect(find.text('2 ocorrência(s)'), findsOneWidget);
    expect(find.text('01/04/2026'), findsOneWidget);

    await _tapChip(tester, 'Nutrientes');

    expect(find.text('01/04/2026'), findsNothing);
    expect(find.text('04/11/2026'), findsOneWidget);
    expect(find.text('1 ocorrência(s)'), findsOneWidget);
    expect(find.widgetWithText(FilterChip, 'Ervas Daninhas'), findsOneWidget);

    await _tapChip(tester, 'Todas');

    expect(find.text('01/04/2026'), findsOneWidget);
    expect(find.text('04/11/2026'), findsOneWidget);
    expect(find.text('2 ocorrência(s)'), findsOneWidget);

    await _tapChip(tester, 'Resolvida');

    expect(find.text('Nenhuma ocorrência neste filtro.'), findsOneWidget);
    expect(find.text('Lista de Ocorrências'), findsNothing);
  });

  testWidgets('fazenda e talhão filtram e ocultam ocorrência sem lugar', (
    tester,
  ) async {
    await _pumpOccurrences(
      tester,
      [
        _occurrence(
          id: 'occ-sul',
          category: 'nutricional',
          fieldId: 'field-sul',
          createdAt: DateTime(2026, 3, 2, 12),
        ),
        _occurrence(
          id: 'occ-norte',
          category: 'daninhas',
          fieldId: 'field-norte',
          createdAt: DateTime(2026, 5, 3, 12),
        ),
        _occurrence(
          id: 'occ-sem-lugar',
          category: 'insetos',
          createdAt: DateTime(2026, 6, 4, 12),
        ),
      ],
      extraOverrides: [
        iFarmLookupProvider.overrideWithValue(_TwoFarmLookup()),
        iFieldLookupProvider.overrideWithValue(_TwoFieldLookup()),
      ],
    );

    expect(find.text('02/03/2026'), findsOneWidget);
    expect(find.text('03/05/2026'), findsOneWidget);
    expect(find.text('04/06/2026'), findsOneWidget);
    expect(find.text('3 ocorrência(s)'), findsOneWidget);
    expect(_dropdownLabels(tester, 1), ['Todos']);

    await _openDropdown(tester, 0);
    expect(find.text('Talhão Sul'), findsNothing);
    expect(find.text('Talhão Norte'), findsNothing);
    await tester.tap(find.text('Fazenda Sul').last);
    await tester.pumpAndSettle();

    expect(find.text('02/03/2026'), findsOneWidget);
    expect(find.text('03/05/2026'), findsNothing);
    expect(find.text('04/06/2026'), findsNothing);
    expect(find.text('1 ocorrência(s)'), findsOneWidget);
    expect(_dropdownLabels(tester, 1), ['Todos', 'Talhão Sul']);

    await _openDropdown(tester, 1);
    expect(find.text('Talhão Norte'), findsNothing);
    await tester.tap(find.text('Talhão Sul').last);
    await tester.pumpAndSettle();

    expect(find.text('02/03/2026'), findsOneWidget);
    expect(find.text('03/05/2026'), findsNothing);
    expect(find.text('Lista de Ocorrências'), findsOneWidget);
  });

  testWidgets(
    'filtro de fazenda segue ocultando a outra fazenda enquanto o índice recarrega',
    (tester) async {
      final repo = _MemoryOccurrenceRepository([
        _occurrence(
          id: 'occ-sul',
          category: 'nutricional',
          fieldId: 'field-sul',
          createdAt: DateTime(2026, 3, 2, 12),
        ),
        _occurrence(
          id: 'occ-extra',
          category: 'nutricional',
          fieldId: 'field-sul',
          createdAt: DateTime(2026, 1, 1, 12),
        ),
        _occurrence(
          id: 'occ-norte',
          category: 'daninhas',
          visitSessionId: 'sess-norte',
          createdAt: DateTime(2026, 5, 3, 12),
        ),
      ]);
      final visits = _GatedVisitLookup();
      addTearDown(() {
        if (!visits.pending.isCompleted) visits.pending.complete(null);
      });

      await _pumpOccurrences(
        tester,
        const [],
        repository: repo,
        extraOverrides: [
          iFarmLookupProvider.overrideWithValue(_TwoFarmLookup()),
          iFieldLookupProvider.overrideWithValue(_TwoFieldLookup()),
          visitSessionLookupProvider.overrideWithValue(visits),
        ],
      );

      expect(find.text('02/03/2026'), findsOneWidget);
      expect(find.text('01/01/2026'), findsOneWidget);
      expect(find.text('03/05/2026'), findsOneWidget);

      await _openDropdown(tester, 0);
      await tester.tap(find.text('Fazenda Sul').last);
      await tester.pumpAndSettle();

      expect(find.text('02/03/2026'), findsOneWidget);
      expect(find.text('01/01/2026'), findsOneWidget);
      expect(find.text('03/05/2026'), findsNothing);

      repo.remove('occ-extra');
      final context = tester.element(find.byType(RelatoriosScreen));
      ProviderScope.containerOf(context).invalidate(occurrencesListProvider);
      await tester.pump();
      await tester.pump();

      expect(find.text('01/01/2026'), findsNothing);
      expect(find.text('02/03/2026'), findsOneWidget);
      expect(find.text('03/05/2026'), findsNothing);
      expect(visits.calls, greaterThan(1));
    },
  );
}

Occurrence _occurrence({
  required String id,
  required String category,
  required DateTime createdAt,
  String? fieldId,
  String? visitSessionId,
}) {
  return Occurrence(
    id: id,
    type: 'Média',
    description: id,
    category: category,
    status: 'draft',
    clientId: 'cli-test-1',
    fieldId: fieldId,
    visitSessionId: visitSessionId,
    createdAt: createdAt,
  );
}

double _dateOffset(WidgetTester tester, String label) {
  final finder = find.text(label);
  expect(finder, findsOneWidget);
  return tester.getTopLeft(finder).dy;
}

List<String> _dropdownLabels(WidgetTester tester, int index) {
  final dropdown = tester.widget<DropdownButton<String>>(
    find.byType(DropdownButton<String>).at(index),
  );
  return [
    for (final item in dropdown.items ?? const <DropdownMenuItem<String>>[])
      if (item.child is Text) (item.child as Text).data ?? '',
  ];
}

Future<void> _openDropdown(WidgetTester tester, int index) async {
  final target = find.byType(DropdownButton<String>).at(index);
  await _ensureTapped(tester, target);
}

Future<void> _tapChip(WidgetTester tester, String label) async {
  await _ensureTapped(tester, find.widgetWithText(FilterChip, label));
}

Future<void> _ensureTapped(WidgetTester tester, Finder target) async {
  final scrollable = find.byWidgetPredicate(
    (widget) => widget is Scrollable && widget.axis == Axis.vertical,
  );
  if (scrollable.evaluate().isNotEmpty) {
    await tester.scrollUntilVisible(target, 240, scrollable: scrollable.first);
  }
  await tester.ensureVisible(target);
  await tester.tap(target);
  await tester.pumpAndSettle();
}

Future<void> _pumpOccurrences(
  WidgetTester tester,
  List<Occurrence> occurrences, {
  OccurrenceRepository? repository,
  List<Override> extraOverrides = const [],
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 1600));
  addTearDown(() => tester.binding.setSurfaceSize(null));

  final relatorioRepository = FakeRelatorioRepository();
  final preferences = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserRoleProvider.overrideWithValue(UserRole.consultor),
        clientLookupProvider.overrideWithValue(_FilterClientLookup()),
        relatorioRepositoryProvider.overrideWithValue(relatorioRepository),
        publish_repo.relatorioRepositoryProvider.overrideWithValue(
          relatorioRepository,
        ),
        occurrenceRepositoryProvider.overrideWithValue(
          repository ?? _MemoryOccurrenceRepository(occurrences),
        ),
        marketingCaseRepositoryProvider.overrideWithValue(
          _EmptyMarketingRepository(),
        ),
        marketingCaseReportsLookupProvider.overrideWith(
          (ref) => MarketingCaseReportsLookupAdapter(ref),
        ),
        marketingCaseReportsListProvider.overrideWith(
          (ref) => ref.watch(marketingCaseReportsListImplProvider),
        ),
        relatorioCombinadoRepositoryProvider.overrideWithValue(
          FakeRelatorioCombinadoRepository(),
        ),
        quickPhotoListProvider.overrideWith((ref) async => const []),
        settingsRepositoryProvider.overrideWithValue(
          SettingsRepository(preferences),
        ),
        ...extraOverrides,
      ],
      child: const MaterialApp(home: Scaffold(body: RelatoriosScreen())),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ocorrências').first);
  await tester.pumpAndSettle();
}

class _MemoryOccurrenceRepository extends OccurrenceRepository {
  _MemoryOccurrenceRepository(List<Occurrence> occurrences) {
    for (final occurrence in occurrences) {
      _store[occurrence.id] = occurrence;
    }
  }

  final Map<String, Occurrence> _store = {};

  void remove(String id) => _store.remove(id);

  @override
  Future<List<Occurrence>> getAllOccurrences() async => _store.values.toList();
}

class _GatedVisitLookup implements IVisitSessionLookup {
  final Completer<VisitSessionSummary?> pending = Completer();
  int calls = 0;

  @override
  Future<VisitSessionSummary?> findById(String sessionId) {
    calls += 1;
    if (calls == 1) {
      return Future.value(
        VisitSessionSummary(
          id: sessionId,
          producerId: 'cli-test-1',
          status: 'finished',
          startTime: DateTime.utc(2026, 5, 3),
          areaId: 'field-norte',
        ),
      );
    }
    return pending.future;
  }

  @override
  Future<VisitSessionSummary?> getActiveSession() async => null;

  @override
  Future<List<VisitSessionSummary>> listFinished() async => const [];
}

class _FilterClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async {
    if (id == 'cli-test-1') {
      return const ClientSummary(
        id: 'cli-test-1',
        name: 'Produtor Teste',
        active: true,
      );
    }
    return null;
  }

  @override
  Future<List<ClientSummary>> listAtivos() async => const [
    ClientSummary(id: 'cli-test-1', name: 'Produtor Teste', active: true),
  ];
}

class _EmptyMarketingRepository implements IMarketingCaseRepository {
  @override
  Future<List<MarketingCase>> fetchMarketingCases() async => const [];

  @override
  Future<MarketingCase> getById(String id) => throw StateError(id);

  @override
  Future<List<MarketingCase>> getLocalCases() async => const [];

  @override
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async =>
      marketingCase;

  @override
  Future<void> saveSingleToCache(MarketingCase marketingCase) async {}

  @override
  Future<void> saveToCache(List<MarketingCase> cases) async {}

  @override
  Future<MarketingCase> softDelete(String id) => throw StateError(id);

  @override
  Future<void> updateCase(MarketingCase marketingCase) async {}
}

class _TwoFarmLookup implements IFarmLookup {
  @override
  Future<FarmSummary?> findById(String farmId) async => null;

  @override
  Future<List<FarmSummary>> getFarmsByClient(String clientId) async {
    if (clientId != 'cli-test-1') return const [];
    return const [
      FarmSummary(id: 'farm-sul', clientId: 'cli-test-1', name: 'Fazenda Sul'),
      FarmSummary(
        id: 'farm-norte',
        clientId: 'cli-test-1',
        name: 'Fazenda Norte',
      ),
    ];
  }

  @override
  Future<void> saveFarm({
    required String clientId,
    required String farmId,
    required String name,
    required String city,
    required String state,
    required double areaHa,
  }) async {}
}

class _TwoFieldLookup implements IFieldLookup {
  static const _fields = [
    FieldSummary(id: 'field-sul', name: 'Talhão Sul', farmId: 'farm-sul'),
    FieldSummary(id: 'field-norte', name: 'Talhão Norte', farmId: 'farm-norte'),
  ];

  @override
  Future<FieldSummary?> findById(String fieldId) async {
    for (final field in _fields) {
      if (field.id == fieldId) return field;
    }
    return null;
  }

  @override
  Future<List<FieldSummary>> listAll() async => _fields;

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async =>
      _fields.where((field) => field.farmId == farmId).toList();
}
