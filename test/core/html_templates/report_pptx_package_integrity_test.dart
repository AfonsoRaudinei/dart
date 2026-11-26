import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:soloforte_app/core/html_templates/report_pptx_builder.dart';

import 'pptx_package_integrity.dart';

const _minimalHtml = '''
<html><body>
<h1 class="sf-title">Relatório</h1>
<main>
<h2 class="sf-section-title"><span class="sf-section-num"></span>Descrição</h2>
<p>Texto mínimo para integridade OOXML.</p>
</main>
</body></html>
''';

String _pngDataUri(int width, int height) {
  final image = img.Image(width: width, height: height);
  img.fill(image, color: img.ColorRgb8(30, 140, 60));
  return 'data:image/png;base64,${base64Encode(img.encodePng(image))}';
}

String _richHtml() {
  final longBody = List.filled(2000, 'x').join();
  final photo1 = _pngDataUri(40, 30);
  final photo2 = _pngDataUri(60, 45);
  return '''
<html><body>
<h1 class="sf-title">Relatório extenso</h1>
<main>
<h2 class="sf-section-title"><span class="sf-section-num"></span>Descrição</h2>
<p>$longBody</p>
<h2 class="sf-section-title"><span class="sf-section-num"></span>Registro fotográfico</h2>
<img data-sf-photo="0" src="$photo1" alt="Foto A">
<img data-sf-photo="1" src="$photo2" alt="Foto B">
</main>
</body></html>
''';
}

Future<Archive> _archiveFromHtml(String html) async {
  final bytes = await const ReportPptxBuilder().build(
    reportTitle: 'Relatório',
    html: html,
  );
  return ZipDecoder().decodeBytes(bytes);
}

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

  test('pacote mínimo passa auditoria de integridade', () async {
    final archive = await _archiveFromHtml(_minimalHtml);
    assertPptxPackageIntegrity(archive);
  });

  test('pacote rico (texto longo + 2 fotos) passa auditoria', () async {
    final archive = await _archiveFromHtml(_richHtml());
    assertPptxPackageIntegrity(archive);

    final media = archive.files
        .where((f) => f.name.startsWith('ppt/media/'))
        .length;
    expect(media, greaterThanOrEqualTo(2));
    final slides = archive.files
        .where((f) => RegExp(r'^ppt/slides/slide\d+\.xml$').hasMatch(f.name))
        .length;
    expect(slides, greaterThan(1));
  });

  test('auditPptxPackage expõe resultado agregado', () async {
    final archive = await _archiveFromHtml(_minimalHtml);
    final result = auditPptxPackage(archive);
    expect(result.isOk, isTrue);
    expect(result.summary, isEmpty);
  });
}