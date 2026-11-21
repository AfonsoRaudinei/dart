import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

/// Upload de foto da implementação do campo de teste (espelho de upload sem marketing).
class TesteExecucaoPhotoService {
  static const _bucket = 'teste-execucoes';
  static const _maxFileSizeBytes = 5 * 1024 * 1024;

  final SupabaseClient _supabase;
  final _uuid = const Uuid();

  TesteExecucaoPhotoService(this._supabase);

  factory TesteExecucaoPhotoService.live() =>
      TesteExecucaoPhotoService(Supabase.instance.client);

  Future<String?> uploadPickedPath({
    required BuildContext context,
    required String path,
    String? folder,
  }) async {
    final file = File(path);
    if (!await file.exists()) return null;

    final fileSize = await file.length();
    if (fileSize > _maxFileSizeBytes) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Foto muito grande (${(fileSize / 1024 / 1024).toStringAsFixed(1)} MB). Máximo: 5 MB.',
            ),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return null;
    }

    final url = await _upload(file, folder: folder);
    if (url == null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Não foi possível enviar a foto. Tente novamente.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
    return url;
  }

  Future<String?> _upload(File file, {String? folder}) async {
    try {
      final userId = LocalSessionIdentity.resolveUserId();
      if (userId.isEmpty) {
        throw StateError('Usuario nao autenticado.');
      }

      var ext = p.extension(file.path).replaceFirst('.', '').toLowerCase();
      if (ext.isEmpty || ext == 'heic' || ext == 'heif') ext = 'jpg';
      final mimeType = switch (ext) {
        'jpg' => 'image/jpeg',
        'jpeg' => 'image/jpeg',
        'png' => 'image/png',
        'webp' => 'image/webp',
        'gif' => 'image/gif',
        _ => 'image/jpeg',
      };
      final name = '${_uuid.v4()}.$ext';
      final safeFolder = folder?.replaceAll(RegExp(r'(^/+|/+$)'), '');
      final storagePath = safeFolder != null && safeFolder.isNotEmpty
          ? '$userId/$safeFolder/$name'
          : '$userId/$name';

      await _supabase.storage.from(_bucket).upload(
            storagePath,
            file,
            fileOptions: FileOptions(contentType: mimeType, upsert: false),
          );

      return _supabase.storage.from(_bucket).getPublicUrl(storagePath);
    } on StorageException catch (e, st) {
      AppLogger.error(
        'TesteExecucaoPhotoService upload error',
        error: e,
        stackTrace: st,
      );
      rethrow;
    } catch (e) {
      AppLogger.error('TesteExecucaoPhotoService unexpected error', error: e);
      return null;
    }
  }
}