import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/html_templates/relatorio_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/report_export_gallery.dart';
import 'package:soloforte_app/core/html_templates/report_photo_links.dart';

void main() {
  test('inject adiciona overlay e script quando há fotos', () {
    const html =
        '<html><body><img data-sf-photo="0" src="x"></body></html>';
    final out = ReportExportGallery.inject(html);

    expect(out, contains('id="sf-export-gallery"'));
    expect(out, contains('sf-export-gallery-close'));
    expect(out, contains('<script>'));
    expect(out, contains('ArrowLeft'));
  });

  test('finalizeDocument inclui galeria exportada', () {
    final out = RelatorioHtmlRenderer.finalizeDocument(
      '<html><body><img data-sf-photo src="x"></body></html>',
    );
    expect(out, contains('sf-export-gallery'));
  });

  test('prepareInAppHtml não marca sf-in-app no HTML exportado original', () {
    final exportHtml = RelatorioHtmlRenderer.finalizeDocument(
      '<html><body class="sf-doc"><img data-sf-photo src="x"></body></html>',
    );
    expect(exportHtml, contains('sf-export-gallery'));
    expect(exportHtml, isNot(contains('class="sf-doc sf-in-app"')));
    expect(exportHtml, isNot(contains('<body class="sf-in-app">')));

    final inApp = ReportPhotoLinks.prepareInAppHtml(exportHtml);
    expect(inApp, contains('class="sf-doc sf-in-app"'));
  });
}
