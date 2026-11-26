import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Teto da cópia HTML enviada ao WebKit de impressão (~8 MB).
@visibleForTesting
const int kReportPdfHtmlMaxBytes = 8 * 1024 * 1024;

@visibleForTesting
const int kReportPdfImageMaxDimension = 1024;

@visibleForTesting
const int kReportPdfJpegQuality = 72;

const _printStyle = '''
<style id="sf-pdf-print">
#sf-share-pdf-toolbar,
.sf-share-pdf-stub { display: none !important; }
@media print {
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

/// Cópia leve do HTML para [Printing.convertHtml]: sem áudio, imagens menores,
/// fotos extras removidas se passar do teto. O HTML exibido no app não muda.
Future<String> prepareReportHtmlForPdf(String html) async {
  var prepared = _stripAudioFromHtml(html);
  prepared = await _recompressDataUriImages(
    prepared,
    maxDimension: kReportPdfImageMaxDimension,
    jpegQuality: kReportPdfJpegQuality,
  );
  prepared = _injectPrintStyle(prepared);
  prepared = _trimHtmlToMaxBytes(prepared, kReportPdfHtmlMaxBytes);
  return prepared;
}

String _injectPrintStyle(String html) {
  if (html.contains('id="sf-pdf-print"')) return html;
  if (html.contains('</head>')) {
    return html.replaceFirst('</head>', '$_printStyle</head>');
  }
  return '$_printStyle$html';
}

String _stripAudioFromHtml(String html) {
  var out = html.replaceAll(
    RegExp(r'<audio\b[^>]*>[\s\S]*?</audio>', caseSensitive: false),
    '',
  );
  out = out.replaceAll(
    RegExp(r'<audio\b[^>]*/>', caseSensitive: false),
    '',
  );
  out = out.replaceAll(
    RegExp(r'\bsrc="data:audio/[^"]*"', caseSensitive: false),
    'src=""',
  );
  return out;
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
    final lighter = await compute(
      _recompressDataUriIsolate,
      _RecompressRequest(
        dataUri: uri,
        maxDimension: maxDimension,
        jpegQuality: jpegQuality,
      ),
    );
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
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

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

String _trimHtmlToMaxBytes(String html, int maxBytes) {
  if (html.length <= maxBytes) return html;
  var trimmed = html;
  final matches = _photoImgPattern.allMatches(trimmed).toList();
  for (var i = matches.length - 1; i >= 0 && trimmed.length > maxBytes; i--) {
    final match = matches[i];
    trimmed = trimmed.replaceRange(match.start, match.end, '');
  }
  return trimmed;
}