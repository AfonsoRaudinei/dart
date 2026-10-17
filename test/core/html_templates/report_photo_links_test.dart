import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/html_templates/relatorio_html_renderer.dart';
import 'package:soloforte_app/core/html_templates/report_photo_links.dart';

const _png1x1 =
    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

String _reportHtml() => RelatorioHtmlRenderer.indexReportPhotos('''
<html><head></head><body>
<header class="sf-letterhead"><span class="sf-doc-type">Relatório</span></header>
<figure class="sf-figure sf-figure-hero">
  <input type="checkbox" id="sf-foto-hero" class="sf-lb-toggle" hidden>
  <label for="sf-foto-hero" class="photo-hero">
    <img data-sf-photo src="$_png1x1" alt="Foto 1 · Insetos" loading="lazy">
  </label>
</figure>
<div class="sf-item">
  <img data-sf-photo class="sf-thumb" src="https://cdn.test/a.jpg?x=1&amp;y=2" alt="Foto 2" loading="lazy">
</div>
<p class="sf-prose">&lt;img data-sf-photo src="x"&gt;</p>
<footer class="sf-footer">
  <img class="sf-brand-logo" src="$_png1x1" alt="" width="22" height="22" aria-hidden="true">
</footer>
</body></html>
''');

void main() {
  group('RelatorioHtmlRenderer.indexReportPhotos', () {
    test('numera fotos na ordem do documento e ignora logo/texto', () {
      final html = _reportHtml();

      expect(html, contains('<img data-sf-photo="0" src="data:image/png'));
      expect(html, contains('<img data-sf-photo="1" class="sf-thumb"'));
      expect(html, isNot(contains('data-sf-photo="2"')));
      expect(html, contains('&lt;img data-sf-photo src="x"&gt;'));
    });
  });

  group('ReportPhotoLinks.prepareInAppHtml', () {
    test('envolve cada foto numerada em link sfphoto://N', () {
      final html = ReportPhotoLinks.prepareInAppHtml(_reportHtml());

      expect(
        html,
        contains(
          '<a class="sf-photo-link" href="sfphoto://0"><img data-sf-photo="0"',
        ),
      );
      expect(
        html,
        contains(
          '<a class="sf-photo-link" href="sfphoto://1"><img data-sf-photo="1"',
        ),
      );
      expect(RegExp('sfphoto://').allMatches(html).length, 2);
    });

    test('remove o checkbox do lightbox CSS só na cópia do app', () {
      final original = _reportHtml();
      final inApp = ReportPhotoLinks.prepareInAppHtml(original);

      expect(original, contains('class="sf-lb-toggle"'));
      expect(inApp, isNot(contains('class="sf-lb-toggle"')));
      expect(inApp, contains('<label for="sf-foto-hero" class="photo-hero">'));
    });

    test('não toca no logo do rodapé nem em HTML sem fotos', () {
      final inApp = ReportPhotoLinks.prepareInAppHtml(_reportHtml());
      expect(
        inApp,
        contains('<footer class="sf-footer">\n  <img class="sf-brand-logo"'),
      );

      const semFotos = '<p>Sem fotos</p>';
      expect(ReportPhotoLinks.prepareInAppHtml(semFotos), semFotos);
    });
  });

  group('ReportPhotoLinks.extractPhotos', () {
    test('extrai src/alt de img[data-sf-photo] ordenado pelo índice', () {
      final photos = ReportPhotoLinks.extractPhotos(_reportHtml());

      expect(photos.map((photo) => photo.index), [0, 1]);
      expect(photos[0].src, _png1x1);
      expect(photos[0].caption, 'Foto 1 · Insetos');
      expect(photos[0].isDataUri, isTrue);
      expect(photos[1].src, 'https://cdn.test/a.jpg?x=1&y=2');
      expect(photos[1].isNetwork, isTrue);
      expect(photos[1].caption, 'Foto 2');
    });

    test('ordena por índice mesmo fora da ordem do documento', () {
      final photos = ReportPhotoLinks.extractPhotos(
        '<img data-sf-photo="1" src="https://cdn.test/b.jpg">'
        '<img data-sf-photo="0" src="https://cdn.test/a.jpg" alt="">',
      );

      expect(photos.map((photo) => photo.src), [
        'https://cdn.test/a.jpg',
        'https://cdn.test/b.jpg',
      ]);
      expect(photos.first.caption, isNull);
    });

    test('decodifica data URI em bytes; URL remota não decodifica', () {
      final photos = ReportPhotoLinks.extractPhotos(_reportHtml());

      final bytes = photos[0].decodeBytes();
      expect(bytes, isNotNull);
      expect(bytes!.sublist(1, 4), 'PNG'.codeUnits);
      expect(photos[1].decodeBytes(), isNull);
    });

    test('foto extraída sobrevive ao HTML transformado para o app', () {
      final inApp = ReportPhotoLinks.prepareInAppHtml(_reportHtml());
      expect(ReportPhotoLinks.extractPhotos(inApp).length, 2);
    });
  });

  group('ReportPhotoLinks.indexFromUrl', () {
    test('aceita índice no host ou no path', () {
      expect(ReportPhotoLinks.linkFor(3), 'sfphoto://3');
      expect(ReportPhotoLinks.indexFromUrl('sfphoto://0'), 0);
      expect(ReportPhotoLinks.indexFromUrl('sfphoto://12/'), 12);
      expect(ReportPhotoLinks.indexFromUrl('sfphoto:///7'), 7);
      expect(ReportPhotoLinks.indexFromUrl('about:blank'), isNull);
      expect(ReportPhotoLinks.indexFromUrl('https://soloforte.app'), isNull);
      expect(ReportPhotoLinks.indexFromUrl('sfphoto://abc'), isNull);
    });
  });

  group('ReportPhotoLinks.decideNavigation', () {
    void expectOpens(String url, int index) {
      final decision = ReportPhotoLinks.decideNavigation(url);
      expect(decision.action, ReportNavigationAction.openPhoto, reason: url);
      expect(decision.photoIndex, index, reason: url);
    }

    void expectAction(String url, ReportNavigationAction action) {
      final decision = ReportPhotoLinks.decideNavigation(url);
      expect(decision.action, action, reason: url);
      expect(decision.photoIndex, isNull, reason: url);
    }

    test('sfphoto com índice abre o visualizador', () {
      expectOpens('sfphoto://0', 0);
      expectOpens('sfphoto://3/', 3);
      expectOpens('sfphoto:///5', 5);
      expectOpens('sfphoto:///5/', 5);
    });

    test('about: e data: são permitidos (documento inicial)', () {
      for (final url in [
        'about:blank',
        'about:srcdoc',
        'about:blank#top',
        'data:text/html;charset=utf-8,%3Chtml%3E',
        'data:text/html;base64,PGh0bWw+',
      ]) {
        expectAction(url, ReportNavigationAction.allow);
      }
    });

    test('qualquer outra URL é bloqueada (WebView sem voltar)', () {
      for (final url in [
        'https://soloforte.app',
        'http://example.com/x',
        'file:///tmp/relatorio.html',
        'mailto:contato@soloforte.app',
        'tel:+5563999990000',
        'javascript:alert(1)',
        '',
      ]) {
        expectAction(url, ReportNavigationAction.prevent);
      }
    });

    test('sfphoto malformado é bloqueado', () {
      for (final url in [
        'sfphoto://',
        'sfphoto:///',
        'sfphoto://abc',
        'sfphoto://-1',
        'sfphoto://1.5',
        'sfphoto://1/2',
        'sfphoto:///1/2',
        'sfphoto://1?x=2',
        'sfphoto://1#foto',
        'sfphoto:1x',
      ]) {
        expectAction(url, ReportNavigationAction.prevent);
      }
    });
  });
}
