import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' show ClientException;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import 'package:soloforte_app/core/contracts/i_report_share_link_publisher.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

/// Publica HTML de relatório no bucket `report-shares` e registra metadados.
class ReportShareLinkService implements IReportShareLinkPublisher {
  ReportShareLinkService(this._supabase);

  static const bucket = 'report-shares';
  static const _uuid = Uuid();
  static const tag = 'ReportShareLink';
  static const offlineMessage = 'Sem conexão para publicar o link.';

  final SupabaseClient _supabase;

  /// Caminho no bucket: `{userId}/{token}.html`
  static String storagePathForUser({
    required String userId,
    required String token,
  }) {
    return '$userId/$token.html';
  }

  /// Garante viewport e rodapé mínimo para leitura mobile no browser.
  static String ensureMobileReadyHtml(String html) {
    const viewport =
        '<meta name="viewport" content="width=device-width, initial-scale=1">';
    // Rodapé na página pública: `window.print()` → Salvar em PDF no diálogo do SO.
    const pdfToolbar = '''
<style id="sf-share-print-css">
@media print {
  #sf-share-pdf-toolbar { display: none !important; }
  body { print-color-adjust: exact; -webkit-print-color-adjust: exact; }
}
</style>
<div id="sf-share-pdf-toolbar" class="sf-share-pdf-stub" style="margin:24px 16px;padding:16px;text-align:center;font-family:-apple-system,BlinkMacSystemFont,sans-serif;font-size:13px;color:#444;border-top:1px solid #e0e0e0;">
  <p style="margin:0 0 12px;line-height:1.45;color:#666;">Para gerar um PDF, toque no botão abaixo e, na tela de impressão do aparelho, escolha <strong>Salvar em PDF</strong> ou <strong>PDF</strong>.</p>
  <button type="button" onclick="window.print()" style="padding:10px 20px;border-radius:10px;border:none;background:#0175C2;color:#fff;font-size:15px;font-weight:600;cursor:pointer;-webkit-tap-highlight-color:transparent;">Gerar PDF</button>
</div>''';

    var doc = html.trim();
    if (!doc.toLowerCase().contains('viewport')) {
      if (doc.contains('<head>')) {
        doc = doc.replaceFirst('<head>', '<head>\n$viewport');
      } else if (RegExp(r'<html[\s>]', caseSensitive: false).hasMatch(doc)) {
        doc = doc.replaceFirst(
          RegExp(r'<html([^>]*)>', caseSensitive: false),
          '<html\$1><head>$viewport<meta charset="utf-8"></head>',
        );
      } else {
        doc =
            '<!DOCTYPE html><html><head>$viewport<meta charset="utf-8"></head><body>$doc</body></html>';
      }
    }

    if (!doc.contains('sf-share-pdf-stub')) {
      if (doc.contains('</body>')) {
        doc = doc.replaceFirst('</body>', '$pdfToolbar\n</body>');
      } else {
        doc = '$doc$pdfToolbar';
      }
    }
    return doc;
  }

  @override
  Future<ReportShareLinkPublished> publishHtml({
    required String title,
    required String html,
    String? reportKind,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw StateError('Faça login para enviar link.');
    }

    final userId = user.id.trim();
    final token = _uuid.v4();
    final storagePath = storagePathForUser(userId: userId, token: token);
    final body = ensureMobileReadyHtml(html);
    final bytes = utf8.encode(body);

    var objectUploaded = false;
    try {
      await _supabase.storage.from(bucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'text/html',
              upsert: false,
            ),
          );
      objectUploaded = true;

      final publicUrl =
          _supabase.storage.from(bucket).getPublicUrl(storagePath);

      await _supabase.from('report_share_links').insert({
        'user_id': userId,
        'token': token,
        'title': title.trim().isEmpty ? 'Relatório SoloForte' : title.trim(),
        'storage_path': storagePath,
        'public_url': publicUrl,
        if (reportKind != null && reportKind.trim().isNotEmpty)
          'report_kind': reportKind.trim(),
      });

      AppLogger.debug('Report share published token=$token', tag: tag);

      return ReportShareLinkPublished(
        publicUrl: publicUrl,
        token: token,
        storagePath: storagePath,
      );
    } catch (e, st) {
      if (objectUploaded) {
        await _removeStorageObject(storagePath);
      }
      AppLogger.error('ReportShareLink publish failed', error: e, stackTrace: st);
      if (e is StateError) rethrow;
      if (_isOfflineError(e)) {
        throw StateError(offlineMessage);
      }
      rethrow;
    }
  }

  Future<void> _removeStorageObject(String storagePath) async {
    try {
      await _supabase.storage.from(bucket).remove([storagePath]);
    } catch (e, st) {
      AppLogger.error(
        'ReportShareLink cleanup remove failed',
        tag: tag,
        error: e,
        stackTrace: st,
      );
    }
  }

  static bool _isOfflineError(Object error) {
    if (error is SocketException ||
        error is TimeoutException ||
        error is ClientException) {
      return true;
    }
    if (error is StorageException) {
      final msg = error.message.toLowerCase();
      return msg.contains('network') || msg.contains('fetch');
    }
    return false;
  }
}
