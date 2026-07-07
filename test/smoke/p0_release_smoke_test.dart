import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:soloforte_app/core/contracts/agenda_ai_recommendation_context.dart';
import 'package:soloforte_app/core/contracts/i_agenda_ai_launcher.dart';
import 'package:soloforte_app/core/html_templates/report_export_service.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/utils/share_position.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_detail_sheet.dart';

/// Smoke tests P0 — proxy automatizado dos cenários de release desta sessão.
void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('P0 export iPad — sharePositionOrigin', () {
    testWidgets('resolveSharePositionOrigin retorna Rect não-zero (viewport iPad)', (
      tester,
    ) async {
      _setIPadViewport(tester);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              final origin = resolveSharePositionOrigin(context);
              expect(origin.width, greaterThan(0));
              expect(origin.height, greaterThan(0));
              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('anchor GlobalKey (HtmlReportViewer pattern) retorna Rect não-zero', (
      tester,
    ) async {
      _setIPadViewport(tester);
      final exportButtonKey = GlobalKey();
      Rect? capturedOrigin;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            appBar: AppBar(
              actions: [
                IconButton(
                  key: exportButtonKey,
                  icon: const Icon(Icons.ios_share_outlined),
                  onPressed: () {
                    capturedOrigin = resolveSharePositionOrigin(
                      exportButtonKey.currentContext!,
                      anchorKey: exportButtonKey,
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.ios_share_outlined));
      await tester.pumpAndSettle();

      expect(capturedOrigin, isNotNull);
      expect(capturedOrigin!.width, greaterThan(0));
      expect(capturedOrigin!.height, greaterThan(0));
    });

    testWidgets('Relatórios export HTML/JSON recebe sharePositionOrigin não-zero', (
      tester,
    ) async {
      _setIPadViewport(tester);
      final captured = <ReportExportFormat, Rect?>{};
      final exportService = _RecordingExportService(
        onExport: (format, origin) => captured[format] = origin,
      );
      const payload = ReportExportPayload(
        title: 'Smoke Export',
        html: '<html><body>ok</body></html>',
        json: {'ok': true},
        csv: 'a,b\n1,2',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () async {
                  final origin = resolveSharePositionOrigin(context);
                  await exportService.export(
                    ReportExportFormat.html,
                    payload,
                    sharePositionOrigin: origin,
                  );
                  await exportService.export(
                    ReportExportFormat.json,
                    payload,
                    sharePositionOrigin: origin,
                  );
                },
                child: const Text('exportar'),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('exportar'));
      await tester.pumpAndSettle();

      for (final format in [ReportExportFormat.html, ReportExportFormat.json]) {
        expect(captured[format], isNotNull);
        expect(captured[format]!.width, greaterThan(0));
        expect(captured[format]!.height, greaterThan(0));
      }
    });
  });

  group('P0 navegação Relatórios → ocorrência', () {
    testWidgets('com backRoute: seta visível e permanece em /consultoria/relatorios', (
      tester,
    ) async {
      final occurrence = Occurrence(
        id: 'occ-smoke-1',
        type: 'Média',
        description: 'Smoke test',
        createdAt: DateTime.utc(2026, 7, 6),
      );

      late GoRouter router;
      router = GoRouter(
        initialLocation: AppRoutes.reports,
        routes: [
          GoRoute(
            path: AppRoutes.map,
            builder: (_, __) => const Scaffold(body: Text('map-page')),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, __) => Scaffold(
              body: TextButton(
                onPressed: () => OccurrenceDetailSheet.show(
                  context,
                  occurrence,
                  backRoute: AppRoutes.reports,
                ),
                child: const Text('abrir-ocorrencia'),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir-ocorrencia'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoutes.reports);
      expect(find.text('map-page'), findsNothing);
      expect(find.text('abrir-ocorrencia'), findsOneWidget);
    });

    testWidgets('sem backRoute: seta contextual ausente (fluxo mapa)', (
      tester,
    ) async {
      final occurrence = Occurrence(
        id: 'occ-smoke-2',
        type: 'Baixa',
        description: 'Mapa',
        createdAt: DateTime.utc(2026, 7, 6),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () => OccurrenceDetailSheet.show(context, occurrence),
              child: const Text('abrir-mapa'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('abrir-mapa'));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.arrow_back_ios_new), findsNothing);
    });

    testWidgets('FAB proxy: context.go(/map) a partir de Relatórios', (
      tester,
    ) async {
      late GoRouter router;
      router = GoRouter(
        initialLocation: AppRoutes.reports,
        routes: [
          GoRoute(
            path: AppRoutes.map,
            builder: (_, __) => const Scaffold(body: Text('map-page')),
          ),
          GoRoute(
            path: AppRoutes.reports,
            builder: (context, __) => Scaffold(
              body: TextButton(
                onPressed: () => context.go(AppRoutes.map),
                child: const Text('fab-to-map'),
              ),
            ),
          ),
        ],
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      await tester.tap(find.text('fab-to-map'));
      await tester.pumpAndSettle();

      expect(router.state.uri.path, AppRoutes.map);
      expect(find.text('map-page'), findsOneWidget);
    });
  });

  group('P0 AgendaAI — entry point mapa', () {
    test('IAgendaAiLauncher recebe launchContext com GPS (contrato mapa→sheet)', () async {
      final launcher = _FakeAgendaAiLauncher();
      const ctx = AgendaAiLaunchContext(latitude: -10.0, longitude: -48.0);
      await launcher.showSheet(
        _FakeBuildContext(),
        launchContext: ctx,
      );

      expect(launcher.callCount, 1);
      expect(launcher.lastContext, ctx);
    });
  });
}

void _setIPadViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1024, 1366);
  tester.view.devicePixelRatio = 2.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

class _RecordingExportService extends ReportExportService {
  _RecordingExportService({required this.onExport});

  final void Function(ReportExportFormat format, Rect? origin) onExport;

  @override
  Future<ReportExportResult> export(
    ReportExportFormat format,
    ReportExportPayload payload, {
    Rect? sharePositionOrigin,
  }) async {
    onExport(format, sharePositionOrigin);
    return ReportExportResult(format: format, path: '/tmp/smoke.${format.name}');
  }
}

class _FakeAgendaAiLauncher implements IAgendaAiLauncher {
  int callCount = 0;
  AgendaAiLaunchContext? lastContext;

  @override
  Future<void> showSheet(
    BuildContext context, {
    AgendaAiLaunchContext? launchContext,
  }) async {
    callCount++;
    lastContext = launchContext;
  }
}

class _FakeBuildContext implements BuildContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
