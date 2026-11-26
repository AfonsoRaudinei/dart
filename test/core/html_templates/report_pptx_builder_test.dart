import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/html_templates/report_pptx_builder.dart';

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
    expect(
      archive.files.any((f) => f.name == 'ppt/presentation.xml'),
      isTrue,
    );
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
    expect(
      archive.files.any((f) => f.name == 'ppt/slides/slide1.xml'),
      isTrue,
    );
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
              .content as List<int>,
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
}