import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/html_templates/html_report_viewer.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/occurrence_detail_report_actions.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() => initializeDateFormatting('pt_BR'));

  testWidgets(
    'detalhe no mapa omite status Rascunho/Confirmada e exibe ações de relatório',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final preferencesService = PreferencesService(
        await SharedPreferences.getInstance(),
      );
      final occurrence = Occurrence(
        id: 'occ-report-actions',
        type: 'Média',
        description: 'Praga leve no talhão',
        status: 'draft',
        createdAt: DateTime.utc(2026, 10, 1, 14, 0),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            preferencesServiceProvider.overrideWithValue(preferencesService),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => TextButton(
                onPressed: () => OccurrenceDetailSheet.show(
                  context,
                  occurrence,
                ),
                child: const Text('abrir-detalhe'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir-detalhe'));
      await tester.pumpAndSettle();

      expect(find.text('Status'), findsNothing);
      expect(find.text('Rascunho'), findsNothing);
      expect(find.text('Confirmada'), findsNothing);
      expect(find.text('Abrir relatório'), findsOneWidget);
      expect(find.text('Exportar HTML'), findsOneWidget);
      expect(find.textContaining('Urgência'), findsOneWidget);
    },
  );

  Future<void> pumpDetail(
    WidgetTester tester,
    Occurrence occurrence, {
    Future<void> Function(BuildContext, Occurrence)? onExportLocation,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferencesService = PreferencesService(
      await SharedPreferences.getInstance(),
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferencesService),
        ],
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => OccurrenceDetailSheet.show(
                context,
                occurrence,
                onExportLocation: onExportLocation,
              ),
              child: const Text('abrir-detalhe'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('abrir-detalhe'));
    await tester.pumpAndSettle();
  }

  Occurrence buildOccurrence(String category) => Occurrence(
        id: 'occ-$category',
        type: 'Média',
        description: 'sede',
        status: 'draft',
        category: category,
        lat: -10.18,
        long: -48.88,
        createdAt: DateTime.utc(2026, 9, 21, 16, 19),
      );

  testWidgets(
    'área visitada com callback exibe Exportar localização e oculta urgência',
    (tester) async {
      Occurrence? exported;
      await pumpDetail(
        tester,
        buildOccurrence(kOccurrenceAreaVisitadaCategory),
        onExportLocation: (_, o) async => exported = o,
      );

      expect(find.text('Exportar localização'), findsOneWidget);
      expect(find.textContaining('Urgência'), findsNothing);

      await tester.ensureVisible(find.text('Exportar localização'));
      await tester.tap(find.text('Exportar localização'));
      await tester.pumpAndSettle();
      expect(exported?.id, 'occ-$kOccurrenceAreaVisitadaCategory');
    },
  );

  testWidgets('área visitada sem callback não exibe Exportar localização', (
    tester,
  ) async {
    await pumpDetail(tester, buildOccurrence(kOccurrenceAreaVisitadaCategory));

    expect(find.text('Exportar localização'), findsNothing);
  });

  testWidgets('outras categorias não exibem Exportar localização', (
    tester,
  ) async {
    await pumpDetail(
      tester,
      buildOccurrence('insetos'),
      onExportLocation: (context, occurrence) async {},
    );

    expect(find.text('Exportar localização'), findsNothing);
    expect(find.textContaining('Urgência'), findsOneWidget);
  });

  group('HtmlReportViewer ações com sheet pai', () {
    Future<void> pumpHarness(
      WidgetTester tester,
      FakeOccurrenceRepository repository,
      Occurrence occurrence,
      _PopRecorder popRecorder,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            occurrenceRepositoryProvider.overrideWithValue(repository),
            htmlReportViewerBodyBuilderProvider.overrideWithValue(
              (_) => const SizedBox(key: Key('fake-html-body')),
            ),
          ],
          child: MaterialApp(
            navigatorObservers: [popRecorder],
            home: _OccurrenceReportViewerHarness(occurrence: occurrence),
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

    testWidgets('confirmar não faz pop síncrono do pai com viewer aberto', (
      tester,
    ) async {
      final popRecorder = _PopRecorder();
      final occurrence = Occurrence(
        id: 'occ-confirm-stack',
        type: 'Média',
        description: 'Confirmar stack',
        status: 'draft',
        createdAt: DateTime.utc(2026, 10, 2),
      );
      final repository = FakeOccurrenceRepository()..seed([occurrence]);

      await pumpHarness(tester, repository, occurrence, popRecorder);

      final viewerContext = tester.element(find.byType(HtmlReportViewer));
      final actions = tester
          .widget<HtmlReportViewer>(find.byType(HtmlReportViewer))
          .actions!;
      final done = await actions.onConfirm!(viewerContext);
      expect(done, isTrue);
      expect(repository.get('occ-confirm-stack')?.status, 'confirmed');
      expect(popRecorder.popCount, 0);
      expect(find.byType(HtmlReportViewer), findsOneWidget);
    });

    testWidgets('excluir não faz pop síncrono do pai com viewer aberto', (
      tester,
    ) async {
      final popRecorder = _PopRecorder();
      final occurrence = Occurrence(
        id: 'occ-delete-stack',
        type: 'Média',
        description: 'Excluir stack',
        status: 'draft',
        createdAt: DateTime.utc(2026, 10, 2),
      );
      final repository = FakeOccurrenceRepository()..seed([occurrence]);

      await pumpHarness(tester, repository, occurrence, popRecorder);

      final viewerContext = tester.element(find.byType(HtmlReportViewer));
      final actions = tester
          .widget<HtmlReportViewer>(find.byType(HtmlReportViewer))
          .actions!;
      final done = await actions.onDelete!(viewerContext);
      expect(done, isTrue);
      expect(repository.get('occ-delete-stack')?.syncStatus, 'deleted');
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

class _OccurrenceReportViewerHarness extends ConsumerWidget {
  const _OccurrenceReportViewerHarness({required this.occurrence});

  final Occurrence occurrence;

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
                        const Text('parent-occurrence-sheet'),
                        TextButton(
                          onPressed: () async {
                            final container = ProviderScope.containerOf(
                              sheetContext,
                              listen: false,
                            );
                            await Navigator.of(sheetContext).push(
                              MaterialPageRoute<void>(
                                builder: (_) => HtmlReportViewer(
                                  title: 'Test',
                                  htmlContent: '<html></html>',
                                  bodyBuilder: (_) =>
                                      const SizedBox(key: Key('fake-body')),
                                  actions: occurrenceReportHtmlViewerActions(
                                    container,
                                    occurrence,
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
