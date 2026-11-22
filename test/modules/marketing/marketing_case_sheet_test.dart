import 'dart:convert';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_marketing_case_reports_lookup.dart';
import 'package:soloforte_app/core/contracts/i_marketing_case_reports_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_access_reader_provider.dart';
import 'package:soloforte_app/core/contracts/marketing_case_report_snapshot.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/marketing/data/repositories/i_marketing_case_repository.dart';
import 'package:soloforte_app/modules/marketing/data/services/marketing_sync_service.dart';
import 'package:soloforte_app/modules/marketing/presentation/providers/marketing_providers.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/marketing_case_sheet.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

void main() {
  group('MarketingCaseSheet', () {
    testWidgets('sheet Resultado: expand false + hero ROI líquido', (
      tester,
    ) async {
      final marketingCase = _resultadoCase();

      await tester.pumpWidget(
        _wrapSheet(marketingCase: marketingCase, themeId: null),
      );
      await tester.pumpAndSettle();

      final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet),
      );
      expect(sheet.expand, isFalse);

      expect(find.text('ROI líquido'), findsOneWidget);
      expect(find.text('R\$ 980,00/ha'), findsOneWidget);
      expect(find.text('9,3 sc/ha'), findsOneWidget);
      expect(find.text('Testemunha (sem produto)'), findsOneWidget);
      expect(find.text('Com coach'), findsOneWidget);
      expect(find.text('Ganho'), findsOneWidget);
      expect(find.text('ROI/ha'), findsOneWidget);
    });

    testWidgets('Antes/Depois exibe a conclusão técnica após os blocos', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapSheet(
          marketingCase: _antesDepoisCase(
            conclusaoTecnica: 'Produto elevou o vigor da raiz.',
          ),
          themeId: null,
        ),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable);
      await tester.scrollUntilVisible(
        find.text('CONCLUSÃO TÉCNICA'),
        120,
        scrollable: scrollable,
      );

      expect(find.text('CONCLUSÃO TÉCNICA'), findsOneWidget);
      expect(find.text('Produto elevou o vigor da raiz.'), findsOneWidget);
      expect(find.text('Comparação 1'), findsOneWidget);
    });

    testWidgets('Antes/Depois sem conclusão técnica não mostra o card', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrapSheet(marketingCase: _antesDepoisCase(), themeId: null),
      );
      await tester.pumpAndSettle();

      expect(find.text('CONCLUSÃO TÉCNICA'), findsNothing);
    });

    testWidgets(
      'Avaliação mostra as fotos dos blocos e a conclusão uma única vez',
      (tester) async {
        await tester.pumpWidget(
          _wrapSheet(
            marketingCase: _antesDepoisCase(
              tipo: CaseTipo.avaliacao,
              conclusaoTecnica: 'Conclusão da avaliação.',
            ),
            themeId: null,
          ),
        );
        await tester.pumpAndSettle();

        final scrollable = find.byType(Scrollable);
        await tester.scrollUntilVisible(
          find.text('CONCLUSÃO TÉCNICA'),
          120,
          scrollable: scrollable,
        );

        expect(find.byType(CachedNetworkImage), findsNWidgets(3));
        expect(find.text('CONCLUSÃO TÉCNICA'), findsOneWidget);
        expect(find.text('Conclusão da avaliação.'), findsOneWidget);
      },
    );

    testWidgets('perfil azul: ações de relatório e hero sem verde escuro', (
      tester,
    ) async {
      final marketingCase = _resultadoCase();

      await tester.pumpWidget(
        _wrapSheet(marketingCase: marketingCase, themeId: 'blue'),
      );
      await tester.pumpAndSettle();

      final scrollable = find.byType(Scrollable);
      await tester.scrollUntilVisible(
        find.text('Abrir relatório'),
        120,
        scrollable: scrollable,
      );
      await tester.scrollUntilVisible(
        find.text('Exportar HTML'),
        120,
        scrollable: scrollable,
      );

      expect(find.text('Abrir relatório'), findsOneWidget);
      expect(find.text('Exportar HTML'), findsOneWidget);

      expect(
        find.byWidgetPredicate(
          (w) =>
              w is DecoratedBox &&
              w.decoration is BoxDecoration &&
              (w.decoration as BoxDecoration).color == const Color(0xFF123D2A),
        ),
        findsNothing,
      );

      final roiValue = tester.widget<Text>(find.text('R\$ 980,00/ha'));
      expect(roiValue.style?.color, SoloForteSheetSkinIos.iconStroke);
      expect(roiValue.style?.color, isNot(PremiumTokens.brandGreen));
    });
  });
}

Widget _wrapSheet({
  required MarketingCase marketingCase,
  required String? themeId,
}) {
  final extensions = themeId == null
      ? const <ThemeExtension<dynamic>>[]
      : <ThemeExtension<dynamic>>[SoloForteThemeExtension(themeId: themeId)];

  return ProviderScope(
    overrides: [
      marketingCaseReportsLookupProvider.overrideWithValue(
        _FakeMarketingLookup(),
      ),
      marketingCaseRepositoryProvider.overrideWithValue(_NoopMarketingRepo()),
      marketingCasesProvider.overrideWith((ref) {
        final repo = ref.watch(marketingCaseRepositoryProvider);
        final sync = ref.watch(marketingSyncServiceProvider);
        return _EmptyCasesNotifier(repo, sync);
      }),
      authorizedClientIdsProvider.overrideWith((ref) async => const <String>{}),
      currentUserRoleProvider.overrideWith((ref) => UserRole.consultor),
    ],
    child: MaterialApp(
      theme: ThemeData(extensions: extensions),
      home: Scaffold(body: MarketingCaseSheet(marketingCase: marketingCase)),
    ),
  );
}

MarketingCase _antesDepoisCase({
  CaseTipo tipo = CaseTipo.antesDepois,
  String? conclusaoTecnica,
}) {
  final now = DateTime.utc(2026, 8, 7);
  return MarketingCase(
    id: 'case-sheet-ad',
    tipo: tipo,
    visibilidade: PlanoMarketing.prata,
    lat: -10,
    lng: -48,
    localizacaoTexto: 'Palmas Tocantins',
    produtorFazenda: 'Miguel',
    produtoUtilizado: 'coach',
    dataCase: now,
    nomeTalhao: tipo == CaseTipo.avaliacao ? 'Talhão 1' : null,
    avaliacoesJson: jsonEncode([
      {
        'id': 'av-1',
        'titulo': 'Comparação 1',
        'nome_lado_a': 'Antes',
        'nome_lado_b': 'Depois',
        'nome_lado_c': 'Concorrente',
        'foto_lado_a_path': 'https://example.com/a.jpg',
        'foto_lado_b_path': 'https://example.com/b.jpg',
        'foto_lado_c_path': 'https://example.com/c.jpg',
      },
    ]),
    conclusaoTecnica: conclusaoTecnica,
    criadoEm: now,
    atualizadoEm: now,
  );
}

MarketingCase _resultadoCase() {
  final now = DateTime.utc(2026, 8, 7);
  return MarketingCase(
    id: 'case-sheet-1',
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.prata,
    lat: -10,
    lng: -48,
    localizacaoTexto: 'Palmas Tocantins',
    produtorFazenda: 'Miguel',
    produtoUtilizado: 'coach',
    dataCase: now,
    prodSemProduto: 55,
    prodComProduto: 65,
    unidadeProdutividade: 'sc/ha',
    custoProdutoPorHa: 70,
    valorGrao: 105,
    criadoEm: now,
    atualizadoEm: now,
  );
}

class _FakeMarketingLookup implements IMarketingCaseReportsLookup {
  @override
  Future<MarketingCaseReportExportBundle> buildExportBundle(
    String caseId, {
    required String? fallbackConsultantName,
    required String fallbackConsultantRole,
    String? reportBrandName,
    String? reportLogoPath,
    String? consultantName,
    String? consultantRole,
    bool asFragment = false,
  }) async {
    return const MarketingCaseReportExportBundle(
      title: 'Marketing test',
      fileBaseName: 'marketing_test',
      html: '<html></html>',
      json: {},
      csv: '',
    );
  }

  @override
  Future<void> deleteCase(String id) async {}

  @override
  Future<bool> publishDraftCase(BuildContext context, String caseId) async =>
      false;

  @override
  Future<void> showEditSheet(BuildContext context, String caseId) async {}
}

class _EmptyCasesNotifier extends MarketingCasesNotifier {
  _EmptyCasesNotifier(
    IMarketingCaseRepository repository,
    MarketingSyncService syncService,
  ) : super(repository, syncService, null) {
    state = const AsyncData([]);
  }

  @override
  Future<void> load({bool forceSync = false}) async {}
}

class _NoopMarketingRepo implements IMarketingCaseRepository {
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
