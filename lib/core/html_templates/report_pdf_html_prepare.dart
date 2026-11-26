import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Teto da cópia HTML enviada ao WebKit de impressão (~8 MB, em **bytes**).
@visibleForTesting
const int kReportPdfHtmlMaxBytes = 8 * 1024 * 1024;

@visibleForTesting
const int kReportPdfImageMaxDimension = 1024;

@visibleForTesting
const int kReportPdfJpegQuality = 72;

/// Data URIs menores que isto são recomprimidas inline (sem custo de isolate).
const int _inlineRecompressMaxChars = 64 * 1024;

const _printStyle = '''
<style id="sf-pdf-print">
audio,
#sf-share-pdf-toolbar,
.sf-share-pdf-stub { display: none !important; }
@media print {
  audio,
  #sf-share-pdf-toolbar,
  .sf-share-pdf-stub { display: none !important; }
  .sf-figure,
  img[data-sf-photo] {
    break-inside: avoid;
    page-break-inside: avoid;
  }
}
</style>
''';

/// Cópia leve do HTML para [Printing.convertHtml].
///
/// - remove o áudio embutido (base64) e esconde o player; a legenda
///   (duração, ficha) permanece;
/// - recomprime imagens `data:image/*` (máx. [kReportPdfImageMaxDimension]);
/// - esconde o rodapé de `window.print()` e evita cortar foto entre páginas;
/// - se passar de [kReportPdfHtmlMaxBytes] bytes, descarta fotos do fim e,
///   em último caso, corta o documento.
///
/// O HTML exibido no app não muda.
Future<String> prepareReportHtmlForPdf(String html) async {
  var prepared = _stripAudioFromHtml(html);
  prepared = await _recompressDataUriImages(
    prepared,
    maxDimension: kReportPdfImageMaxDimension,
    jpegQuality: kReportPdfJpegQuality,
  );
  prepared = _injectPrintStyle(prepared);
  prepared = trimReportHtmlToMaxBytes(prepared, kReportPdfHtmlMaxBytes);
  return prepared;
}

String _injectPrintStyle(String html) {
  if (html.contains('id="sf-pdf-print"')) return html;
  if (html.contains('</head>')) {
    return html.replaceFirst('</head>', '$_printStyle</head>');
  }
  return '$_printStyle$html';
}

/// Remove só o payload base64 do áudio (o peso); o elemento fica, escondido
/// pelo CSS de impressão, para não mexer na estrutura/legenda do documento.
String _stripAudioFromHtml(String html) {
  return html
      .replaceAll(
        RegExp(r'\bsrc="data:audio/[^"]*"', caseSensitive: false),
        'src=""',
      )
      .replaceAll(
        RegExp(r"\bsrc='data:audio/[^']*'", caseSensitive: false),
        "src=''",
      );
}

final _imgDataUriPattern = RegExp(
  r'(<img\b[^>]*\bsrc=")(data:image/[^";]+(?:;base64,[^"]+)?)(")',
  caseSensitive: false,
);

Future<String> _recompressDataUriImages(
  String html, {
  required int maxDimension,
  required int jpegQuality,
}) async {
  final matches = _imgDataUriPattern.allMatches(html).toList();
  if (matches.isEmpty) return html;

  var result = html;
  for (final match in matches.reversed) {
    final uri = match.group(2)!;
    final request = _RecompressRequest(
      dataUri: uri,
      maxDimension: maxDimension,
      jpegQuality: jpegQuality,
    );
    final lighter = uri.length < _inlineRecompressMaxChars
        ? _recompressDataUriIsolate(request)
        : await compute(_recompressDataUriIsolate, request);
    if (lighter == null || lighter == uri) continue;
    result = result.replaceRange(
      match.start,
      match.end,
      '${match.group(1)}$lighter${match.group(3)}',
    );
  }
  return result;
}

class _RecompressRequest {
  const _RecompressRequest({
    required this.dataUri,
    required this.maxDimension,
    required this.jpegQuality,
  });

  final String dataUri;
  final int maxDimension;
  final int jpegQuality;
}

String? _recompressDataUriIsolate(_RecompressRequest request) {
  try {
    final bytes = UriData.parse(request.dataUri).contentAsBytes();
    if (bytes.isEmpty) return null;
    final rawDecoded = img.decodeImage(bytes);
    if (rawDecoded == null) return null;
    final decoded = img.bakeOrientation(rawDecoded);

    final shouldResize =
        decoded.width > request.maxDimension ||
        decoded.height > request.maxDimension;
    final output = shouldResize
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height
                ? request.maxDimension
                : null,
            height: decoded.height > decoded.width
                ? request.maxDimension
                : null,
            interpolation: img.Interpolation.average,
          )
        : decoded;

    final jpg = Uint8List.fromList(
      img.encodeJpg(output, quality: request.jpegQuality),
    );
    if (jpg.length >= bytes.length) return null;
    return 'data:image/jpeg;base64,${base64Encode(jpg)}';
  } catch (_) {
    return null;
  }
}

final _photoImgPattern = RegExp(
  r'<img\b[^>]*\bdata-sf-photo\b[^>]*>',
  caseSensitive: false,
);

const _closingTags = '</body></html>';

/// Garante `utf8.encode(result).length <= maxBytes`.
///
/// 1. remove `<img data-sf-photo>` do fim para o começo;
/// 2. se ainda passar, corta o texto em fronteira de caractere UTF-8 (nunca
///    no meio de um code point/emoji), descarta uma tag aberta pela metade e
///    fecha com `</body></html>`.
@visibleForTesting
String trimReportHtmlToMaxBytes(String html, int maxBytes) {
  var bytes = utf8.encode(html).length;
  if (bytes <= maxBytes) return html;

  var trimmed = html;
  final matches = _photoImgPattern.allMatches(html).toList();
  for (var i = matches.length - 1; i >= 0 && bytes > maxBytes; i--) {
    final match = matches[i];
    bytes -= utf8.encode(match[0]!).length;
    trimmed = trimmed.replaceRange(match.start, match.end, '');
  }
  if (utf8.encode(trimmed).length <= maxBytes) return trimmed;
  return _cutToMaxBytes(trimmed, maxBytes);
}

String _cutToMaxBytes(String html, int maxBytes) {
  final budget = maxBytes - utf8.encode(_closingTags).length;
  final bytes = utf8.encode(html);
  // Nem as tags de fechamento cabem: devolve vazio em vez de estourar o teto.
  if (budget <= 0) return '';

  var end = budget;
  // bytes[end] é o 1º byte descartado: se for continuação, estamos no meio
  // de um caractere — recua até a fronteira.
  while (end > 0 && (bytes[end] & 0xC0) == 0x80) {
    end--;
  }
  var head = utf8.decode(bytes.sublist(0, end));
  final lastOpen = head.lastIndexOf('<');
  if (lastOpen > head.lastIndexOf('>')) head = head.substring(0, lastOpen);
  return '$head$_closingTags';
}
