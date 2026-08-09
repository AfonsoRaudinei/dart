import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/core/contracts/i_marketing_case_reports_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/marketing_case_reports_list_provider.dart';
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
import 'package:soloforte_app/modules/marketing/infra/marketing_case_reports_lookup_adapter.dart';
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
    expect(
      find.textContaining('Nenhuma ocorrência registrada'),
      findsOneWidget,
    );
  });

  testWidgets('exibe UI dedicada: Gerados=Publicações, Consolidados e Ocorrências', (
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
          clientId: 'cli-test-1',
          createdAt: DateTime.utc(2026, 6, 4, 12),
        ),
      ]);

    await _pumpScreen(
      tester,
      relatorioRepository: relatorioRepository,
      occurrenceRepository: occurrenceRepository,
      marketingCases: [_marketingCase()],
    );

    await _selectSegment(tester, 'Ocorrências');
    expect(find.text('Lista de Ocorrências'), findsOneWidget);
    expect(find.text('Exportar lista'), findsOneWidget);

    await _selectSegment(tester, 'Gerados');
    expect(find.text('Publicações'), findsOneWidget);
    expect(find.text('Produtor Teste - Fazenda Marketing'), findsOneWidget);
    expect(find.text('Relatórios Consolidados'), findsNothing);

    await _selectSegment(tester, 'Consolidados');
    expect(find.text('Relatórios Consolidados'), findsOneWidget);
    expect(find.text('Resumo da Propriedade'), findsOneWidget);
    expect(find.text('Histórico de Visitas'), findsOneWidget);
    expect(find.text('Linha do tempo'), findsOneWidget);
    expect(find.text('Gerado sob demanda'), findsWidgets);
    expect(find.text('Lista de Ocorrências'), findsNothing);

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

    await _selectSegment(tester, 'Consolidados');
    await tester.ensureVisible(
      find.byTooltip('Ações do relatório consolidado').first,
    );
    await tester.tap(find.byTooltip('Ações do relatório consolidado').first);
    await tester.pumpAndSettle();
    expect(find.text('Pré-visualizar HTML'), findsOneWidget);
    expect(find.text('Exportar'), findsOneWidget);
  });

  testWidgets(
    'resumo da propriedade fica disponível mesmo sem talhões separados',
    (tester) async {
      final relatorioRepository = FakeRelatorioRepository();
      relatorioRepository.seed([
        makeRelatorio(
          id: 'rel-farm-only',
          farmName: 'Fazenda sem Talhão',
          status: RelatorioStatus.publicado,
        ),
      ]);

      await _pumpScreen(
        tester,
        relatorioRepository: relatorioRepository,
        occurrenceRepository: FakeOccurrenceRepository(),
      );

      await _selectSegment(tester, 'Consolidados');

      expect(find.text('Resumo da Propriedade'), findsOneWidget);
      expect(find.text('1 propriedade(s), 0 talhão(ões)'), findsOneWidget);
      expect(find.text('Disponível'), findsNWidgets(2));
      expect(find.text('Vazio'), findsNothing);
    },
  );

  testWidgets('ocorrência com snake_case exibe label legível', (tester) async {
    final occurrenceRepository = FakeOccurrenceRepository()
      ..seed([
        Occurrence(
          id: 'occ-snake',
          type: 'Média',
          description: 'Ervas',
          category: 'ervas_daninhas',
          status: 'draft',
          clientId: 'cli-test-1',
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

  testWidgets('filtro de marketing cases por tipo na aba Gerados', (
    tester,
  ) async {
    final marketingRepo = FakeMarketingCaseRepository([
      _marketingCase(id: 'mkt-resultado', tipo: 'resultado'),
      _marketingCase(
        id: 'mkt-antes',
        tipo: 'antes_depois',
        produtorFazenda: 'Produtor Antes Depois',
      ),
    ]);

    await _pumpScreen(
      tester,
      relatorioRepository: FakeRelatorioRepository(),
      occurrenceRepository: FakeOccurrenceRepository(),
      marketingRepository: marketingRepo,
    );

    await _selectSegment(tester, 'Gerados');

    expect(find.text('Produtor Teste - Fazenda Marketing'), findsOneWidget);
    expect(find.text('Produtor Antes Depois'), findsOneWidget);

    await tester.tap(find.text('Resultado').first);
    await tester.pumpAndSettle();

    expect(find.text('Produtor Teste - Fazenda Marketing'), findsOneWidget);
    expect(find.text('Produtor Antes Depois'), findsNothing);

    await tester.tap(find.text('Todas').first);
    await tester.pumpAndSettle();

    expect(find.text('Produtor Antes Depois'), findsOneWidget);
  });

  testWidgets('exclusão de marketing case remove card após confirmação', (
    tester,
  ) async {
    final marketingRepo = FakeMarketingCaseRepository([
      _marketingCase(id: 'mkt-delete'),
    ]);

    await _pumpScreen(
      tester,
      relatorioRepository: FakeRelatorioRepository(),
      occurrenceRepository: FakeOccurrenceRepository(),
      marketingRepository: marketingRepo,
    );

    await _selectSegment(tester, 'Gerados');

    expect(find.text('Produtor Teste - Fazenda Marketing'), findsOneWidget);

    await tester.tap(find.byTooltip('Ações da publicação').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir').last);
    await _pumpActionFrame(tester);
    expect(find.text('Excluir publicação?'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Excluir'));
    await tester.pumpAndSettle();

    expect(find.text('Produtor Teste - Fazenda Marketing'), findsNothing);
    expect(marketingRepo.cases.first.deletadoEm, isNotNull);
    expect(marketingRepo.cases.first.ativo, isFalse);
  });

  testWidgets('cancelar exclusão de marketing case mantém o card', (
    tester,
  ) async {
    final marketingRepo = FakeMarketingCaseRepository([
      _marketingCase(id: 'mkt-keep'),
    ]);

    await _pumpScreen(
      tester,
      relatorioRepository: FakeRelatorioRepository(),
      occurrenceRepository: FakeOccurrenceRepository(),
      marketingRepository: marketingRepo,
    );

    await _selectSegment(tester, 'Gerados');

    await tester.tap(find.byTooltip('Ações da publicação').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Excluir').last);
    await _pumpActionFrame(tester);
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('Produtor Teste - Fazenda Marketing'), findsOneWidget);
    expect(marketingRepo.cases.first.deletadoEm, isNull);
  });

  testWidgets('consolidados na aba Consolidados não exibem opção Excluir', (
    tester,
  ) async {
    final relatorioRepository = FakeRelatorioRepository();
    relatorioRepository.seed([
      makeRelatorio(
        id: 'rel-menu',
        farmName: 'Fazenda Menu',
        status: RelatorioStatus.publicado,
      ),
    ]);

    await _pumpScreen(
      tester,
      relatorioRepository: relatorioRepository,
      occurrenceRepository: FakeOccurrenceRepository(),
    );

    await _selectSegment(tester, 'Consolidados');
    await tester.tap(find.byTooltip('Ações do relatório consolidado').first);
    await tester.pumpAndSettle();

    expect(find.text('Pré-visualizar HTML'), findsOneWidget);
    expect(find.text('Exportar'), findsOneWidget);
    expect(find.text('Excluir'), findsNothing);
  });

  testWidgets('consolidados exige seleção de produtor com múltiplos clientes', (
    tester,
  ) async {
    final relatorioRepository = FakeRelatorioRepository();
    relatorioRepository.seed([
      makeRelatorio(
        id: 'rel-a',
        clientId: 'cli-a',
        farmName: 'Fazenda A',
        status: RelatorioStatus.publicado,
      ),
      makeRelatorio(
        id: 'rel-b',
        clientId: 'cli-b',
        farmName: 'Fazenda B',
        status: RelatorioStatus.publicado,
      ),
    ]);

    await _pumpScreen(
      tester,
      relatorioRepository: relatorioRepository,
      occurrenceRepository: FakeOccurrenceRepository(),
    );

    await _selectSegment(tester, 'Consolidados');

    expect(
      find.text(
        'Selecione um produtor para consolidar visitas e exportar relatórios.',
      ),
      findsOneWidget,
    );
    expect(find.text('Vazio'), findsNothing);

    await tester.tap(find.text('Produtor A · 1').first);
    await tester.pumpAndSettle();

    expect(find.text('Resumo da Propriedade'), findsOneWidget);
    expect(find.text('1 visita(s)'), findsOneWidget);
    expect(find.text('Disponível'), findsNWidgets(2));
    expect(find.text('Fazenda B'), findsNothing);
  });

  testWidgets('ocorrências exige seleção de produtor com múltiplos clientes', (
    tester,
  ) async {
    final occurrenceRepository = FakeOccurrenceRepository()
      ..seed([
        Occurrence(
          id: 'occ-a',
          type: 'Baixa',
          description: 'Produtor A',
          category: 'daninhas',
          status: 'confirmed',
          clientId: 'cli-a',
          createdAt: DateTime.utc(2026, 6, 4, 12),
        ),
        Occurrence(
          id: 'occ-b',
          type: 'Alta',
          description: 'Produtor B',
          category: 'pragas',
          status: 'confirmed',
          clientId: 'cli-b',
          createdAt: DateTime.utc(2026, 6, 5, 12),
        ),
      ]);

    await _pumpScreen(
      tester,
      relatorioRepository: FakeRelatorioRepository(),
      occurrenceRepository: occurrenceRepository,
    );

    await _selectSegment(tester, 'Ocorrências');

    expect(find.textContaining('Selecione um produtor'), findsNWidgets(2));
    expect(find.text('Produtor A · 1'), findsOneWidget);
    expect(find.text('Produtor B · 1'), findsOneWidget);
    expect(find.textContaining('Pragas'), findsNothing);

    await tester.tap(find.text('Produtor A · 1').first);
    await tester.pumpAndSettle();

    expect(find.text('1 ocorrência(s)'), findsOneWidget);
    expect(find.textContaining('Daninhas'), findsOneWidget);
    expect(find.textContaining('Pragas'), findsNothing);
    expect(find.text('Produtor B · 1'), findsOneWidget);
  });

  testWidgets('Gerados oculta marketing case em rascunho', (tester) async {
    await _pumpScreen(
      tester,
      relatorioRepository: FakeRelatorioRepository(),
      occurrenceRepository: FakeOccurrenceRepository(),
      marketingCases: [
        _marketingCase(id: 'mkt-published'),
        _marketingCase(
          id: 'mkt-draft',
          produtorFazenda: 'Rascunho oculto',
          status: 'draft',
        ),
      ],
    );

    await _selectSegment(tester, 'Gerados');

    expect(find.text('Produtor Teste - Fazenda Marketing'), findsOneWidget);
    expect(find.text('Rascunho oculto'), findsNothing);
  });

  testWidgets('Gerados oculta marketing case pending_sync', (tester) async {
    await _pumpScreen(
      tester,
      relatorioRepository: FakeRelatorioRepository(),
      occurrenceRepository: FakeOccurrenceRepository(),
      marketingCases: [
        _marketingCase(id: 'mkt-published'),
        _marketingCase(
          id: 'mkt-pending',
          produtorFazenda: 'Pendente sync oculto',
          status: 'pending_sync',
        ),
      ],
    );

    await _selectSegment(tester, 'Gerados');

    expect(find.text('Produtor Teste - Fazenda Marketing'), findsOneWidget);
    expect(find.text('Pendente sync oculto'), findsNothing);
  });

  testWidgets('Gerados oculta marketing case arquivado', (tester) async {
    await _pumpScreen(
      tester,
      relatorioRepository: FakeRelatorioRepository(),
      occurrenceRepository: FakeOccurrenceRepository(),
      marketingCases: [
        _marketingCase(id: 'mkt-published'),
        _marketingCase(
          id: 'mkt-archived',
          produtorFazenda: 'Arquivado oculto',
          status: 'archived',
        ),
      ],
    );

    await _selectSegment(tester, 'Gerados');

    expect(find.text('Produtor Teste - Fazenda Marketing'), findsOneWidget);
    expect(find.text('Arquivado oculto'), findsNothing);
  });

  testWidgets('publicação em Gerados oferece Compartilhar pack', (
    tester,
  ) async {
    await _pumpScreen(
      tester,
      relatorioRepository: FakeRelatorioRepository(),
      occurrenceRepository: FakeOccurrenceRepository(),
      marketingCases: [_marketingCase()],
    );

    await _selectSegment(tester, 'Gerados');
    await tester.tap(find.byTooltip('Ações da publicação').first);
    await tester.pumpAndSettle();

    expect(find.text('Compartilhar pack'), findsOneWidget);
    expect(find.text('Editar'), findsOneWidget);
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
  FakeMarketingCaseRepository? marketingRepository,
  List<MarketingCase>? marketingCases,
}) async {
  final overrides = <Override>[
    currentUserRoleProvider.overrideWithValue(UserRole.consultor),
    clientLookupProvider.overrideWithValue(_RelatoriosTestClientLookup()),
    relatorioRepositoryProvider.overrideWithValue(relatorioRepository),
    publish_repo.relatorioRepositoryProvider.overrideWithValue(
      relatorioRepository,
    ),
    occurrenceRepositoryProvider.overrideWithValue(occurrenceRepository),
    marketingCaseRepositoryProvider.overrideWithValue(
      marketingRepository ??
          FakeMarketingCaseRepository(marketingCases ?? const []),
    ),
    marketingCaseReportsLookupProvider.overrideWith(
      (ref) => MarketingCaseReportsLookupAdapter(ref),
    ),
    marketingCaseReportsListProvider.overrideWith(
      (ref) => ref.watch(marketingCaseReportsListImplProvider),
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

  FakeMarketingCaseRepository(this.cases);

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
  Future<void> updateCase(MarketingCase marketingCase) async {
    final index = cases.indexWhere((item) => item.id == marketingCase.id);
    if (index >= 0) {
      cases[index] = marketingCase;
    }
  }

  @override
  Future<MarketingCase> softDelete(String id) async {
    final index = cases.indexWhere((item) => item.id == id);
    if (index < 0) {
      throw StateError('Case não encontrado: $id');
    }
    final existing = cases[index];
    final deleted = MarketingCase.fromJson({
      ...existing.toJson(),
      'deletado_em': DateTime.utc(2026, 8, 8, 12).toIso8601String(),
      'ativo': false,
      'sync_status': 'pending_sync',
    });
    cases[index] = deleted;
    return deleted;
  }
}

class _RelatoriosTestClientLookup implements IClientLookup {
  static const _clients = <ClientSummary>[
    ClientSummary(id: 'cli-test-1', name: 'Produtor Teste', active: true),
    ClientSummary(id: 'cli-a', name: 'Produtor A', active: true),
    ClientSummary(id: 'cli-b', name: 'Produtor B', active: true),
  ];

  @override
  Future<ClientSummary?> findById(String id) async {
    for (final client in _clients) {
      if (client.id == id) return client;
    }
    return null;
  }

  @override
  Future<List<ClientSummary>> listAtivos() async => _clients;
}

MarketingCase _marketingCase({
  String id = 'mkt-1',
  String tipo = 'resultado',
  String produtorFazenda = 'Produtor Teste - Fazenda Marketing',
  String status = 'published',
}) {
  return MarketingCase.fromJson({
    'id': id,
    'tipo': tipo,
    'visibilidade': 'ouro',
    'lat': -10.1,
    'lng': -48.2,
    'localizacao_texto': 'Palmas, TO',
    'produtor_fazenda': produtorFazenda,
    'produto_utilizado': 'Produto X',
    'produtividade_valor': 72,
    'produtividade_unidade': 'sc/ha',
    'nome_vendedor': 'Vendedor Teste',
    'telefone_vendedor': '(63) 99999-0000',
    'descricao': 'Case de resultado para teste.',
    'quantidade_produzida': 1800,
    'status': status,
    'criado_em': '2026-06-04T12:00:00.000Z',
    'atualizado_em': '2026-06-04T12:00:00.000Z',
    'sync_status': 'synced',
  });
}
