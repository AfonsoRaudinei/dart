import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

import '../utils/local_media_path_resolver.dart';

/// Utilitários base compartilhados por todos os renderers HTML.
/// Não depende de nenhum módulo de domínio.
abstract class RelatorioHtmlRenderer {
  static const _assetsBase = 'assets/html_templates/';
  static const int maxInlineImageBytes = 900 * 1024;
  static const int maxInlineImageDimension = 1600;
  static const baseCssAsset = '${_assetsBase}_sf_document_base.css';
  static const _baseCssToken = '{{sf_base_css}}';
  static final _googleFontsLink = RegExp(
    r'<link\b[^>]*fonts\.(?:googleapis|gstatic)\.com[^>]*>\s*',
    caseSensitive: false,
  );

  static String? _baseCssCache;

  /// Carrega o template HTML do asset bundle.
  ///
  /// Injeta a base de documento em `{{sf_base_css}}` e remove `<link>` de
  /// Google Fonts: o WebView abre o HTML offline e a fonte remota não carrega.
  static Future<String> loadTemplate(String filename) async {
    var template = await rootBundle.loadString(
      '$_assetsBase$filename',
      cache: false,
    );
    template = template.replaceAll(_googleFontsLink, '');
    if (template.contains(_baseCssToken)) {
      template = template.replaceAll(_baseCssToken, await _loadBaseCss());
    }
    return template;
  }

  static Future<String> _loadBaseCss() async {
    return _baseCssCache ??= await rootBundle.loadString(
      baseCssAsset,
      cache: false,
    );
  }

  /// Substitui todos os {{placeholders}} do template pelos valores do mapa.
  /// Valores nulos são substituídos por string vazia.
  static String replacePlaceholders(
    String template,
    Map<String, String> values,
  ) {
    var result = template;
    for (final entry in values.entries) {
      result = result.replaceAll('{{${entry.key}}}', entry.value);
    }
    return result;
  }

  /// Resolve um bloco Handlebars comentado do tipo:
  /// `<!-- {{#if condicao}} --> ... <!-- {{else}} --> ... <!-- {{/if}} -->`.
  ///
  /// Os templates são HTML estático; sem esta etapa, o navegador exibiria
  /// tanto o bloco verdadeiro quanto o falso porque as marcações são comentários.
  static String resolveIfBlock(
    String template,
    String condition, {
    required bool include,
    String? truthyHtml,
    String falsyHtml = '',
  }) {
    final startToken = '<!-- {{#if $condition}} -->';
    final start = template.indexOf(startToken);
    if (start < 0) return template;

    final parsed = _parseHandlebarsBlock(
      template,
      start: start,
      startTokenLength: startToken.length,
      openingPrefix: '#if ',
      closingToken: '/if',
    );
    if (parsed == null) return template;

    final truthyStart = start + startToken.length;
    final truthyEnd = parsed.elseStart ?? parsed.closeStart;
    final defaultTruthy = template.substring(truthyStart, truthyEnd);
    final replacement = include
        ? (truthyHtml ?? defaultTruthy)
        : (parsed.elseStart == null
              ? falsyHtml
              : template.substring(parsed.elseEnd!, parsed.closeStart));

    return template.replaceRange(start, parsed.closeEnd, replacement);
  }

  /// Resolve um bloco comentado `<!-- {{#each itens}} --> ... <!-- {{/each}} -->`.
  static String resolveEachBlock(
    String template,
    String collection, {
    required String html,
  }) {
    final startToken = '<!-- {{#each $collection}} -->';
    final start = template.indexOf(startToken);
    if (start < 0) return template;

    final parsed = _parseHandlebarsBlock(
      template,
      start: start,
      startTokenLength: startToken.length,
      openingPrefix: '#each ',
      closingToken: '/each',
    );
    if (parsed == null) return template;

    return template.replaceRange(start, parsed.closeEnd, html);
  }

  /// Remove qualquer `{{placeholder}}` remanescente depois da renderização.
  /// Deve ser usado no fim dos renderers para evitar vazamento visual de tokens.
  static String stripUnresolvedPlaceholders(String html) {
    return html.replaceAll(RegExp(r'\{\{[^}]+\}\}'), '');
  }

  static _HandlebarsBlock? _parseHandlebarsBlock(
    String template, {
    required int start,
    required int startTokenLength,
    required String openingPrefix,
    required String closingToken,
  }) {
    final tokenRegex = RegExp(r'<!--\s*\{\{([^}]+)\}\}\s*-->');
    var depth = 0;
    int? elseStart;
    int? elseEnd;

    final contentStart = start + startTokenLength;
    for (final match in tokenRegex.allMatches(template, contentStart)) {
      final token = match.group(1)?.trim() ?? '';
      if (token.startsWith(openingPrefix)) {
        depth++;
        continue;
      }
      if (token == closingToken) {
        if (depth == 0) {
          return _HandlebarsBlock(
            elseStart: elseStart,
            elseEnd: elseEnd,
            closeStart: match.start,
            closeEnd: match.end,
          );
        }
        depth--;
        continue;
      }
      if (token == 'else' && depth == 0) {
        elseStart = match.start;
        elseEnd = match.end;
      }
    }
    return null;
  }

  /// Converte um arquivo de foto local (path) para data URI base64.
  /// Retorna null se o path for nulo ou o arquivo não existir.
  static Future<String?> photoPathToBase64(
    String? path, {
    int maxBytes = maxInlineImageBytes,
    int maxDimension = maxInlineImageDimension,
    int jpegQuality = 78,
  }) async {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final resolved = await LocalMediaPathResolver.resolveLocalPath(path);
    if (resolved == null) return null;
    final file = File(resolved);
    if (!await file.exists()) return null;
    var bytes = await file.readAsBytes();
    var mime = _mimeFromPath(path);

    if (bytes.lengthInBytes > maxBytes) {
      final compressed = _compressImage(
        bytes,
        maxDimension: maxDimension,
        jpegQuality: jpegQuality,
      );
      if (compressed != null) {
        bytes = compressed;
        mime = 'image/jpeg';
      }
    }

    final b64 = base64Encode(bytes);
    return 'data:$mime;base64,$b64';
  }

  /// Aceita apenas `data:image/*` gerado internamente ou URLs `https` válidas.
  static String sanitizePhotoSrc(String? src) {
    if (src == null || src.isEmpty) return '';
    if (src.startsWith('data:image/')) return src;

    if (src.contains('"') ||
        src.contains("'") ||
        src.contains('<') ||
        src.contains('>') ||
        src.contains('\\')) {
      return '';
    }

    final uri = Uri.tryParse(src);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) return '';
    if (uri.userInfo.isNotEmpty) return '';
    return uri.toString();
  }

  /// Resolve foto local → data URI; remoto → apenas `https` sanitizado.
  static Future<String> resolvePhotoSrc(String? path) async {
    final resolved = await photoPathToBase64(path);
    return sanitizePhotoSrc(resolved);
  }

  /// Resolve foto para export HTML auto-contido (offline-first).
  ///
  /// - Path local → `data:image/*;base64,...`
  /// - URL remota → download + inline base64 (fallback: URL https sanitizada)
  static Future<String> resolvePhotoSrcForExport(
    String? path, {
    Future<Uint8List?> Function(String url)? fetchRemoteBytes,
  }) async {
    if (path == null || path.isEmpty) return '';
    final trimmed = path.trim();
    if (trimmed.startsWith('data:image/')) {
      return sanitizePhotoSrc(trimmed);
    }

    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      final sanitized = sanitizePhotoSrc(trimmed);
      if (sanitized.isEmpty) return '';
      final fetcher = fetchRemoteBytes ?? _fetchRemotePhotoBytes;
      final bytes = await fetcher(sanitized);
      if (bytes != null && bytes.isNotEmpty) {
        final inlined = _bytesToInlineDataUri(bytes, hintPath: sanitized);
        if (inlined != null) return inlined;
      }
      return sanitized;
    }

    final local = await photoPathToBase64(trimmed);
    return sanitizePhotoSrc(local);
  }

  static Future<Uint8List?> _fetchRemotePhotoBytes(String url) async {
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (_) {
      // fallback silencioso para URL remota no HTML exportado
    }
    return null;
  }

  static String? _bytesToInlineDataUri(
    Uint8List bytes, {
    required String hintPath,
    int maxBytes = maxInlineImageBytes,
    int maxDimension = maxInlineImageDimension,
    int jpegQuality = 78,
  }) {
    var output = bytes;
    var mime = _mimeFromPath(hintPath);
    if (output.lengthInBytes > maxBytes) {
      final compressed = _compressImage(
        output,
        maxDimension: maxDimension,
        jpegQuality: jpegQuality,
      );
      if (compressed != null) {
        output = compressed;
        mime = 'image/jpeg';
      }
    }
    return 'data:$mime;base64,${base64Encode(output)}';
  }

  static Future<String> assetImageToBase64(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final mime = _mimeFromPath(assetPath);
    final b64 = base64Encode(bytes);
    return 'data:$mime;base64,$b64';
  }

  static const soloForteLogoAsset = 'assets/images/soloforte_logo.png';

  /// Placeholders de marca SoloForte para todos os HTML de relatório.
  ///
  /// A marca aparece uma única vez, no rodapé (logo + "SoloForte").
  /// `report_header_signature` fica vazio: o timbre não repete a marca.
  /// O consultor aparece só no bloco de assinatura do template — por isso
  /// [consultantName] / [consultantRole] não entram no rodapé.
  /// Branding customizado (Settings) é ignorado de propósito — ver
  /// `.cursor/rules/soloforte-designer.mdc`.
  static Future<Map<String, String>> brandingPlaceholders({
    String? customBrandName,
    String? customLogoPath,
    String? consultantName,
    String? consultantRole,
  }) async {
    final logoSrc = await assetImageToBase64(soloForteLogoAsset);

    return {
      'report_header_signature': '',
      'report_footer_signature':
          '''
<div class="sf-brand">
  <img class="sf-brand-logo" src="$logoSrc" alt="" width="22" height="22" aria-hidden="true">
  <div class="sf-brand-copy">
    <strong>SoloForte</strong>
  </div>
</div>
''',
    };
  }

  /// Toda foto do relatório começa com `<img data-sf-photo ` (atributo sem
  /// valor). [finalizeDocument] troca cada ocorrência por `data-sf-photo="N"`
  /// (0-based, ordem do documento) — índice usado pelo visualizador nativo.
  /// Texto livre chega escapado (`&lt;img`), então não colide com o marcador.
  static final _photoImgMarker = RegExp(r'<img data-sf-photo(?=[\s>])');

  /// Numera as fotos marcadas na ordem do documento.
  static String indexReportPhotos(String html) {
    var index = 0;
    return html.replaceAllMapped(
      _photoImgMarker,
      (_) => '<img data-sf-photo="${index++}"',
    );
  }

  /// Etapa final comum dos renderers: remove tokens remanescentes e numera
  /// as fotos do relatório.
  static String finalizeDocument(String html) {
    return indexReportPhotos(stripUnresolvedPlaceholders(html));
  }

  static Uint8List? _compressImage(
    Uint8List bytes, {
    required int maxDimension,
    required int jpegQuality,
  }) {
    final decoded = img.decodeImage(bytes);
    if (decoded == null) return null;

    final shouldResize =
        decoded.width > maxDimension || decoded.height > maxDimension;
    final output = shouldResize
        ? img.copyResize(
            decoded,
            width: decoded.width >= decoded.height ? maxDimension : null,
            height: decoded.height > decoded.width ? maxDimension : null,
            interpolation: img.Interpolation.average,
          )
        : decoded;

    return Uint8List.fromList(img.encodeJpg(output, quality: jpegQuality));
  }

  static String _mimeFromPath(String path) {
    final ext = path.split('.').last.toLowerCase();
    if (ext == 'png') return 'image/png';
    if (ext == 'webp') return 'image/webp';
    return 'image/jpeg';
  }

  /// Formata DateTime para dd/MM/yyyy.
  static String formatDate(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy', 'pt_BR').format(dt);
  }

  /// Formata DateTime para dd/MM/yyyy HH:mm.
  static String formatDateTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('dd/MM/yyyy HH:mm', 'pt_BR').format(dt);
  }

  /// Formata DateTime para HH:mm (hora apenas).
  static String formatTime(DateTime? dt) {
    if (dt == null) return '';
    return DateFormat('HH:mm', 'pt_BR').format(dt);
  }

  /// Formata double para 1 casa decimal (ex: 12.5 -> "12,5").
  static String formatHectares(double? value) {
    if (value == null) return '';
    return NumberFormat('#,##0.0', 'pt_BR').format(value);
  }

  static const _knownKeyLabels = {
    'estadio': 'Estádio',
    'estadio_fenologico': 'Estádio fenológico',
    'altura': 'Altura',
    'pressao': 'Pressão',
    'observacao': 'Observação',
    'observacoes': 'Observações',
    'severidade': 'Severidade',
    'incidencia': 'Incidência',
    'populacao': 'População',
    'umidade': 'Umidade',
    'area': 'Área',
  };

  static const _unitSuffixes = {
    'cm': 'cm',
    'mm': 'mm',
    'm': 'm',
    'ha': 'ha',
    'pct': '%',
    'kg': 'kg',
  };

  /// Converte chave técnica (`altura_cm`, `incidencia_pct`) em rótulo legível
  /// (`Altura (cm)`, `Incidência (%)`). Não escapa HTML.
  static String humanizeKey(String key) {
    final normalized = key.trim().toLowerCase();
    if (normalized.isEmpty) return key.trim();
    final known = _knownKeyLabels[normalized];
    if (known != null) return known;

    final parts = normalized
        .split(RegExp(r'[_\s]+'))
        .where((part) => part.isNotEmpty)
        .toList();
    String? unit;
    if (parts.length > 1 && _unitSuffixes.containsKey(parts.last)) {
      unit = _unitSuffixes[parts.removeLast()];
    }
    final baseKey = parts.join('_');
    var base = _knownKeyLabels[baseKey] ?? parts.join(' ');
    if (base.isNotEmpty) base = base[0].toUpperCase() + base.substring(1);
    return unit == null ? base : '$base ($unit)';
  }

  /// Retorna os primeiros 8 caracteres de um UUID.
  static String shortId(String id) {
    if (id.length < 8) return id;
    return id.substring(0, 8).toUpperCase();
  }

  /// Escapa caracteres HTML para evitar XSS nos dados injetados.
  static String escapeHtml(String? text) {
    if (text == null) return '';
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }

  /// Formata data atual para exibição no footer.
  static String geradoEm() {
    return DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR').format(DateTime.now());
  }
}

class _HandlebarsBlock {
  const _HandlebarsBlock({
    required this.elseStart,
    required this.elseEnd,
    required this.closeStart,
    required this.closeEnd,
  });

  final int? elseStart;
  final int? elseEnd;
  final int closeStart;
  final int closeEnd;
}
