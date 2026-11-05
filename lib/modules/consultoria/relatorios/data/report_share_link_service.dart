import 'dart:convert';

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
    const pdfStub = '''
<div id="sf-share-pdf-stub" style="margin:24px 16px;padding:12px;text-align:center;font-family:-apple-system,sans-serif;font-size:13px;color:#666;border-top:1px solid #e0e0e0;">
  <button type="button" disabled style="opacity:0.5;padding:8px 16px;border-radius:8px;border:1px solid #ccc;background:#f5f5f5;">Gerar PDF (em breve)</button>
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
        doc = doc.replaceFirst('</body>', '$pdfStub\n</body>');
      } else {
        doc = '$doc$pdfStub';
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

    try {
      await _supabase.storage.from(bucket).uploadBinary(
            storagePath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'text/html',
              upsert: false,
            ),
          );
    } on StorageException catch (e, st) {
      AppLogger.error('ReportShareLink upload failed', error: e, stackTrace: st);
      final msg = e.message.toLowerCase();
      if (msg.contains('network') || msg.contains('fetch')) {
        throw StateError(
          'Sem conexão. Conecte-se à internet para publicar o link.',
        );
      }
      rethrow;
    }

    final publicUrl = _supabase.storage.from(bucket).getPublicUrl(storagePath);

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
  }
}
