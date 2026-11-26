import 'dart:convert';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:soloforte_app/core/html_templates/report_pdf_html_prepare.dart';

const _audioHtml = '''
<!DOCTYPE html>
<html lang="pt-BR"><head><meta charset="utf-8"></head>
<body>
<section>
<audio controls src="data:audio/mp4;base64,QUFBQUFBQUFBQUFB"></audio>
<p class="sf-caption">Duração: 30s</p>
</section>
</body></html>
''';

int _bytesOf(String s) => utf8.encode(s).length;

/// PNG com ruído determinístico (comprime mal => o JPEG fica bem menor).
String _noisyPngDataUri(int width, int height) {
  final random = Random(7);
  final image = img.Image(width: width, height: height);
  for (final pixel in image) {
    pixel
      ..r = random.nextInt(256)
      ..g = random.nextInt(256)
      ..b = random.nextInt(256);
  }
  return 'data:image/png;base64,${base64Encode(img.encodePng(image, level: 1))}';
}

bool _hasLoneSurrogate(String s) {
  final units = s.codeUnits;
  for (var i = 0; i < units.length; i++) {
    final u = units[i];
    if (u >= 0xD800 && u <= 0xDBFF) {
      if (i + 1 >= units.length ||
          units[i + 1] < 0xDC00 ||
          units[i + 1] > 0xDFFF) {
        return true;
      }
      i++;
    } else if (u >= 0xDC00 && u <= 0xDFFF) {
      return true;
    }
  }
  return false;
}

void main() {
  test('remove o base64 do áudio e mantém a legenda de duração', () async {
    final prepared = await prepareReportHtmlForPdf(_audioHtml);

    expect(prepared, isNot(contains('data:audio')));
    expect(prepared, isNot(contains('QUFBQUFB')));
    expect(prepared, contains('Duração: 30s'));
    expect(prepared, contains('audio,'));
    expect(prepared, contains('id="sf-pdf-print"'));
    expect(_audioHtml, contains('data:audio'));
  });

  test('data URI de imagem grande é recomprimida (menor e <= 1024)', () async {
    final uri = _noisyPngDataUri(1300, 900);
    final html =
        '<html><head></head><body>'
        '<img data-sf-photo="0" src="$uri" alt="Foto 1"></body></html>';

    final prepared = await prepareReportHtmlForPdf(html);

    final match = RegExp(r'src="(data:image/[^"]+)"').firstMatch(prepared)!;
    final newUri = match.group(1)!;
    expect(newUri, startsWith('data:image/jpeg;base64,'));
    expect(newUri.length, lessThan(uri.length));
    final decoded = img.decodeImage(UriData.parse(newUri).contentAsBytes())!;
    expect(
      decoded.width > decoded.height ? decoded.width : decoded.height,
      lessThanOrEqualTo(kReportPdfImageMaxDimension),
    );
    expect(decoded.width, 1024);
  });

  test('data URI inválida não quebra e o trecho sai intacto', () async {
    const tag =
        '<img data-sf-photo="0" src="data:image/png;base64,%%%nao-e-base64%%%" alt="Foto 1">';
    const html =
        '<html><head></head><body><p>Antes</p>$tag<p>Depois</p></body></html>';

    final prepared = await prepareReportHtmlForPdf(html);

    expect(prepared, contains(tag));
    expect(prepared, contains('<p>Antes</p>'));
    expect(prepared, contains('<p>Depois</p>'));

    const notImage =
        '<img data-sf-photo="1" src="data:image/png;base64,AAECAwQFBgcICQ==" alt="x">';
    final prepared2 = await prepareReportHtmlForPdf(
      '<html><head></head><body>$notImage</body></html>',
    );
    expect(prepared2, contains(notImage));
  });

  test('HTML acima do limite é cortado e o resultado cabe em bytes', () async {
    final filler = List.filled(
      kReportPdfHtmlMaxBytes ~/ 27 + 1000,
      'lorem ipsum dolor sit amet\n',
    ).join();
    final html = '<html><head></head><body><p>$filler</p></body></html>';
    expect(_bytesOf(html), greaterThan(kReportPdfHtmlMaxBytes));

    final prepared = await prepareReportHtmlForPdf(html);

    expect(_bytesOf(prepared), lessThanOrEqualTo(kReportPdfHtmlMaxBytes));
    expect(prepared, endsWith('</body></html>'));
    expect(prepared, contains('id="sf-pdf-print"'));
  });

  test('fotos do fim saem primeiro quando o teto estoura', () {
    final photo =
        '<img data-sf-photo="0" src="data:image/jpeg;base64,${'A' * 400}">';
    final photo2 = photo.replaceFirst('"0"', '"1"');
    final html = '<html><body><p>texto</p>$photo$photo2</body></html>';
    final limit = _bytesOf(html) - _bytesOf(photo2) + 1;

    final trimmed = trimReportHtmlToMaxBytes(html, limit);

    expect(_bytesOf(trimmed), lessThanOrEqualTo(limit));
    expect(trimmed, contains('data-sf-photo="0"'));
    expect(trimmed, isNot(contains('data-sf-photo="1"')));
    expect(trimmed, endsWith('</body></html>'));
  });

  test('acentos e emoji perto do limite não geram string malformada', () {
    // Varre limites consecutivos para cair em todas as posições de byte
    // possíveis dentro de caracteres de 2, 3 e 4 bytes.
    final html = '<html><body><p>${'aé€😀' * 40}</p></body></html>';
    final start = _bytesOf(html) - 60;
    for (var limit = start; limit < _bytesOf(html); limit++) {
      final trimmed = trimReportHtmlToMaxBytes(html, limit);
      expect(
        _bytesOf(trimmed),
        lessThanOrEqualTo(limit),
        reason: 'limit=$limit',
      );
      expect(_hasLoneSurrogate(trimmed), isFalse, reason: 'limit=$limit');
      expect(trimmed, isNot(contains('\uFFFD')), reason: 'limit=$limit');
      expect(utf8.decode(utf8.encode(trimmed)), trimmed);
    }
  });

  test('corte não deixa tag aberta pela metade', () {
    final html =
        '<html><body><p>${'x' * 200}</p><div class="aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa">fim</div></body></html>';
    final limit = html.indexOf('aaaa') + 5;
    final trimmed = trimReportHtmlToMaxBytes(html, limit);
    expect(_bytesOf(trimmed), lessThanOrEqualTo(limit));
    expect(trimmed, isNot(contains('<div')));
    expect(trimmed, endsWith('</body></html>'));
  });

  test('HTML dentro do limite não é alterado pelo corte', () {
    const html = '<html><body><p>ok</p></body></html>';
    expect(trimReportHtmlToMaxBytes(html, kReportPdfHtmlMaxBytes), html);
  });
}
