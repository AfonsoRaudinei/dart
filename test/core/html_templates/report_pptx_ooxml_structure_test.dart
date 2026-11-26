import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/html_templates/report_pptx_builder.dart';
import 'package:xml/xml.dart';

import 'pptx_package_integrity.dart';

const _minimalHtml = '''
<html><body>
<h1 class="sf-title">Relatório</h1>
<main>
<h2 class="sf-section-title"><span class="sf-section-num"></span>Descrição</h2>
<p>Texto mínimo para estrutura OOXML.</p>
</main>
</body></html>
''';

Future<Uint8List> _buildMinimalPptx() async {
  return const ReportPptxBuilder().build(
    reportTitle: 'Relatório',
    html: _minimalHtml,
  );
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

  test(
    'tamanho descomprimido no cabeçalho local bate com o conteúdo',
    () async {
      final zipBytes = await _buildMinimalPptx();
      final locals = parseZipLocalHeaders(zipBytes);
      expect(locals, isNotEmpty);
      for (final entry in locals) {
        expect(
          entry.uncompressedSizeInHeader,
          isNot(0),
          reason: 'entrada ${entry.name}: cabeçalho com uncompressedSize=0',
        );
        if (entry.compressionMethod == 0) {
          expect(
            entry.uncompressedSizeInHeader,
            entry.data.length,
            reason: 'stored ${entry.name}',
          );
          expect(
            entry.compressedSizeInHeader,
            entry.data.length,
            reason: 'stored ${entry.name}',
          );
        }
      }

      final archive = ZipDecoder().decodeBytes(zipBytes);
      for (final file in archive.files) {
        final len = (file.content as List<int>).length;
        expect(file.size, len, reason: 'ArchiveFile.size para ${file.name}');
      }
    },
  );

  test('primeiro local header no binário é [Content_Types].xml', () async {
    final zipBytes = await _buildMinimalPptx();
    final locals = parseZipLocalHeaders(zipBytes);
    expect(locals.first.name, '[Content_Types].xml');
  });

  test('[Content_Types].xml tem Overrides de docProps e partes ppt', () async {
    final zipBytes = await _buildMinimalPptx();
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final xml = utf8.decode(
      archive.files.firstWhere((f) => f.name == '[Content_Types].xml').content
          as List<int>,
    );
    expect(xml, contains('PartName="/docProps/core.xml"'));
    expect(xml, contains('core-properties+xml'));
    expect(xml, contains('PartName="/docProps/app.xml"'));
    expect(xml, contains('extended-properties+xml'));
    expect(xml, contains('PartName="/ppt/presProps.xml"'));
    expect(xml, contains('presProps+xml'));
    expect(xml, contains('PartName="/ppt/viewProps.xml"'));
    expect(xml, contains('viewProps+xml'));
    expect(xml, contains('PartName="/ppt/tableStyles.xml"'));
    expect(xml, contains('tableStyles+xml'));
  });

  test('theme1.xml contém effectStyleLst e bgFillStyleLst', () async {
    final zipBytes = await _buildMinimalPptx();
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final theme = utf8.decode(
      archive.files.firstWhere((f) => f.name == 'ppt/theme/theme1.xml').content
          as List<int>,
    );
    expect(theme, contains('<a:effectStyleLst>'));
    expect(theme, contains('<a:bgFillStyleLst>'));
    final doc = XmlDocument.parse(theme);
    expect(
      doc.findAllElements('a:effectStyle').length,
      greaterThanOrEqualTo(3),
    );
    expect(doc.findAllElements('a:bgFillStyleLst').length, 1);
  });

  test('presProps, viewProps e tableStyles existem no pacote', () async {
    final zipBytes = await _buildMinimalPptx();
    final archive = ZipDecoder().decodeBytes(zipBytes);
    expect(archive.files.any((f) => f.name == 'ppt/presProps.xml'), isTrue);
    expect(archive.files.any((f) => f.name == 'ppt/viewProps.xml'), isTrue);
    expect(archive.files.any((f) => f.name == 'ppt/tableStyles.xml'), isTrue);

    final presProps = utf8.decode(
      archive.files.firstWhere((f) => f.name == 'ppt/presProps.xml').content
          as List<int>,
    );
    expect(presProps, isNot(contains('needle=')));
    expect(presProps, contains('<p:showPr loop="0"'));
    XmlDocument.parse(presProps);
  });

  test('slideMaster1.xml contém txStyles', () async {
    final zipBytes = await _buildMinimalPptx();
    final archive = ZipDecoder().decodeBytes(zipBytes);
    final master = utf8.decode(
      archive.files
              .firstWhere((f) => f.name == 'ppt/slideMasters/slideMaster1.xml')
              .content
          as List<int>,
    );
    expect(master, contains('<p:txStyles>'));
    expect(master, contains('<p:titleStyle>'));
    expect(master, contains('<p:bodyStyle>'));
    expect(master, contains('<p:otherStyle>'));
    XmlDocument.parse(master);
  });

  test(
    'presentation.xml.rels inclui presProps, viewProps e tableStyles',
    () async {
      final zipBytes = await _buildMinimalPptx();
      final archive = ZipDecoder().decodeBytes(zipBytes);
      final rels = utf8.decode(
        archive.files
                .firstWhere((f) => f.name == 'ppt/_rels/presentation.xml.rels')
                .content
            as List<int>,
      );
      final doc = XmlDocument.parse(rels);
      final types = doc
          .findAllElements('Relationship')
          .map((e) => e.getAttribute('Type'))
          .whereType<String>()
          .toList();
      expect(types.any((t) => t.endsWith('/presProps')), isTrue, reason: rels);
      expect(types.any((t) => t.endsWith('/viewProps')), isTrue);
      expect(types.any((t) => t.endsWith('/tableStyles')), isTrue);

      // rId1=master, rId2..=slides; extras após os slides.
      final ids =
          doc
              .findAllElements('Relationship')
              .map(
                (e) => int.parse(
                  RegExp(
                    r'rId(\d+)',
                  ).firstMatch(e.getAttribute('Id')!)!.group(1)!,
                ),
              )
              .toList()
            ..sort();
      expect(ids.first, 1);
      expect(
        ids.contains(ids.last - 2),
        isTrue,
      ); // presProps/viewProps/tableStyles no fim
    },
  );

  test('todos os .xml e .rels são XML bem-formado', () async {
    final zipBytes = await _buildMinimalPptx();
    final archive = ZipDecoder().decodeBytes(zipBytes);
    for (final file in archive.files) {
      if (!file.name.endsWith('.xml') && !file.name.endsWith('.rels')) {
        continue;
      }
      final text = utf8.decode(file.content as List<int>);
      expect(() => XmlDocument.parse(text), returnsNormally, reason: file.name);
    }
  });
}
