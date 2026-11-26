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

Archive _cloneArchiveWithPatches(
  Archive source,
  Map<String, String Function(String)> patches,
) {
  final copy = Archive();
  for (final f in source.files) {
    var content = List<int>.from(f.content as List<int>);
    final patch = patches[f.name];
    if (patch != null) {
      content = utf8.encode(patch(utf8.decode(content)));
    }
    copy.addFile(ArchiveFile(f.name, content.length, content));
  }
  return copy;
}

String _issues(PptxPackageAuditResult result) => [
  ...result.orphanRelationships,
  ...result.brokenEmbeds,
  ...result.duplicateShapeIds,
  ...result.partsWithoutContentType,
  ...result.malformedXml,
].join('\n');

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

  test('resolveOoxmlPartPath resolve mídia a partir do slide', () {
    expect(
      resolveOoxmlPartPath('ppt/slides', '../media/image1.jpeg'),
      'ppt/media/image1.jpeg',
    );
  });

  test('auditoria falha com rel órfão (target inexistente)', () async {
    final base = await _archiveFromHtml(_minimalHtml);
    final archive = _cloneArchiveWithPatches(base, {
      'ppt/_rels/presentation.xml.rels': (xml) => xml.replaceFirst(
        '</Relationships>',
        '<Relationship Id="rIdGhost" '
        'Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/slide" '
        'Target="slides/arquivo_inexistente.xml"/>'
        '</Relationships>',
      ),
    });
    final result = auditPptxPackage(archive);
    expect(result.isOk, isFalse);
    final issues = _issues(result);
    expect(issues.toLowerCase(), contains('ausente'));
    expect(result.orphanRelationships, isNotEmpty);
  });

  test('auditoria falha com r:embed sem rId no .rels', () async {
    final base = await _archiveFromHtml(_minimalHtml);
    final archive = _cloneArchiveWithPatches(base, {
      'ppt/slides/slide1.xml': (xml) => xml.replaceFirst(
        '<p:grpSpPr/>',
        '<p:grpSpPr/><a:blip r:embed="rIdGhost"/>',
      ),
    });
    final result = auditPptxPackage(archive);
    expect(result.isOk, isFalse);
    final issues = _issues(result);
    expect(issues, contains('r:embed'));
    expect(issues, contains('Id ausente'));
    expect(result.brokenEmbeds, isNotEmpty);
  });

  test('auditoria falha com id duplicado de p:cNvPr no mesmo slide', () async {
    final base = await _archiveFromHtml(_minimalHtml);
    final archive = _cloneArchiveWithPatches(base, {
      'ppt/slides/slide1.xml': (xml) {
        final firstId = RegExp(r'<p:cNvPr id="(\d+)"').firstMatch(xml)!.group(1)!;
        var seen = 0;
        return xml.replaceAllMapped(RegExp(r'<p:cNvPr id="\d+"'), (m) {
          seen++;
          if (seen == 2) return '<p:cNvPr id="$firstId"';
          return m.group(0)!;
        });
      },
    });
    final slideXml = utf8.decode(
      archive.files
          .firstWhere((f) => f.name == 'ppt/slides/slide1.xml')
          .content as List<int>,
    );
    final ids = RegExp(r'<p:cNvPr id="(\d+)"')
        .allMatches(slideXml)
        .map((m) => m.group(1))
        .toList();
    expect(ids.length, greaterThanOrEqualTo(2));
    expect(ids[0], ids[1]);

    final result = auditPptxPackage(archive);
    expect(result.isOk, isFalse);
    final issues = _issues(result);
    expect(issues, contains('repetido'));
    expect(result.duplicateShapeIds, isNotEmpty);
  });
}
