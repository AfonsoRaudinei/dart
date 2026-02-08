import 'drawing_local_store.dart';
import 'drawing_remote_store.dart';
import 'drawing_models.dart';

class DrawingSyncResult {
  final List<DrawingFeature> updated;
  final List<DrawingFeature> conflicts;
  final int errors;

  DrawingSyncResult({
    this.updated = const [],
    this.conflicts = const [],
    this.errors = 0,
  });
}

class DrawingSyncService {
  final DrawingLocalStore _localStore;
  final DrawingRemoteStore _remoteStore;

  DrawingSyncService({
    DrawingLocalStore? localStore,
    DrawingRemoteStore? remoteStore,
  }) : _localStore = localStore ?? DrawingLocalStore(),
       _remoteStore = remoteStore ?? DrawingRemoteStore();

  Future<DrawingSyncResult> synchronize() async {
    final resultUpdates = <DrawingFeature>[];
    final resultConflicts = <DrawingFeature>[];
    int errorCount = 0;

    // 1. PUSH: Send pending sync features
    final pending = await _localStore.getPendingSync();

    for (var feature in pending) {
      try {
        await _remoteStore.push(feature);

        // Success: Mark synced
        final synced = DrawingFeature(
          id: feature.id,
          geometry: feature.geometry,
          properties: feature.properties.copyWith(
            syncStatus: SyncStatus.synced,
            updatedAt:
                DateTime.now(), // Local update ts after sync? Usually backend returns new ts.
          ),
        );
        await _localStore.update(synced);
        resultUpdates.add(synced);
      } catch (e) {
        // Error: Keep pending or mark conflict if specific error?
        // Simple error -> keep pending to retry later.
        // If conflict error (409) -> mark conflict.
        // Stub implementation marks conflict for demo sometimes, or just error.
        errorCount++;
        // If critical conflict logic needed on push:
        // if (e is ConflictException) ...
      }
    }

    // 2. PULL: Fetch remote updates
    // Assuming we track last sync timestamp
    // final lastSync = await _localStore.getLastSyncTime();
    final remoteUpdates = await _remoteStore.fetchUpdates(null);

    for (var remote in remoteUpdates) {
      final local = await _localStore.getById(remote.id);

      if (local == null) {
        // New remote feature -> Insert
        final newLocal = DrawingFeature(
          id: remote.id,
          geometry: remote.geometry,
          properties: remote.properties.copyWith(syncStatus: SyncStatus.synced),
        );
        await _localStore.insert(newLocal);
        resultUpdates.add(newLocal);
      } else {
        // Exists locally. Check for conflict.

        // Conflict Condition:
        // Local has changes not synced (pending) AND remote has changes (updated_at > local.last_synced_at?)
        // OR simply: local version != remote version AND local status != synced?

        if (local.properties.syncStatus != SyncStatus.synced) {
          // Local was edited and not pushed yet. Remote also changed.
          // CONFLICT!
          final conflict = DrawingFeature(
            id: local.id,
            geometry: local.geometry, // Keep local geometry accessible
            properties: local.properties.copyWith(
              syncStatus: SyncStatus.conflict,
            ),
          );

          // We do NOT overwrite local geometry. We just mark status.
          // Maybe we store remote version aside?
          // For now, simpler implementation: Mark conflict status on local item.
          await _localStore.update(conflict);
          resultConflicts.add(conflict);
        } else {
          // Local is synced (clean). Remote is newer.
          // Safe auto-update
          if (remote.properties.updatedAt.isAfter(local.properties.updatedAt)) {
            final newLocal = DrawingFeature(
              id: remote.id,
              geometry: remote.geometry,
              properties: remote.properties.copyWith(
                syncStatus: SyncStatus.synced,
              ),
            );
            await _localStore.update(newLocal);
            resultUpdates.add(newLocal);
          }
        }
      }
    }

    return DrawingSyncResult(
      updated: resultUpdates,
      conflicts: resultConflicts,
      errors: errorCount,
    );
  }

  // Resolve conflict: "Use Local"
  Future<void> resolveUseLocal(String id) async {
    final local = await _localStore.getById(id);
    if (local == null) return;

    // Force push local version as new authority (increment version?)
    // Set status to pending to retry push
    // Increment version to beat remote next time?
    final resolved = DrawingFeature(
      id: local.id,
      geometry: local.geometry,
      properties: local.properties.copyWith(
        syncStatus: SyncStatus.pending_sync,
        updatedAt: DateTime.now(),
        versao: local.properties.versao + 1,
      ),
    );
    await _localStore.update(resolved);
  }

  // Resolve conflict: "Use Remote"
  Future<void> resolveUseRemote(String id, DrawingFeature remoteVersion) async {
    // Overwrite local with remote
    final resolved = DrawingFeature(
      id: remoteVersion.id,
      geometry: remoteVersion.geometry,
      properties: remoteVersion.properties.copyWith(
        syncStatus: SyncStatus.synced,
      ),
    );
    await _localStore.update(resolved);
  }
}
