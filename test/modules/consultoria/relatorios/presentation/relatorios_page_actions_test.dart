import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/models/relatorio_status.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/presentation/relatorios_page.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/providers/relatorio_providers.dart';
import 'package:soloforte_app/modules/consultoria/relatorios/providers/relatorio_repository_provider.dart'
    as publish_repo;
import 'package:soloforte_app/modules/consultoria/relatorios/models/visit_session_snapshot.dart';
import 'package:soloforte_app/modules/consultoria/quick_photo/presentation/providers/quick_photo_list_provider.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';

import '../../helpers/consultoria_test_factories.dart';
import '../../helpers/fake_relatorio_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting('pt_BR');
  });

  testWidgets('ações reais de relatório publicam e excluem', (
    tester,
  ) async {
    final relatorioRepository = FakeRelatorioRepository();
    relatorioRepository.seed([
      makeRelatorio(
        id: 'rel-draft',
        farmName: 'Fazenda Rascunho',
        status: RelatorioStatus.pendente_revisao,
      ),
      makeRelatorio(
        id: 'rel-published',
        farmName: 'Fazenda Publicada',
        status: RelatorioStatus.publicado,
      ),
    ]);

    await _pumpScreen(
      tester,
      relatorioRepository: relatorioRepository,
      occurrenceRepository: FakeOccurrenceRepository(),
    );

    expect(find.text('Relatórios de Visita'), findsOneWidget);
    expect(find.text('Fazenda Rascunho'), findsWidgets);

    await _openReportMenu(tester, index: 0);
    expect(find.text('Pré-visualizar HTML'), findsOneWidget);
    expect(find.text('Exportar'), findsOneWidget);
    expect(find.text('Publicar'), findsOneWidget);
    await tester.tap(find.text('Publicar'));
    await _pumpActionFrame(tester);
    expect(find.text('Publicar relatório?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Publicar'));
    await _pumpActionFrame(tester);

    expect(
      relatorioRepository.get('rel-draft')?.status,
      RelatorioStatus.publicado,
    );
    expect(
      relatorioRepository.get('rel-draft')?.syncStatus,
      RelatorioSyncStatus.pending_sync,
    );

    await _openReportMenu(tester, index: 0);
    await tester.tap(find.text('Excluir').last);
    await _pumpActionFrame(tester);
    expect(find.text('Excluir relatório?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await _pumpActionFrame(tester);

    expect(relatorioRepository.get('rel-draft')?.deletedAt, isNotNull);
    expect(find.text('Fazenda Rascunho'), findsNothing);
  });

  testWidgets('ações reais de ocorrência confirmam e excluem logicamente', (
    tester,
  ) async {
    final occurrenceRepository = FakeOccurrenceRepository()
      ..seed([
        Occurrence(
          id: 'occ-1',
          type: 'Média',
          description: 'Insetos no baixeiro',
          category: 'insetos',
          status: 'draft',
          createdAt: DateTime.utc(2026, 6, 3, 12),
        ),
      ]);

    await _pumpScreen(
      tester,
      relatorioRepository: FakeRelatorioRepository(),
      occurrenceRepository: occurrenceRepository,
    );

    await _selectSegment(tester, 'Ocorrências');
    expect(find.text('Ocorrências Registradas'), findsOneWidget);
    expect(find.textContaining('Insetos'), findsWidgets);
    expect(find.text('Urgência: Média'), findsOneWidget);

    await _openOccurrenceMenu(tester, index: 0);
    expect(find.text('Confirmar'), findsOneWidget);
    await tester.tap(find.text('Confirmar'));
    await _pumpActionFrame(tester);

    expect(occurrenceRepository.get('occ-1')?.status, 'confirmed');
    expect(find.text('Confirmada'), findsOneWidget);

    await _openOccurrenceMenu(tester, index: 0);
    await tester.tap(find.text('Excluir').last);
    await _pumpActionFrame(tester);
    expect(find.text('Excluir ocorrência?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await _pumpActionFrame(tester);

    expect(occurrenceRepository.get('occ-1')?.syncStatus, 'deleted');
    expect(find.text('Nenhuma ocorrência registrada.'), findsOneWidget);
  });

  testWidgets('exibe UI dedicada para consolidados e marketing cases', (
    tester,
  ) async {
    final relatorioRepository = FakeRelatorioRepository();
    relatorioRepository.seed([
      makeRelatorio(
        id: 'rel-consolidated',
        farmName: 'Fazenda Consolidada',
        status: RelatorioStatus.publicado,
      ).copyWith(
        talhoes: const [
          TalhaoVisitado(
            talhaoId: 'talhao-1',
            nomeTalhao: 'Talhao Norte',
            areaHectares: 42,
            cultura: 'Soja',
            safra: '2025/26',
          ),
        ],
      ),
    ]);

    final occurrenceRepository = FakeOccurrenceRepository()
      ..seed([
        Occurrence(
          id: 'occ-consolidated',
          type: 'Baixa',
          description: 'Ocorrência consolidada',
          category: 'daninhas',
          status: 'confirmed',
          createdAt: DateTime.utc(2026, 6, 4, 12),
        ),
      ]);

    await _pumpScreen(
      tester,
      relatorioRepository: relatorioRepository,
      occurrenceRepository: occurrenceRepository,
      marketingCases: [_marketingCase()],
    );

    await _selectSegment(tester, 'Gerados');
    expect(find.text('Relatórios Consolidados'), findsOneWidget);
    expect(find.text('Lista de Ocorrências'), findsOneWidget);
    expect(find.text('Resumo da Propriedade'), findsOneWidget);
    expect(find.text('Histórico de Visitas'), findsOneWidget);
    expect(find.text('Gerado sob demanda'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, -400));
    await tester.pumpAndSettle();

    expect(find.text('Marketing Cases'), findsOneWidget);
    expect(find.text('Produtor Teste - Fazenda Marketing'), findsOneWidget);

    await _selectSegment(tester, 'Mídia');
    expect(find.text('Fotos da visita'), findsOneWidget);
    expect(
      find.text('Nenhuma foto registrada. Use o botão + no mapa.'),
      findsOneWidget,
    );
    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Foto rápida'), findsWidgets);
    expect(find.text('Inversão vegetal'), findsOneWidget);
    expect(find.text('Órfãs'), findsOneWidget);

    await _selectSegment(tester, 'Gerados');
    await tester.ensureVisible(
      find.byTooltip('Ações do relatório consolidado').first,
    );
    await tester.tap(find.byTooltip('Ações do relatório consolidado').first);
    await tester.pumpAndSettle();
    expect(find.text('Pré-visualizar HTML'), findsOneWidget);
    expect(find.text('Exportar'), findsOneWidget);
  });

  testWidgets('ocorrência com snake_case exibe label legível', (tester) async {
    final occurrenceRepository = FakeOccurrenceRepository()
      ..seed([
        Occurrence(
          id: 'occ-snake',
          type: 'Média',
          description: 'Ervas',
          category: 'ervas_daninhas',
          status: 'draft',
          createdAt: DateTime.utc(2026, 6, 20, 12),
        ),
      ]);

    await _pumpScreen(
      tester,
      relatorioRepository: FakeRelatorioRepository(),
      occurrenceRepository: occurrenceRepository,
    );

    await _selectSegment(tester, 'Ocorrências');
    expect(find.textContaining('Ervas Daninhas'), findsOneWidget);
    expect(find.text('ervas_daninhas'), findsNothing);
  });
}

Future<void> _selectSegment(WidgetTester tester, String label) async {
  await tester.tap(find.text(label).first);
  await tester.pumpAndSettle();
}

Future<void> _pumpScreen(
  WidgetTester tester, {
  required FakeRelatorioRepository relatorioRepository,
  required FakeOccurrenceRepository occurrenceRepository,
  List<MarketingCase>? marketingCases,
}) async {
  final overrides = <Override>[
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
  ];

  await tester.pumpWidget(
    ProviderScope(
      overrides: overrides,
      child: const MaterialApp(home: Scaffold(body: RelatoriosScreen())),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openReportMenu(WidgetTester tester, {required int index}) async {
  await tester.tap(find.byTooltip('Ações do relatório').at(index));
  await tester.pumpAndSettle();
}

Future<void> _openOccurrenceMenu(
  WidgetTester tester, {
  required int index,
}) async {
  await tester.tap(find.byTooltip('Ações da ocorrência').at(index));
  await tester.pumpAndSettle();
}

Future<void> _pumpActionFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 250));
}

class FakeOccurrenceRepository extends OccurrenceRepository {
  final Map<String, Occurrence> _store = {};

  void seed(List<Occurrence> occurrences) {
    for (final occurrence in occurrences) {
      _store[occurrence.id] = occurrence;
    }
  }

  Occurrence? get(String id) => _store[id];

  @override
  Future<List<Occurrence>> getAllOccurrences() async {
    return _store.values
        .where((occurrence) => occurrence.syncStatus != 'deleted')
        .toList();
  }

  @override
  Future<void> updateOccurrence(Occurrence occurrence) async {
    _store[occurrence.id] = occurrence.copyWith(
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 'updated',
    );
  }

  @override
  Future<void> softDeleteOccurrence(String id) async {
    final occurrence = _store[id];
    if (occurrence == null) return;
    _store[id] = occurrence.copyWith(
      updatedAt: DateTime.now().toUtc(),
      syncStatus: 'deleted',
    );
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
}

MarketingCase _marketingCase() {
  return MarketingCase.fromJson({
    'id': 'mkt-1',
    'tipo': 'resultado',
    'visibilidade': 'ouro',
    'lat': -10.1,
    'lng': -48.2,
    'localizacao_texto': 'Palmas, TO',
    'produtor_fazenda': 'Produtor Teste - Fazenda Marketing',
    'produto_utilizado': 'Produto X',
    'produtividade_valor': 72,
    'produtividade_unidade': 'sc/ha',
    'nome_vendedor': 'Vendedor Teste',
    'telefone_vendedor': '(63) 99999-0000',
    'descricao': 'Case de resultado para teste.',
    'quantidade_produzida': 1800,
    'status': 'published',
    'criado_em': '2026-06-04T12:00:00.000Z',
    'atualizado_em': '2026-06-04T12:00:00.000Z',
    'sync_status': 'synced',
  });
}
