import 'package:soloforte_app/core/services/sync_retry_runner.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'drawing_local_store.dart';
import 'drawing_remote_store.dart';
import '../../domain/models/drawing_models.dart';

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
        await SyncRetryRunner.execute(
          operation: () => _remoteStore.push(feature),
          tag: 'DrawingSync',
          stage: 'drawing_push_remote',
          entityId: feature.id,
        );

        try {
          final synced = DrawingFeature(
            id: feature.id,
            geometry: feature.geometry,
            properties: feature.properties.copyWith(
              syncStatus: SyncStatus.synced,
              updatedAt: DateTime.now(),
            ),
          );
          await _localStore.update(synced);
          resultUpdates.add(synced);
          AppLogger.debug(
            'Drawing push synced [id=${feature.id}]',
            tag: 'DrawingSync',
          );
        } catch (error, stackTrace) {
          errorCount++;
          AppLogger.error(
            'Drawing push remoto concluido, mas persistencia local falhou '
            '[id=${feature.id}]',
            tag: 'DrawingSync',
            error: error,
            stackTrace: stackTrace,
          );
        }
      } catch (error) {
        errorCount++;
        AppLogger.warning(
          'Drawing push falhou; pendencia local preservada [id=${feature.id}]',
          tag: 'DrawingSync',
          error: error,
        );
      }
    }

    // 2. PULL: Fetch remote updates
    List<DrawingFeature> remoteUpdates = const [];
    try {
      remoteUpdates = await SyncRetryRunner.execute(
        operation: () => _remoteStore.fetchUpdates(null),
        tag: 'DrawingSync',
        stage: 'drawing_pull_remote',
      );
    } catch (error) {
      errorCount++;
      AppLogger.warning(
        'Drawing pull skipped after recoverable error; estado local preservado',
        tag: 'DrawingSync',
        error: error,
      );
      return DrawingSyncResult(
        updated: resultUpdates,
        conflicts: resultConflicts,
        errors: errorCount,
      );
    }

    for (var remote in remoteUpdates) {
      final local = await _localStore.getById(remote.id);

      if (local == null) {
        try {
          final newLocal = DrawingFeature(
            id: remote.id,
            geometry: remote.geometry,
            properties: remote.properties.copyWith(
              syncStatus: SyncStatus.synced,
            ),
          );
          await _localStore.insert(newLocal);
          resultUpdates.add(newLocal);
        } catch (error, stackTrace) {
          errorCount++;
          AppLogger.error(
            'Drawing pull persist failed on insert [id=${remote.id}]',
            tag: 'DrawingSync',
            error: error,
            stackTrace: stackTrace,
          );
        }
      } else {
        if (local.properties.syncStatus != SyncStatus.synced) {
          final conflict = DrawingFeature(
            id: local.id,
            geometry: local.geometry,
            properties: local.properties.copyWith(
              syncStatus: SyncStatus.conflict,
            ),
          );
          try {
            await _localStore.update(conflict);
            resultConflicts.add(conflict);
            AppLogger.warning(
              'Drawing conflict detected [id=${local.id}]',
              tag: 'DrawingSync',
            );
          } catch (error, stackTrace) {
            errorCount++;
            AppLogger.error(
              'Drawing conflict persist failed [id=${local.id}]',
              tag: 'DrawingSync',
              error: error,
              stackTrace: stackTrace,
            );
          }
        } else {
          if (remote.properties.updatedAt.isAfter(local.properties.updatedAt)) {
            try {
              final newLocal = DrawingFeature(
                id: remote.id,
                geometry: remote.geometry,
                properties: remote.properties.copyWith(
                  syncStatus: SyncStatus.synced,
                ),
              );
              await _localStore.update(newLocal);
              resultUpdates.add(newLocal);
            } catch (error, stackTrace) {
              errorCount++;
              AppLogger.error(
                'Drawing pull persist failed on update [id=${remote.id}]',
                tag: 'DrawingSync',
                error: error,
                stackTrace: stackTrace,
              );
            }
          }
        }
      }
    }

    AppLogger.debug(
      'Drawing sync finished '
      '[updated=${resultUpdates.length} conflicts=${resultConflicts.length} '
      'errors=$errorCount]',
      tag: 'DrawingSync',
    );

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
