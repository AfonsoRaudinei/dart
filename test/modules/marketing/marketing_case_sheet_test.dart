import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_marketing_case_reports_lookup.dart';
import 'package:soloforte_app/core/contracts/i_marketing_case_reports_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/marketing_case_report_snapshot.dart';
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
        _wrapSheet(
          marketingCase: marketingCase,
          themeId: null,
        ),
      );
      await tester.pumpAndSettle();

      final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet),
      );
      expect(sheet.expand, isFalse);

      expect(find.text('ROI líquido'), findsOneWidget);
      expect(find.text('R\$ 980,00/ha'), findsOneWidget);
      expect(find.text('9,3 sc/ha'), findsOneWidget);
      expect(find.text('Testemunha'), findsOneWidget);
      expect(find.text('Com produto'), findsOneWidget);
      expect(find.text('Ganho'), findsOneWidget);
      expect(find.text('ROI/ha'), findsOneWidget);
    });

    testWidgets('perfil azul: ações de relatório e hero sem verde escuro', (
      tester,
    ) async {
      final marketingCase = _resultadoCase();

      await tester.pumpWidget(
        _wrapSheet(
          marketingCase: marketingCase,
          themeId: 'blue',
        ),
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
      : <ThemeExtension<dynamic>>[
          SoloForteThemeExtension(themeId: themeId),
        ];

  return ProviderScope(
    overrides: [
      marketingCaseReportsLookupProvider.overrideWithValue(
        _FakeMarketingLookup(),
      ),
    ],
    child: MaterialApp(
      theme: ThemeData(extensions: extensions),
      home: Scaffold(
        body: MarketingCaseSheet(marketingCase: marketingCase),
      ),
    ),
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
