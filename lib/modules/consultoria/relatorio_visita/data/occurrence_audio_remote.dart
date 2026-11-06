import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/network/network_policy.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/local_media_path_resolver.dart';

/// Resultado do envio do áudio local para o bucket da ocorrência.
enum AudioUploadResult { skipped, uploaded }

/// Acesso ao objeto de áudio, injetável nos testes.
abstract class OccurrenceAudioObjectStore {
  Future<void> upload(String objectPath, Uint8List bytes);

  Future<Uint8List> download(String objectPath);

  Future<void> remove(String objectPath);
}

/// Bucket privado `occurrence-audio`. Sem retry longo — só o timeout da rede.
class SupabaseOccurrenceAudioObjectStore implements OccurrenceAudioObjectStore {
  SupabaseOccurrenceAudioObjectStore(this._client);

  final SupabaseClient _client;

  static const bucket = 'occurrence-audio';

  @override
  Future<void> upload(String objectPath, Uint8List bytes) {
    return NetworkPolicy.withTimeout(() async {
      await _client.storage
          .from(bucket)
          .uploadBinary(
            objectPath,
            bytes,
            fileOptions: const FileOptions(
              contentType: 'audio/mp4',
              upsert: true,
            ),
            retryAttempts: 0,
          );
    });
  }

  @override
  Future<Uint8List> download(String objectPath) {
    return NetworkPolicy.withTimeout(
      () => _client.storage.from(bucket).download(objectPath),
    );
  }

  @override
  Future<void> remove(String objectPath) {
    return NetworkPolicy.withTimeout(() async {
      await _client.storage.from(bucket).remove([objectPath]);
    });
  }
}

/// Sobe e baixa o m4a da ocorrência sem mudar `audio_path` nem `sync_status`.
class OccurrenceAudioRemote {
  OccurrenceAudioRemote(this._store);

  final OccurrenceAudioObjectStore _store;

  static const _tag = 'OccurrenceAudio';

  /// Chave `{userId}/{occurrenceId}.m4a`. [userId] é o dono da linha.
  static String objectPath(String userId, String occurrenceId) =>
      '$userId/$occurrenceId.m4a';

  /// Sem arquivo local → [AudioUploadResult.skipped] e o store não é chamado.
  /// Falha do store propaga para o push não marcar `synced`.
  Future<AudioUploadResult> uploadIfLocal({
    required String userId,
    required String occurrenceId,
    required String? audioPath,
  }) async {
    final stored = audioPath?.trim() ?? '';
    if (stored.isEmpty) return AudioUploadResult.skipped;

    final resolved = await LocalMediaPathResolver.resolveLocalPath(stored);
    if (resolved == null || _isRemoteUrl(resolved)) {
      return AudioUploadResult.skipped;
    }
    final file = File(resolved);
    if (!await file.exists()) return AudioUploadResult.skipped;

    final bytes = await file.readAsBytes();
    await _store.upload(objectPath(userId, occurrenceId), bytes);
    return AudioUploadResult.uploaded;
  }

  /// Se o arquivo local já existe, devolve true sem baixar.
  /// Caminho com `..`, absoluto ou fora de `docs/media`: false, sem gravar.
  /// Rede ou 403: log e false. Não lança e não altera `sync_status`.
  Future<bool> downloadIfMissing({
    required String userId,
    required String occurrenceId,
    required String? audioPath,
    Directory? documentsDirectory,
  }) async {
    final stored = audioPath?.trim() ?? '';
    if (stored.isEmpty) return false;

    final docs = documentsDirectory ?? await getApplicationDocumentsDirectory();
    final target = _mediaFileInsideDocuments(docs, stored);
    if (target == null) return false;

    final resolved = await LocalMediaPathResolver.resolveLocalPath(stored);
    if (resolved != null &&
        !_isRemoteUrl(resolved) &&
        await File(resolved).exists() &&
        _fileStaysInsideMedia(docs, resolved)) {
      return true;
    }

    try {
      final bytes = await _store.download(objectPath(userId, occurrenceId));
      if (!await target.parent.exists()) {
        await target.parent.create(recursive: true);
      }
      await target.writeAsBytes(bytes, flush: true);
      return true;
    } catch (error) {
      AppLogger.warning(
        'Falha ao baixar áudio da ocorrência $occurrenceId',
        tag: _tag,
        error: error,
      );
      return false;
    }
  }

  /// Remove o objeto remoto. Falha só entra no log.
  Future<void> removeObject({
    required String userId,
    required String occurrenceId,
  }) async {
    try {
      await _store.remove(objectPath(userId, occurrenceId));
    } catch (error) {
      AppLogger.warning(
        'Falha ao remover áudio remoto da ocorrência $occurrenceId',
        tag: _tag,
        error: error,
      );
    }
  }

  static bool _isRemoteUrl(String path) =>
      path.startsWith('http://') || path.startsWith('https://');

  /// Grava só `docs/media/<basename>` de um nome sem barra.
  /// Recusa relativo com `..`, caminho absoluto ou destino fora de `docs/media`.
  static File? _mediaFileInsideDocuments(Directory docs, String stored) {
    final relative = LocalMediaPathResolver.toStoredPath(
      stored,
    ).replaceAll(r'\', '/');
    if (relative.isEmpty || _isUnsafeMediaPath(relative)) return null;

    final name = p.basename(relative);
    if (!_isSafeMediaFileName(name)) return null;

    final mediaDir = _mediaDirectory(docs);
    final targetPath = p.normalize(p.join(mediaDir, name));
    if (!p.isWithin(mediaDir, targetPath)) return null;
    return File(targetPath);
  }

  static bool _fileStaysInsideMedia(Directory docs, String path) {
    final normalized = p.normalize(path);
    if (normalized.contains('..')) return false;
    return p.isWithin(_mediaDirectory(docs), normalized);
  }

  static String _mediaDirectory(Directory docs) =>
      p.normalize(p.join(docs.path, LocalMediaPathResolver.mediaSegment));

  static bool _isUnsafeMediaPath(String path) =>
      path.contains('..') || p.isAbsolute(path) || p.posix.isAbsolute(path);

  static bool _isSafeMediaFileName(String name) =>
      name.isNotEmpty &&
      !name.contains('/') &&
      !name.contains(r'\') &&
      !name.contains('..');
}
