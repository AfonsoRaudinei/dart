import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

/// Utilitários base compartilhados por todos os renderers HTML.
/// Não depende de nenhum módulo de domínio.
abstract class RelatorioHtmlRenderer {
  static const _assetsBase = 'assets/html_templates/';

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

  /// Converte um arquivo de foto local (path) para data URI base64.
  /// Retorna null se o path for nulo ou o arquivo não existir.
  static Future<String?> photoPathToBase64(String? path) async {
    if (path == null || path.isEmpty) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    final bytes = await file.readAsBytes();
    final b64 = base64Encode(bytes);
    // Detecta extensão para MIME correto.
    final ext = path.split('.').last.toLowerCase();
    final mime = ext == 'png' ? 'image/png' : 'image/jpeg';
    return 'data:$mime;base64,$b64';
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
