import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/app_logger.dart';
import '../../../../core/utils/local_media_path_resolver.dart';

/// Persistência local de áudio de ocorrência (até 30 s no formulário).
class OccurrenceAudioStorage {
  OccurrenceAudioStorage._();
  static final OccurrenceAudioStorage instance = OccurrenceAudioStorage._();

  Future<String?> persistLocalCopy(String sourcePath) async {
    try {
      if (sourcePath.trim().isEmpty) return null;
      final resolved = await LocalMediaPathResolver.resolveLocalPath(sourcePath);
      final source = File(resolved ?? sourcePath);
      if (!await source.exists()) return null;
      final saved = await _saveToAppDirectory(source);
      return LocalMediaPathResolver.toStoredPath(saved.path);
    } catch (e, st) {
      AppLogger.error(
        'Erro ao persistir áudio da ocorrência',
        tag: 'OccurrenceAudio',
        error: e,
        stackTrace: st,
      );
      return null;
    }
  }

  Future<File> _saveToAppDirectory(File sourceFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(
      p.join(directory.path, LocalMediaPathResolver.mediaSegment),
    );
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }
    final ext = p.extension(sourceFile.path);
    final safeExt = ext.isNotEmpty ? ext : '.m4a';
    final newFileName = 'audio_${const Uuid().v4()}$safeExt';
    final newPath = p.join(mediaDir.path, newFileName);
    return sourceFile.copy(newPath);
  }

  Future<void> deleteAudio(String? storedPath) async {
    if (storedPath == null || storedPath.trim().isEmpty) return;
    try {
      final resolved = await LocalMediaPathResolver.resolveLocalPath(storedPath);
      final file = File(resolved ?? storedPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      AppLogger.warning(
        'Erro ao excluir áudio',
        tag: 'OccurrenceAudio',
        error: e,
      );
    }
  }
}
