import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_report_share_link_publisher.dart';
import 'package:soloforte_app/core/contracts/i_report_share_link_publisher_provider.dart';
import 'package:soloforte_app/core/html_templates/html_report_viewer.dart';

const _reportHtml = '''
<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8"></head>
<body>
<section>
<h2>Áudio de campo</h2>
<audio controls src="data:audio/mp4;base64,AAA"></audio>
<p class="sf-caption">Duração: 30s</p>
</section>
<p>Ervas Daninhas</p>
<img data-sf-photo src="data:image/jpeg;base64,QQ" alt="Foto 1">
</body></html>
''';

class _RecordingPublisher implements IReportShareLinkPublisher {
  int calls = 0;

  @override
  Future<ReportShareLinkPublished> publishHtml({
    required String title,
    required String html,
    String? reportKind,
  }) async {
    calls += 1;
    throw StateError('publishHtml não deve ser chamado');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('prepareReportHtmlForPdf esconde áudio e mantém a duração', () {
    final prepared = prepareReportHtmlForPdf(_reportHtml);

    expect(prepared, contains('id="sf-pdf-print"'));
    expect(prepared, contains('@media print'));
    expect(prepared, contains('audio,'));
    expect(prepared, contains('.sf-share-pdf-stub'));
    expect(prepared, contains('page-break-inside: avoid'));
    expect(prepared, contains('<audio controls'));
    expect(prepared, contains('Duração: 30s'));
    expect(prepared, contains('Ervas Daninhas'));
    expect(prepared, isNot(contains('sfphoto://')));
    expect(_reportHtml, isNot(contains('sf-pdf-print')));
  });

  testWidgets('Enviar PDF grava bytes %PDF e não publica o link', (
    tester,
  ) async {
    final publisher = _RecordingPublisher();
    String? convertedHtml;
    Uint8List? delivered;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          reportShareLinkPublisherProvider.overrideWithValue(publisher),
        ],
        child: MaterialApp(
          home: HtmlReportViewer(
            title: 'Ervas Daninhas',
            htmlContent: _reportHtml,
            fileBaseName: 'ervas_daninhas',
            bodyBuilder: htmlReportViewerPlaceholderBody,
            enableWhatsAppShareLink: true,
            whatsAppPhoneDigits: '63999999999',
            htmlToPdfConverter: (html) async {
              convertedHtml = html;
              return Uint8List.fromList('%PDF-1.4\n'.codeUnits);
            },
            deliverPdfBytes: (bytes) async {
              delivered = bytes;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byTooltip('Enviar PDF'), findsOneWidget);
    expect(find.byTooltip('Enviar link (WhatsApp)'), findsNothing);
    expect(find.byIcon(Icons.picture_as_pdf_outlined), findsOneWidget);

    await tester.tap(find.byTooltip('Enviar PDF'));
    await tester.pump();
    await tester.pump();

    expect(publisher.calls, 0);
    expect(convertedHtml, isNotNull);
    expect(convertedHtml, contains('id="sf-pdf-print"'));
    expect(convertedHtml, contains('Duração: 30s'));
    expect(convertedHtml, contains('Ervas Daninhas'));
    expect(convertedHtml, contains('<audio controls'));
    expect(convertedHtml, isNot(contains('sfphoto://')));

    final viewer = tester.widget<HtmlReportViewer>(
      find.byType(HtmlReportViewer),
    );
    expect(viewer.htmlContent, isNot(contains('sf-pdf-print')));

    expect(delivered, isNotNull);
    expect(String.fromCharCodes(delivered!.take(4)), '%PDF');
  });
}
