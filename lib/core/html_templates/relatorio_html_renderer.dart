import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:intl/intl.dart';

/// Utilitários base compartilhados por todos os renderers HTML.
/// Não depende de nenhum módulo de domínio.
abstract class RelatorioHtmlRenderer {
  static const _assetsBase = 'assets/html_templates/';
  static const int maxInlineImageBytes = 900 * 1024;
  static const int maxInlineImageDimension = 1600;

  /// Carrega o template HTML do asset bundle.
  static Future<String> loadTemplate(String filename) async {
    return rootBundle.loadString('$_assetsBase$filename');
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
    final file = File(path);
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

  static Future<String> assetImageToBase64(String assetPath) async {
    final data = await rootBundle.load(assetPath);
    final bytes = data.buffer.asUint8List();
    final mime = _mimeFromPath(assetPath);
    final b64 = base64Encode(bytes);
    return 'data:$mime;base64,$b64';
  }

  static Future<Map<String, String>> brandingPlaceholders({
    String? customBrandName,
    String? customLogoPath,
    String? consultantName,
    String? consultantRole,
  }) async {
    // Branding customizado (logo/nome do consultor) permanece em Settings para
    // sync futuro, mas os templates HTML usam header limpo + rodapé SoloForte
    // único (soloforte-designer.mdc). Parâmetros custom* são ignorados de propósito.
    final escapedConsultant = escapeHtml(consultantName);
    final escapedRole = escapeHtml(consultantRole);
    final issuerCaption = escapedConsultant.isNotEmpty
        ? escapedRole.isNotEmpty
              ? 'Responsável: $escapedConsultant · $escapedRole'
              : 'Responsável: $escapedConsultant'
        : 'Agronomia inteligente · www.soloforte.app';

    return {
      'report_header_signature': '',
      'report_footer_signature':
          '''
<div class="sf-brand">
  <span class="sf-brand-icon" aria-hidden="true">🌱</span>
  <div class="sf-brand-copy">
    <strong>SoloForte</strong>
    <span class="sf-brand-tagline">$issuerCaption</span>
  </div>
</div>
''',
    };
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
