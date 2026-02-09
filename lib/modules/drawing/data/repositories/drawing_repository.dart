import '../data_sources/drawing_local_store.dart';
import '../../domain/models/drawing_models.dart';
import '../data_sources/drawing_sync_service.dart';

class DrawingRepository {
  final DrawingLocalStore _localStore;
  final DrawingSyncService _syncService;

  DrawingRepository({
    DrawingLocalStore? localStore,
    DrawingSyncService? syncService,
  }) : _localStore = localStore ?? DrawingLocalStore(),
       _syncService = syncService ?? DrawingSyncService();

  Future<void> saveFeature(DrawingFeature feature) async {
    // Check if exists
    final existing = await _localStore.getById(feature.id);
    if (existing != null) {
      await _localStore.update(feature);
    } else {
      await _localStore.insert(feature);
    }
  }

  Future<void> deleteFeature(String id) async {
    await _localStore.delete(id);
  }

  Future<List<DrawingFeature>> getAllFeatures() async {
    return await _localStore.getAll();
  }

  /// Trigger remote synchronization via SyncService
  Future<DrawingSyncResult> sync() async {
    return await _syncService.synchronize();
  }

  /// Sets status to pending_sync for all local_only features
  /// Triggered by user action "Sync Now"
  Future<void> markAllForSync() async {
    final all = await _localStore.getAll();
    for (var f in all) {
      if (f.properties.syncStatus == SyncStatus.local_only) {
        final pendingFeature = DrawingFeature(
          id: f.id,
          geometry: f.geometry,
          properties: f.properties.copyWith(
            syncStatus: SyncStatus.pending_sync,
          ),
        );
        await _localStore.update(pendingFeature);
      }
    }
  }
}
