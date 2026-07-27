import 'dart:io';

/// Detecta se um valor de mídia de marketing é URL remota ou path local.
///
/// Offline-first: fotos podem ficar em `documents/media/marketing/` até o
/// upload no Supabase Storage no momento do sync.
class MarketingMediaRef {
  const MarketingMediaRef._();

  static bool isRemoteUrl(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    return trimmed.startsWith('http://') || trimmed.startsWith('https://');
  }

  static bool isLocalPath(String? value) {
    if (value == null) return false;
    final trimmed = value.trim();
    if (trimmed.isEmpty || isRemoteUrl(trimmed)) return false;
    return true;
  }

  /// Normaliza `file://` → path absoluto do filesystem.
  static String? toFilePath(String? value) {
    if (!isLocalPath(value)) return null;
    final trimmed = value!.trim();
    if (trimmed.startsWith('file://')) {
      try {
        return Uri.parse(trimmed).toFilePath();
      } catch (_) {
        return trimmed.replaceFirst('file://', '');
      }
    }
    return trimmed;
  }

  static bool localFileExists(String? value) {
    final path = toFilePath(value);
    if (path == null) return false;
    return File(path).existsSync();
  }
}
