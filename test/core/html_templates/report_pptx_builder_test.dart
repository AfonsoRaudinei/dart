import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:soloforte_app/core/html_templates/report_pptx_builder.dart';
import 'package:xml/xml.dart';

String _pngDataUri(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(30, 140, 60));
  return 'data:image/png;base64,${base64Encode(img.encodePng(image))}';
}

String _htmlWithBody(String body, {String photos = ''}) =>
    '''
<html><body>
<h1 class="sf-title">Relatório</h1>
<main>
<h2 class="sf-section-title"><span class="sf-section-num"></span>Descrição</h2>
$body
$photos
</main>
</body></html>
''';

Future<Archive> _build(String html) async {
  final bytes = await const ReportPptxBuilder().build(
    reportTitle: 'Relatório',
    html: html,
  );
  return ZipDecoder().decodeBytes(bytes);
}

String _entry(Archive archive, String name) => utf8.decode(
  archive.files.firstWhere((f) => f.name == name).content as List<int>,
);

List<String> _slideXmls(Archive archive) {
  final names =
      archive.files
          .map((f) => f.name)
          .where((n) => RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(n))
          .toList()
        ..sort((a, b) {
          int n(String s) =>
              int.parse(RegExp(r'(\d+)\.xml').firstMatch(s)![1]!);
          return n(a).compareTo(n(b));
        });
  return names.map((n) => _entry(archive, n)).toList();
}

/// Texto do corpo (shape "Text 3") de um slide, parágrafos concatenados.
String _bodyText(String slideXml) {
  final doc = XmlDocument.parse(slideXml);
  for (final sp in doc.findAllElements('p:sp')) {
    final name = sp.findAllElements('p:cNvPr').first.getAttribute('name');
    if (name == 'Text 3') {
      return sp.findAllElements('a:t').map((t) => t.innerText).join();
    }
  }
  return '';
}

String _titleText(String slideXml) {
  final doc = XmlDocument.parse(slideXml);
  for (final sp in doc.findAllElements('p:sp')) {
    final name = sp.findAllElements('p:cNvPr').first.getAttribute('name');
    if (name == 'Text 2') {
      return sp.findAllElements('a:t').map((t) => t.innerText).join();
    }
  }
  return '';
}

const _sampleHtml = '''
<!DOCTYPE html>
<html><body>
<header class="sf-letterhead">
<h1 class="sf-title">Ervas daninhas</h1>
<p class="sf-subtitle">Cliente · Fazenda · Talhão</p>
</header>
<main>
<section class="sf-section">
<h2 class="sf-section-title"><span class="sf-section-num"></span>Descrição</h2>
<p>Infestação moderada na borda do talhão.</p>
</section>
<section class="sf-section">
<h2 class="sf-section-title"><span class="sf-section-num"></span>Registro fotográfico</h2>
<img data-sf-photo="0" src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==" alt="Foto 1">
</section>
</main>
</body></html>
''';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', (message) async {
          final key = utf8.decode(message!.buffer.asUint8List());
          if (key == 'assets/images/soloforte_logo.png') {
            return const StandardMessageCodec().encodeMessage(
              Uint8List.fromList([
                0x89,
                0x50,
                0x4E,
                0x47,
                0x0D,
                0x0A,
                0x1A,
                0x0A,
              ]),
            );
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMessageHandler('flutter/assets', null);
  });

  test('build retorna pptx com slides e mídia', () async {
    final bytes = await const ReportPptxBuilder().build(
      reportTitle: 'Ervas daninhas',
      html: _sampleHtml,
    );

    expect(bytes.length, greaterThan(500));

    final archive = ZipDecoder().decodeBytes(bytes);
    final slide1 = archive.files.where(
      (f) => f.name == 'ppt/slides/slide1.xml',
    );
    expect(slide1, isNotEmpty);

    final media = archive.files.where((f) => f.name.startsWith('ppt/media/'));
    expect(media.length, greaterThanOrEqualTo(1));
    expect(archive.files.any((f) => f.name == 'ppt/presentation.xml'), isTrue);
  });

  test('data URI malformado não derruba build() e a foto é ignorada', () async {
    const html = '''
<html><body>
<h1 class="sf-title">Relatório</h1>
<main>
<h2 class="sf-section-title"><span class="sf-section-num"></span>Descrição</h2>
<p>Texto.</p>
<img data-sf-photo="0" src="data:image/png;base64,%%%não-é-base64%%%" alt="Foto 1">
</main>
</body></html>
''';
    final bytes = await const ReportPptxBuilder().build(
      reportTitle: 'Relatório',
      html: html,
    );

    final archive = ZipDecoder().decodeBytes(bytes);
    expect(archive.files.any((f) => f.name == 'ppt/slides/slide1.xml'), isTrue);
    // Só o logo (png) vira mídia; nenhuma foto jpeg.
    final media = archive.files
        .where((f) => f.name.startsWith('ppt/media/'))
        .map((f) => f.name)
        .toList();
    expect(media.where((n) => n.endsWith('.jpeg')), isEmpty);
  });

  test('entidades HTML são decodificadas antes do escape XML', () async {
    const html = '''
<html><body>
<h1 class="sf-title">Ervas &amp; <em>daninhas</em></h1>
<p class="sf-subtitle">Cliente&nbsp;A</p>
<main>
<h2 class="sf-section-title"><span class="sf-section-num"></span>Pragas &amp; doenças</h2>
<p>Soja&nbsp;e milho &lt;ok&gt; &quot;x&quot; it&#39;s &#x27;y&#x27;.</p>
</main>
</body></html>
''';
    final bytes = await const ReportPptxBuilder().build(
      reportTitle: 'Ervas & daninhas',
      html: html,
    );
    final archive = ZipDecoder().decodeBytes(bytes);
    String slideXml(int n) => utf8.decode(
      archive.files
              .firstWhere((f) => f.name == 'ppt/slides/slide$n.xml')
              .content
          as List<int>,
    );

    final cover = slideXml(1);
    expect(cover, contains('<a:t>Ervas &amp; daninhas</a:t>'));
    expect(cover, contains('Cliente A'));
    expect(cover, isNot(contains('&amp;amp;')));
    expect(cover, isNot(contains('<em>')));

    final section = slideXml(2);
    expect(section, contains('Pragas &amp; doenças'));
    expect(section, contains('Soja e milho &lt;ok&gt;'));
    expect(section, contains('it\'s'));
    expect(section, isNot(contains('&amp;amp;')));
    expect(section, isNot(contains('&amp;nbsp;')));
    expect(section, isNot(contains('&amp;lt;')));
  });

  test(
    'bytes que não são imagem não viram mídia e o pptx segue válido',
    () async {
      final junk = base64Encode(List<int>.generate(64, (i) => i));
      final archive = await _build(
        _htmlWithBody(
          '<p>Texto.</p>',
          photos:
              '<img data-sf-photo="0" src="data:image/jpeg;base64,$junk" alt="Foto 1">',
        ),
      );

      final media = archive.files
          .where((f) => f.name.startsWith('ppt/media/'))
          .map((f) => f.name)
          .toList();
      expect(media.where((n) => n.endsWith('.jpeg')), isEmpty);
      for (final xml in _slideXmls(archive)) {
        XmlDocument.parse(xml);
      }
      expect(
        archive.files.any((f) => f.name == 'ppt/presentation.xml'),
        isTrue,
      );
    },
  );

  test('imagem pequena não é ampliada', () async {
    final archive = await _build(
      _htmlWithBody(
        '<p>Texto.</p>',
        photos:
            '<img data-sf-photo="0" src="${_pngDataUri(100, 50)}" alt="Foto 1">',
      ),
    );
    final jpeg = archive.files.firstWhere(
      (f) => f.name.startsWith('ppt/media/') && f.name.endsWith('.jpeg'),
    );
    final decoded = img.decodeJpg(
      Uint8List.fromList(jpeg.content as List<int>),
    );
    expect(decoded, isNotNull);
    expect(decoded!.width, 100);
    expect(decoded.height, 50);
  });

  test('imagem grande é reduzida e mantém a proporção no slide', () async {
    final archive = await _build(
      _htmlWithBody(
        '<p>Texto.</p>',
        photos:
            '<img data-sf-photo="0" src="${_pngDataUri(2000, 1000)}" alt="Foto 1">',
      ),
    );
    final jpeg = archive.files.firstWhere(
      (f) => f.name.startsWith('ppt/media/') && f.name.endsWith('.jpeg'),
    );
    final decoded = img.decodeJpg(
      Uint8List.fromList(jpeg.content as List<int>),
    );
    expect(decoded!.width, 1024);
    expect(decoded.height, 512);

    final photoSlide = _slideXmls(
      archive,
    ).firstWhere((x) => x.contains('<p:pic>') && x.contains('Foto 1'));
    final ext = RegExp(
      r'<p:pic>[\s\S]*?<a:ext cx="(\d+)" cy="(\d+)"/>',
    ).firstMatch(photoSlide)!;
    final cx = int.parse(ext[1]!);
    final cy = int.parse(ext[2]!);
    expect(cx / cy, closeTo(2.0, 0.01));
    expect(cx / cy, isNot(closeTo(1.5, 0.1)));
  });

  test('texto longo é dividido em vários slides dentro do limite', () async {
    final paragraphs = List.generate(
      12,
      (i) => '<p>${List.filled(70, 'palavra$i').join(' ')}</p>',
    ).join('\n');
    final archive = await _build(_htmlWithBody(paragraphs));
    final slides = _slideXmls(archive);

    final textSlides = slides
        .where((x) => _titleText(x).startsWith('Descrição'))
        .toList();
    expect(textSlides.length, greaterThan(1));
    for (final slide in textSlides) {
      expect(
        _bodyText(slide).length,
        lessThanOrEqualTo(kPptxSlideBodyMaxChars),
      );
      expect(slide, contains('<a:normAutofit/>'));
    }
    expect(_titleText(textSlides.first), 'Descrição');
    expect(_titleText(textSlides[1]), 'Descrição (2/${textSlides.length})');
    expect(
      _titleText(textSlides.last),
      endsWith('(${textSlides.length}/${textSlides.length})'),
    );
  });

  test('parágrafo único maior que o limite é quebrado por palavra', () async {
    final single = '<p>${List.filled(1500, 'abc').join(' ')}</p>';
    final archive = await _build(_htmlWithBody(single));
    final textSlides = _slideXmls(
      archive,
    ).where((x) => _titleText(x).startsWith('Descrição')).toList();
    expect(textSlides.length, greaterThan(1));
    var words = 0;
    for (final slide in textSlides) {
      final body = _bodyText(slide);
      expect(body.length, lessThanOrEqualTo(kPptxSlideBodyMaxChars));
      words += RegExp('abc').allMatches(body).length;
    }
    expect(words, 1500);
  });

  test('subtítulo longo da capa gera vários slides com sufixo (2/n)', () async {
    final subtitle = List.filled(3000, 'x').join(' ');
    final html = '''
<html><body>
<h1 class="sf-title">Relatório</h1>
<p class="sf-subtitle">$subtitle</p>
<main>
<h2 class="sf-section-title"><span class="sf-section-num"></span>Descrição</h2>
<p>Corpo.</p>
</main>
</body></html>
''';
    final archive = await _build(html);
    final slides = _slideXmls(archive);

    final coverSlides = slides
        .where((x) {
          final title = _titleText(x);
          return title == 'Relatório' ||
              RegExp(r'^Relatório \(\d+/\d+\)$').hasMatch(title);
        })
        .toList();
    expect(coverSlides.length, greaterThan(1));
    expect(_titleText(coverSlides.first), 'Relatório');
    final total = coverSlides.length;
    expect(
      _titleText(coverSlides[1]),
      'Relatório (2/$total)',
    );
    for (final slide in coverSlides) {
      expect(_bodyText(slide).length, lessThanOrEqualTo(kPptxSlideBodyMaxChars));
    }
  });

  test(
    'fotos após o teto não viram jpeg extra e o aviso bate com o HTML',
    () async {
      const extra = 3;
      final uri = _pngDataUri(1, 1);
      final photos = List.generate(
        kPptxMaxPhotos + extra,
        (i) => '<img data-sf-photo="$i" src="$uri" alt="Foto ${i + 1}">',
      ).join('\n');
      final html = _htmlWithBody('<p>Texto.</p>', photos: photos);
      final figureCount = RegExp(r'<figure', caseSensitive: false)
          .allMatches(html)
          .length;

      final archive = await _build(html);
      final jpegs = archive.files.where(
        (f) => f.name.startsWith('ppt/media/') && f.name.endsWith('.jpeg'),
      );
      expect(jpegs.length, kPptxMaxPhotos);
      expect(figureCount, 0);

      final slides = _slideXmls(archive);
      final notice = '+$extra fotos não incluídas (limite do arquivo)';
      expect(slides.where((x) => _bodyText(x).contains(notice)).length, 1);
    },
  );

  test(
    'acima do teto de fotos só entram kPptxMaxPhotos e há aviso factual',
    () async {
      const extra = 5;
      final uri = _pngDataUri(1, 1);
      final photos = List.generate(
        kPptxMaxPhotos + extra,
        (i) => '<img data-sf-photo="$i" src="$uri" alt="Foto ${i + 1}">',
      ).join('\n');
      final archive = await _build(
        _htmlWithBody('<p>Texto.</p>', photos: photos),
      );

      final jpegs = archive.files.where(
        (f) => f.name.startsWith('ppt/media/') && f.name.endsWith('.jpeg'),
      );
      expect(jpegs.length, kPptxMaxPhotos);

      final slides = _slideXmls(archive);
      final notice = '+$extra fotos não incluídas (limite do arquivo)';
      final withNotice = slides.where((x) => _bodyText(x).contains(notice));
      expect(withNotice.length, 1);
      // Último slide de texto: o aviso fica antes dos slides de foto.
      final noticeIndex = slides.indexOf(withNotice.single);
      final firstPhoto = slides.indexWhere((x) => x.contains('<p:pic>'));
      expect(noticeIndex, lessThan(firstPhoto));
      for (final xml in slides) {
        XmlDocument.parse(xml);
      }
    },
  );

  test('caracteres de controle ilegais em XML são removidos', () async {
    const html = '''
<html><body>
<h1 class="sf-title">Título\u0001 ok</h1>
<p class="sf-subtitle">Contexto\u000B aqui\uFFFE</p>
<main>
<h2 class="sf-section-title"><span class="sf-section-num"></span>Seção\u0008 A</h2>
<p>Texto\u0001 com\u000B controle\u001F e \u0009tab.</p>
</main>
</body></html>
''';
    final archive = await _build(html);
    final slides = _slideXmls(archive);
    final illegal = RegExp(
      r'[\u0000-\u0008\u000B\u000C\u000E-\u001F\uFFFE\uFFFF]',
    );
    for (final xml in slides) {
      expect(illegal.hasMatch(xml), isFalse);
      XmlDocument.parse(xml);
    }
    expect(slides.first, contains('Título ok'));
    expect(_bodyText(slides[1]), contains('Texto com'));
  });
}
