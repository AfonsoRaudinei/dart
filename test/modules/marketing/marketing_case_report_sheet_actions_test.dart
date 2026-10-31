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
import 'package:soloforte_app/modules/marketing/presentation/marketing_case_report_sheet_actions.dart';

void main() {
  testWidgets('MarketingCaseReportActionsRow smoke', (tester) async {
    final marketingCase = _sampleCase();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          marketingCaseReportsLookupProvider.overrideWithValue(
            _FakeMarketingLookup(),
          ),
        ],
        child: MaterialApp(
          theme: ThemeData(
            extensions: const [SoloForteThemeExtension(themeId: 'blue')],
          ),
          home: Scaffold(
            body: MarketingCaseReportActionsRow(
              marketingCase: marketingCase,
              isIos: true,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Abrir relatório'), findsOneWidget);
    expect(find.text('Exportar HTML'), findsOneWidget);
  });
}

MarketingCase _sampleCase() {
  final now = DateTime.utc(2026, 8, 7);
  return MarketingCase(
    id: 'case-actions-1',
    tipo: CaseTipo.resultado,
    visibilidade: PlanoMarketing.prata,
    lat: -10,
    lng: -48,
    localizacaoTexto: 'Palmas',
    produtorFazenda: 'Produtor',
    produtoUtilizado: 'Produto',
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
      html: '<html><body>ok</body></html>',
      json: {'tipo': 'marketing_case'},
      csv: 'id\n1',
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
