import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

enum ReportExportFormat { pdf, html, json, csv }

class ReportExportPayload {
  final String title;
  final String html;
  final String? fileBaseName;
  final Map<String, dynamic>? json;
  final String? csv;

  const ReportExportPayload({
    required this.title,
    required this.html,
    this.fileBaseName,
    this.json,
    this.csv,
  });
}

class ReportExportResult {
  final ReportExportFormat format;
  final String? path;

  const ReportExportResult({required this.format, this.path});
}

class ReportExportService {
  const ReportExportService();

  static String safeFileBaseName(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'\s+'), '_')
        .replaceAll(RegExp(r'[^a-z0-9_\-]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return normalized.isEmpty ? 'relatorio' : normalized;
  }

  Future<ReportExportResult> export(
    ReportExportFormat format,
    ReportExportPayload payload,
  ) async {
    switch (format) {
      case ReportExportFormat.pdf:
        return exportPdf(payload);
      case ReportExportFormat.html:
        return exportHtml(payload);
      case ReportExportFormat.json:
        return exportJson(payload);
      case ReportExportFormat.csv:
        return exportCsv(payload);
    }
  }

  Future<ReportExportResult> exportPdf(ReportExportPayload payload) async {
    await Printing.layoutPdf(
      onLayout: (format) async {
        // ignore: deprecated_member_use
        return Printing.convertHtml(format: format, html: payload.html);
      },
      name: '${_baseName(payload)}.pdf',
    );
    return const ReportExportResult(format: ReportExportFormat.pdf);
  }

  Future<ReportExportResult> exportHtml(ReportExportPayload payload) {
    return _writeAndShare(
      format: ReportExportFormat.html,
      payload: payload,
      extension: 'html',
      content: payload.html,
      mimeType: 'text/html',
    );
  }

  Future<ReportExportResult> exportJson(ReportExportPayload payload) {
    final data = payload.json;
    if (data == null) {
      throw StateError('Dados JSON indisponiveis para este relatorio.');
    }
    return _writeAndShare(
      format: ReportExportFormat.json,
      payload: payload,
      extension: 'json',
      content: const JsonEncoder.withIndent('  ').convert(data),
      mimeType: 'application/json',
    );
  }

  Future<ReportExportResult> exportCsv(ReportExportPayload payload) {
    final data = payload.csv;
    if (data == null || data.trim().isEmpty) {
      throw StateError('Dados CSV indisponiveis para este relatorio.');
    }
    return _writeAndShare(
      format: ReportExportFormat.csv,
      payload: payload,
      extension: 'csv',
      content: data,
      mimeType: 'text/csv',
    );
  }

  Future<File> writeTempFile({
    required String baseName,
    required String extension,
    required String content,
  }) async {
    final dir = await getTemporaryDirectory();
    final safeName = safeFileBaseName(baseName);
    final file = File('${dir.path}/$safeName.$extension');
    await file.writeAsString(content, flush: true);
    return file;
  }

  Future<ReportExportResult> _writeAndShare({
    required ReportExportFormat format,
    required ReportExportPayload payload,
    required String extension,
    required String content,
    required String mimeType,
  }) async {
    final file = await writeTempFile(
      baseName: _baseName(payload),
      extension: extension,
      content: content,
    );
    await Share.shareXFiles([
      XFile(file.path, mimeType: mimeType),
    ], subject: payload.title);
    return ReportExportResult(format: format, path: file.path);
  }

  String _baseName(ReportExportPayload payload) {
    return safeFileBaseName(payload.fileBaseName ?? payload.title);
  }
}

@visibleForTesting
String reportSafeFileBaseNameForTest(String value) {
  return ReportExportService.safeFileBaseName(value);
}
