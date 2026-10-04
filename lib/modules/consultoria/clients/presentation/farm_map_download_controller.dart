import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/farm_map_download_plan.dart';

part 'farm_map_download_controller.g.dart';

/// Estado visível do download de mapa por fazenda (job em segundo plano).
class FarmMapDownloadJob {
  final bool isRunning;
  final OfflinePrefetchProgress progress;
  final String? pendingSnackbar;

  const FarmMapDownloadJob({
    required this.isRunning,
    required this.progress,
    this.pendingSnackbar,
  });

  int get percent => (progress.fraction * 100).round();

  FarmMapDownloadJob copyWith({
    bool? isRunning,
    OfflinePrefetchProgress? progress,
    String? pendingSnackbar,
    bool clearSnackbar = false,
  }) {
    return FarmMapDownloadJob(
      isRunning: isRunning ?? this.isRunning,
      progress: progress ?? this.progress,
      pendingSnackbar:
          clearSnackbar ? null : (pendingSnackbar ?? this.pendingSnackbar),
    );
  }
}

@Riverpod(keepAlive: true)
class FarmMapDownloadController extends _$FarmMapDownloadController {
  final Map<String, bool> _cancelRequested = {};

  @override
  Map<String, FarmMapDownloadJob> build() => {};

  FarmMapDownloadJob? jobFor(String farmId) => state[farmId];

  bool isRunningFor(String farmId) => state[farmId]?.isRunning ?? false;

  void acknowledgeSnackbar(String farmId) {
    final job = state[farmId];
    if (job == null || job.pendingSnackbar == null) return;
    state = {
      ...state,
      farmId: job.copyWith(clearSnackbar: true),
    };
  }

  void cancel(String farmId) {
    _cancelRequested[farmId] = true;
  }

  Future<void> startDownload({
    required String farmId,
    required FarmMapDownloadPlan plan,
    required String layerKey,
    required String urlTemplate,
    required List<String> subdomains,
    required Map<String, String> headers,
  }) async {
    if (state[farmId]?.isRunning == true) return;

    _cancelRequested[farmId] = false;
    final initialProgress = OfflinePrefetchProgress(
      total: plan.tileCount,
      processed: 0,
      downloaded: 0,
      skipped: 0,
      failed: 0,
    );
    state = {
      ...state,
      farmId: FarmMapDownloadJob(
        isRunning: true,
        progress: initialProgress,
      ),
    };

    final cache = ref.read(offlineTileCacheServiceProvider);
    OfflinePrefetchResult result;
    try {
      result = await cache.prefetchArea(
        layerKey: layerKey,
        urlTemplate: urlTemplate,
        subdomains: subdomains,
        south: plan.south,
        west: plan.west,
        north: plan.north,
        east: plan.east,
        minZoom: plan.minZoom,
        maxZoom: plan.maxZoom,
        headers: headers,
        onProgress: (value) {
          final current = state[farmId];
          if (current == null || !current.isRunning) return;
          state = {
            ...state,
            farmId: current.copyWith(progress: value),
          };
        },
        shouldCancel: () => _cancelRequested[farmId] ?? false,
      );
    } on OfflineTileCacheException catch (error) {
      state = {
        ...state,
        farmId: FarmMapDownloadJob(
          isRunning: false,
          progress: initialProgress,
          pendingSnackbar: error.message,
        ),
      };
      return;
    } catch (_) {
      state = {
        ...state,
        farmId: FarmMapDownloadJob(
          isRunning: false,
          progress: initialProgress,
          pendingSnackbar: 'Falha ao baixar o mapa. Tente novamente.',
        ),
      };
      return;
    }

    final progress = OfflinePrefetchProgress(
      total: result.total,
      processed: result.processed,
      downloaded: result.downloaded,
      skipped: result.skipped,
      failed: result.failed,
    );

    if (!result.isComplete) {
      final message = result.cancelled
          ? 'Download do mapa cancelado.'
          : 'Download incompleto: ${result.failed} tile(s) falharam. Tente novamente.';
      state = {
        ...state,
        farmId: FarmMapDownloadJob(
          isRunning: false,
          progress: progress,
          pendingSnackbar: message,
        ),
      };
      return;
    }

    _registerOfflineArea(
      farmId: farmId,
      plan: plan,
      layerKey: layerKey,
      downloaded: result.downloaded,
    );

    state = {
      ...state,
      farmId: FarmMapDownloadJob(
        isRunning: false,
        progress: progress,
        pendingSnackbar:
            'Mapa da fazenda baixado: ${result.downloaded} tile(s) novo(s), '
            '${result.skipped} já existente(s).',
      ),
    };
  }

  void _registerOfflineArea({
    required String farmId,
    required FarmMapDownloadPlan plan,
    required String layerKey,
    required int downloaded,
  }) {
    final center = LatLng(
      (plan.south + plan.north) / 2,
      (plan.west + plan.east) / 2,
    );
    OfflineMapAreaConfig? existing;
    for (final area in ref.read(offlineMapAreasProvider)) {
      if (area.layerKey == layerKey &&
          area.covers(
            layerKey: layerKey,
            lat: center.latitude,
            lng: center.longitude,
            zoom: plan.minZoom.toDouble(),
          )) {
        existing = area;
        break;
      }
    }

    ref.read(offlineMapAreasProvider.notifier).updateArea(
          existing != null
              ? existing.mergeWithViewport(
                  south: plan.south,
                  west: plan.west,
                  north: plan.north,
                  east: plan.east,
                  minZoom: plan.minZoom.toDouble(),
                  maxZoom: plan.maxZoom.toDouble(),
                  createdAt:
                      downloaded > 0 ? DateTime.now() : existing.createdAt,
                )
              : OfflineMapAreaConfig(
                  id: 'farm:$farmId',
                  layerKey: layerKey,
                  south: plan.south,
                  west: plan.west,
                  north: plan.north,
                  east: plan.east,
                  minZoom: plan.minZoom.toDouble(),
                  maxZoom: plan.maxZoom.toDouble(),
                  createdAt: DateTime.now(),
                ),
        );
  }
}
