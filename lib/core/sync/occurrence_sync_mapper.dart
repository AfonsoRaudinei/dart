import '../sync/sync_constants.dart';

class OccurrenceSyncMapper {
  static String fromDb(dynamic value) {
    if (value is int) {
      return value == SyncConstants.statusSynced ? 'synced' : 'local';
    }
    if (value is String && value.isNotEmpty) {
      return value;
    }
    return 'local';
  }

  static int toDb(String value) {
    return value == 'synced' ? SyncConstants.statusSynced : SyncConstants.statusDirty;
  }

  static bool isPending(String syncStatus) {
    return syncStatus != 'synced';
  }
}
