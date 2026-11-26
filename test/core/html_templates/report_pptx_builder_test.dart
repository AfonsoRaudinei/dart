import 'dart:convert';
import 'dart:typed_data';

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
}