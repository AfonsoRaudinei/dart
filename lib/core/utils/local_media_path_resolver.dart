import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Resolve paths de mídia local (relativos ou absolutos legados) para arquivo existente.
abstract class LocalMediaPathResolver {
  static const String mediaSegment = 'media';

  /// Converte path absoluto em relativo ao diretório de documentos (`media/…`).
  static String toStoredPath(String absoluteOrRelativePath) {
    if (absoluteOrRelativePath.isEmpty) return '';
    final normalized = absoluteOrRelativePath.replaceAll(r'\', '/');
    final mediaIndex = normalized.lastIndexOf('/$mediaSegment/');
    if (mediaIndex >= 0) {
      return normalized.substring(mediaIndex + 1);
    }
    if (normalized.startsWith('$mediaSegment/')) {
      return normalized;
    }
    final fileName = p.basename(normalized);
    if (fileName.isEmpty) return normalized;
    return p.join(mediaSegment, fileName).replaceAll(r'\', '/');
  }

  /// Resolve path armazenado (relativo ou absoluto legado) para path absoluto existente.
  static Future<String?> resolveLocalPath(String stored) async {
    if (stored.isEmpty) return null;
    if (stored.startsWith('http://') || stored.startsWith('https://')) {
      return stored;
    }

    final normalized = stored.replaceAll(r'\', '/');
    final candidates = <String>[];

    if (p.isAbsolute(normalized)) {
      candidates.add(normalized);
    } else {
      final directory = await getApplicationDocumentsDirectory();
      candidates.add(p.join(directory.path, normalized));
      if (!normalized.startsWith('$mediaSegment/')) {
        candidates.add(
          p.join(directory.path, mediaSegment, p.basename(normalized)),
        );
      }
    }

    for (final candidate in candidates) {
      if (await File(candidate).exists()) return candidate;
    }
    return null;
  }
}
