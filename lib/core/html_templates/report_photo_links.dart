import 'dart:typed_data';

/// Foto de relatório extraída de `img[data-sf-photo]`.
class ReportPhoto {
  const ReportPhoto({required this.index, required this.src, this.caption});

  /// Valor de `data-sf-photo` (0-based, ordem do documento).
  final int index;

  /// `data:image/*;base64,...` ou URL `https`.
  final String src;

  /// Texto do `alt` (ex.: `Foto 2`), quando houver.
  final String? caption;

  bool get isDataUri => src.startsWith('data:');

  bool get isNetwork => src.startsWith('https://');

  /// Bytes de um data URI; `null` para URL remota ou data URI inválido.
  Uint8List? decodeBytes() {
    if (!isDataUri) return null;
    try {
      return UriData.parse(src).contentAsBytes();
    } catch (_) {
      return null;
    }
  }
}

/// Ponte HTML ↔ visualizador nativo de fotos (WebView com JavaScript
/// desabilitado). Funções puras: o HTML exportado não passa por aqui.
abstract final class ReportPhotoLinks {
  static const scheme = 'sfphoto';

  static final _imgTag = RegExp(r'<img\b[^>]*>', caseSensitive: false);
  static final _photoIndexAttr = RegExp(r'\sdata-sf-photo="(\d+)"');
  static final _lightboxToggle = RegExp(
    r'<input\b[^>]*\bclass="sf-lb-toggle"[^>]*>\s*',
    caseSensitive: false,
  );

  static String linkFor(int index) => '$scheme://$index';

  /// Índice N de `sfphoto://N`; `null` para qualquer outra URL.
  static int? indexFromUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != scheme) return null;
    return int.tryParse(uri.host);
  }

  /// Cópia do HTML para exibição no app: cada foto numerada vira link
  /// `sfphoto://N` e o lightbox CSS (checkbox) é removido.
  static String prepareInAppHtml(String html) {
    final withoutLightbox = html.replaceAll(_lightboxToggle, '');
    return withoutLightbox.replaceAllMapped(_imgTag, _linkPhotoTag);
  }

  static String _linkPhotoTag(Match match) {
    final tag = match[0]!;
    final index = _photoIndexAttr.firstMatch(tag)?.group(1);
    if (index == null) return tag;
    return '<a class="sf-photo-link" href="${linkFor(int.parse(index))}">'
        '$tag</a>';
  }

  /// Fotos `img[data-sf-photo]` com `src`, ordenadas pelo índice.
  static List<ReportPhoto> extractPhotos(String html) {
    final byIndex = <int, ReportPhoto>{};
    for (final match in _imgTag.allMatches(html)) {
      final tag = match[0]!;
      final index = int.tryParse(
        _photoIndexAttr.firstMatch(tag)?.group(1) ?? '',
      );
      if (index == null || byIndex.containsKey(index)) continue;
      final src = _unescape(_attr(tag, 'src') ?? '').trim();
      if (src.isEmpty) continue;
      final alt = _unescape(_attr(tag, 'alt') ?? '').trim();
      byIndex[index] = ReportPhoto(
        index: index,
        src: src,
        caption: alt.isEmpty ? null : alt,
      );
    }
    return byIndex.values.toList()..sort((a, b) => a.index - b.index);
  }

  static String? _attr(String tag, String name) {
    return RegExp('\\s$name="([^"]*)"').firstMatch(tag)?.group(1);
  }

  static String _unescape(String text) {
    return text
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&amp;', '&');
  }
}
