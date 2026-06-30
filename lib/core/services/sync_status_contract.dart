/// Valores canônicos de [sync_status] para entidades sincronizáveis (AGENTS.md).
class SyncStatusContract {
  SyncStatusContract._();

  static const localOnly = 'local_only';
  static const pendingSync = 'pending_sync';
  static const synced = 'synced';
  static const syncError = 'sync_error';
  static const deletedLocal = 'deleted_local';

  /// Legado SQLite (int) e strings antigas ainda presentes no banco.
  static const legacyPending = 'pending';
  static const legacyLocal = 'local';

  static const canonicalValues = {
    localOnly,
    pendingSync,
    synced,
    syncError,
    deletedLocal,
  };

  /// Normaliza valores legados para o contrato canônico.
  static String normalize(String? value) {
    switch (value) {
      case pendingSync:
      case legacyPending:
      case '1':
        return pendingSync;
      case synced:
      case '0':
        return synced;
      case syncError:
        return syncError;
      case deletedLocal:
      case 'deleted':
        return deletedLocal;
      case legacyLocal:
        return localOnly;
      case localOnly:
        return localOnly;
      default:
        return localOnly;
    }
  }

  static bool isPending(String? value) {
    final normalized = normalize(value);
    return normalized == pendingSync || normalized == localOnly;
  }

  static bool isValidCanonical(String? value) =>
      value != null && canonicalValues.contains(value);
}
