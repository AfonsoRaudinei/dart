import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/html_templates/html_report_viewer.dart';
import 'package:soloforte_app/core/html_templates/report_export_service.dart';

const _reportHtml =
    '<html><body><p>Relatório de teste</p></body></html>';

class _CapturingExportService extends ReportExportService {
  final Completer<void> exportStarted = Completer<void>();
  ReportExportFormat? capturedFormat;
  ReportExportPayload? capturedPayload;
  Rect? capturedOrigin;

  @override
  Future<ReportExportResult> export(
    ReportExportFormat format,
    ReportExportPayload payload, {
    Rect? sharePositionOrigin,
  }) async {
    capturedFormat = format;
    capturedPayload = payload;
    capturedOrigin = sharePositionOrigin;
    if (!exportStarted.isCompleted) {
      exportStarted.complete();
    }
    return ReportExportResult(format: format, path: '/tmp/test.${format.name}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('menu Exportar dispara pptx com payload do viewer', (
    tester,
  ) async {
    final exportService = _CapturingExportService();

    await tester.pumpWidget(
      MaterialApp(
        home: HtmlReportViewer(
          title: 'Campo',
          htmlContent: _reportHtml,
          fileBaseName: 'campo',
          bodyBuilder: htmlReportViewerPlaceholderBody,
          enableWhatsAppShareLink: true,
          exportService: exportService,
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Exportar'), findsOneWidget);
    expect(find.byTooltip('Enviar PDF'), findsNothing);

    await tester.tap(find.byTooltip('Exportar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar apresentação'));
    await tester.pump();

    await exportService.exportStarted.future;
    await tester.pump();

    expect(exportService.capturedFormat, ReportExportFormat.pptx);
    expect(exportService.capturedPayload?.title, 'Campo');
    expect(exportService.capturedPayload?.html, _reportHtml);
    expect(exportService.capturedPayload?.fileBaseName, 'campo');
    expect(exportService.capturedOrigin, isNotNull);
    expect(exportService.capturedOrigin!.width, greaterThan(0));
  });

  testWidgets('exportação pptx exibe indicador de ocupado na AppBar', (
    tester,
  ) async {
    final exportService = _SlowExportService();

    await tester.pumpWidget(
      MaterialApp(
        home: HtmlReportViewer(
          title: 'Campo',
          htmlContent: _reportHtml,
          bodyBuilder: htmlReportViewerPlaceholderBody,
          enableWhatsAppShareLink: true,
          exportService: exportService,
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byTooltip('Exportar'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Enviar apresentação'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    exportService.release.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });
}

class _SlowExportService extends ReportExportService {
  final Completer<void> release = Completer<void>();

  @override
  Future<ReportExportResult> export(
    ReportExportFormat format,
    ReportExportPayload payload, {
    Rect? sharePositionOrigin,
  }) async {
    await release.future;
    return ReportExportResult(format: format, path: '/tmp/slow.${format.name}');
  }
}