import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/presentation/relatorios_page.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/providers/relatorio_providers.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/providers/relatorio_repository_provider.dart'
    as publish_repo;
import 'package:soloforte_app/modules/consultoria/quick_photo/presentation/providers/quick_photo_list_provider.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';

import '../../modules/consultoria/helpers/consultoria_test_factories.dart';
import '../../modules/consultoria/helpers/fake_relatorio_repository.dart';

/// BUG-004 — RelatoriosScreen: dados fictícios / providers errados.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  group('BUG-004 relatorios_screen_regression', () {
    test('relatorios_page.dart usa providers reais como fonte de dados', () {
      final pageSource = File(
        'lib/modules/consultoria/relatorios/presentation/relatorios_page.dart',
      ).readAsStringSync();
      final consolidatedSource = File(
        'lib/modules/consultoria/relatorios/presentation/relatorios_consolidated_reports.dart',
      ).readAsStringSync();

      expect(pageSource.contains('occurrencesListProvider'), isTrue);
      expect(pageSource.contains('_relatoriosTecnicosListProvider'), isTrue);
      expect(consolidatedSource.contains('marketingCasesProvider'), isTrue);
      expect(pageSource.contains('ref.watch(relatoriosListProvider)'), isFalse);
    });

    testWidgets(
      'RelatoriosScreen exibe relatório vindo do provider, não lista hardcoded',
      (tester) async {
        final relatorioRepository = FakeRelatorioRepository();
        relatorioRepository.seed([
          makeRelatorio(
            id: 'r1',
            farmName: 'Fazenda Regression Shield',
          ),
        ]);

        await _pumpRelatoriosScreen(
          tester,
          relatorioRepository: relatorioRepository,
          occurrenceRepository: FakeOccurrenceRepository(),
        );

        expect(find.text('Relatórios de Visita'), findsOneWidget);
        expect(find.text('Fazenda Regression Shield'), findsWidgets);
        expect(find.text('Nenhum relatório gerado ainda.'), findsNothing);
      },
    );

    testWidgets(
      'seção de ocorrências exibe item de occurrencesListProvider',
      (tester) async {
        final occurrenceRepository = FakeOccurrenceRepository()
          ..seed([
            Occurrence(
              id: 'o1',
              type: 'Alta',
              description: 'Ocorrência regression shield',
              category: 'insetos',
              status: 'draft',
              createdAt: DateTime.utc(2026, 7, 30, 12),
            ),
          ]);

        await _pumpRelatoriosScreen(
          tester,
          relatorioRepository: FakeRelatorioRepository(),
          occurrenceRepository: occurrenceRepository,
        );

        await tester.tap(find.text('Ocorrências').first);
        await tester.pumpAndSettle();

        expect(find.text('Ocorrências Registradas'), findsOneWidget);
        expect(find.textContaining('Insetos'), findsWidgets);
        expect(find.text('Urgência: Alta'), findsOneWidget);
        expect(find.text('Nenhuma ocorrência registrada.'), findsNothing);
      },
    );

    testWidgets(
      'seção de marketing exibe item de marketingCasesProvider',
      (tester) async {
        await _pumpRelatoriosScreen(
          tester,
          relatorioRepository: FakeRelatorioRepository(),
          occurrenceRepository: FakeOccurrenceRepository(),
          marketingCases: [_marketingCase()],
        );

        await tester.tap(find.text('Gerados').first);
        await tester.pumpAndSettle();
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();

        expect(find.text('Marketing Cases'), findsOneWidget);
        expect(find.text('Produtor Regression - Fazenda Marketing'), findsOneWidget);
      },
    );
  });
}

Future<void> _pumpRelatoriosScreen(
  WidgetTester tester, {
  required FakeRelatorioRepository relatorioRepository,
  required FakeOccurrenceRepository occurrenceRepository,
  List<MarketingCase>? marketingCases,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        currentUserRoleProvider.overrideWithValue(UserRole.consultor),
        relatorioRepositoryProvider.overrideWithValue(relatorioRepository),
        publish_repo.relatorioRepositoryProvider.overrideWithValue(
          relatorioRepository,
        ),
        occurrenceRepositoryProvider.overrideWithValue(occurrenceRepository),
        marketingCaseRepositoryProvider.overrideWithValue(
          FakeMarketingCaseRepository(marketingCases ?? const []),
        ),
        quickPhotoListProvider.overrideWith((ref) async => const []),
      ],
      child: const MaterialApp(home: Scaffold(body: RelatoriosScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

class FakeOccurrenceRepository extends OccurrenceRepository {
  final Map<String, Occurrence> _store = {};

  void seed(List<Occurrence> occurrences) {
    for (final occurrence in occurrences) {
      _store[occurrence.id] = occurrence;
    }
  }

  @override
  Future<List<Occurrence>> getAllOccurrences() async {
    return _store.values
        .where((occurrence) => occurrence.syncStatus != 'deleted')
        .toList();
  }
}

class FakeMarketingCaseRepository implements IMarketingCaseRepository {
  final List<MarketingCase> cases;

  const FakeMarketingCaseRepository(this.cases);

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
    return marketingCase;
  }

  @override
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async {
    return marketingCase;
  }

  @override
  Future<MarketingCase> getById(String id) async {
    return cases.firstWhere((item) => item.id == id);
  }

  @override
  Future<void> updateCase(MarketingCase marketingCase) async {}
}

MarketingCase _marketingCase() {
  return MarketingCase.fromJson({
    'id': 'm1',
    'tipo': 'resultado',
    'visibilidade': 'ouro',
    'lat': -10.1,
    'lng': -48.2,
    'localizacao_texto': 'Palmas, TO',
    'produtor_fazenda': 'Produtor Regression - Fazenda Marketing',
    'produto_utilizado': 'Produto X',
    'produtividade_valor': 72,
    'produtividade_unidade': 'sc/ha',
    'nome_vendedor': 'Vendedor Teste',
    'telefone_vendedor': '(63) 99999-0000',
    'descricao': 'Case de regression shield.',
    'quantidade_produzida': 1800,
    'status': 'published',
    'criado_em': '2026-07-30T12:00:00.000Z',
    'atualizado_em': '2026-07-30T12:00:00.000Z',
    'sync_status': 'synced',
  });
}
