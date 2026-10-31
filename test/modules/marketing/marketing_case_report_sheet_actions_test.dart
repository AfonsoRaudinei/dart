import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_marketing_case_reports_lookup.dart';
import 'package:soloforte_app/core/contracts/i_marketing_case_reports_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/marketing_case_report_snapshot.dart';
import 'package:soloforte_app/core/html_templates/html_report_viewer.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/marketing_case_status.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/plano_marketing.dart';
import 'package:soloforte_app/modules/marketing/presentation/marketing_case_report_sheet_actions.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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

  group('HtmlReportViewer ações com sheet pai', () {
    Future<void> pumpHarness(
      WidgetTester tester,
      _HarnessMarketingLookup lookup,
      MarketingCase marketingCase,
      _PopRecorder popRecorder,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            marketingCaseReportsLookupProvider.overrideWithValue(lookup),
            htmlReportViewerBodyBuilderProvider.overrideWithValue(
              (_) => const SizedBox(key: Key('fake-html-body')),
            ),
          ],
          child: MaterialApp(
            navigatorObservers: [popRecorder],
            home: _MarketingReportViewerHarness(marketingCase: marketingCase),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('open-parent-sheet'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('open-viewer'));
      await tester.pumpAndSettle();
      expect(find.byType(HtmlReportViewer), findsOneWidget);
    }

    testWidgets('excluir não faz pop síncrono do pai com viewer aberto', (
      tester,
    ) async {
      final popRecorder = _PopRecorder();
      final lookup = _HarnessMarketingLookup();
      final marketingCase = _sampleCase();

      await pumpHarness(tester, lookup, marketingCase, popRecorder);

      final viewerContext = tester.element(find.byType(HtmlReportViewer));
      final actions = tester
          .widget<HtmlReportViewer>(find.byType(HtmlReportViewer))
          .actions!;
      final done = await actions.onDelete!(viewerContext);
      expect(done, isTrue);
      expect(lookup.deletedCaseIds, contains('case-actions-1'));
      expect(popRecorder.popCount, 0);
      expect(find.byType(HtmlReportViewer), findsOneWidget);
    });

    testWidgets('publicar não faz pop síncrono do pai com viewer aberto', (
      tester,
    ) async {
      final popRecorder = _PopRecorder();
      final lookup = _HarnessMarketingLookup(publishSucceeds: true);
      final marketingCase = _sampleCase(status: MarketingCaseStatus.draft);

      await pumpHarness(tester, lookup, marketingCase, popRecorder);

      final viewerContext = tester.element(find.byType(HtmlReportViewer));
      final actions = tester
          .widget<HtmlReportViewer>(find.byType(HtmlReportViewer))
          .actions!;
      final published = await actions.onPublish!(viewerContext);
      expect(published, isTrue);
      expect(lookup.publishCalls, contains('case-actions-1'));
      expect(popRecorder.popCount, 0);
      expect(find.byType(HtmlReportViewer), findsOneWidget);
    });
  });
}

class _PopRecorder extends NavigatorObserver {
  int popCount = 0;

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    popCount++;
    super.didPop(route, previousRoute);
  }
}

class _MarketingReportViewerHarness extends ConsumerWidget {
  const _MarketingReportViewerHarness({required this.marketingCase});

  final MarketingCase marketingCase;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (sheetContext) {
                  return Scaffold(
                    body: Column(
                      children: [
                        const Text('parent-marketing-sheet'),
                        TextButton(
                          onPressed: () async {
                            final container = ProviderScope.containerOf(
                              sheetContext,
                              listen: false,
                            );
                            await Navigator.of(sheetContext).push(
                              MaterialPageRoute<void>(
                                builder: (_) => HtmlReportViewer(
                                  title: 'Marketing test',
                                  htmlContent: '<html></html>',
                                  bodyBuilder: (_) =>
                                      const SizedBox(key: Key('fake-body')),
                                  actions: marketingCaseReportViewerActions(
                                    container,
                                    marketingCase,
                                    closeParentSheetOnAction: true,
                                    parentSheetContext: sheetContext,
                                  ),
                                ),
                              ),
                            );
                          },
                          child: const Text('open-viewer'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
          child: const Text('open-parent-sheet'),
        ),
      ),
    );
  }
}

MarketingCase _sampleCase({MarketingCaseStatus status = MarketingCaseStatus.published}) {
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
    status: status,
    criadoEm: now,
    atualizadoEm: now,
  );
}

class _HarnessMarketingLookup implements IMarketingCaseReportsLookup {
  _HarnessMarketingLookup({this.publishSucceeds = false});

  final bool publishSucceeds;
  final List<String> deletedCaseIds = [];
  final List<String> publishCalls = [];

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
  Future<void> deleteCase(String id) async {
    deletedCaseIds.add(id);
  }

  @override
  Future<bool> publishDraftCase(BuildContext context, String caseId) async {
    publishCalls.add(caseId);
    return publishSucceeds;
  }

  @override
  Future<void> showEditSheet(BuildContext context, String caseId) async {}
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
