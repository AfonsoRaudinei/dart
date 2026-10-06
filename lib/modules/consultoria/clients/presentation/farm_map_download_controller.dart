import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/farm_map_download_plan.dart';

part 'farm_map_download_controller.g.dart';

/// Estado visível do download de mapa por fazenda (job em segundo plano).
class FarmMapDownloadJob {
  final bool isRunning;
  final bool isPaused;
  final OfflinePrefetchProgress progress;
  final String? pendingSnackbar;

  const FarmMapDownloadJob({
    required this.isRunning,
    this.isPaused = false,
    required this.progress,
    this.pendingSnackbar,
  });

  int get percent => (progress.fraction * 100).round();

  FarmMapDownloadJob copyWith({
    bool? isRunning,
    bool? isPaused,
    OfflinePrefetchProgress? progress,
    String? pendingSnackbar,
    bool clearSnackbar = false,
  }) {
    return FarmMapDownloadJob(
      isRunning: isRunning ?? this.isRunning,
      isPaused: isPaused ?? this.isPaused,
      progress: progress ?? this.progress,
      pendingSnackbar: clearSnackbar
          ? null
          : (pendingSnackbar ?? this.pendingSnackbar),
    );
  }
}

/// Snackbars novos após transição de estado (listener único no app shell).
List<({String farmId, String message})> farmMapDownloadNewSnackbars({
  Map<String, FarmMapDownloadJob>? previous,
  required Map<String, FarmMapDownloadJob> next,
}) {
  final pending = <({String farmId, String message})>[];
  for (final entry in next.entries) {
    final message = entry.value.pendingSnackbar;
    final previousMessage = previous?[entry.key]?.pendingSnackbar;
    if (message != null && message != previousMessage) {
      pending.add((farmId: entry.key, message: message));
    }
  }
  return pending;
}

@Riverpod(keepAlive: true)
class FarmMapDownloadController extends _$FarmMapDownloadController {
  final Map<String, bool> _cancelRequested = {};

  @override
  Map<String, FarmMapDownloadJob> build() {
    SessionController.registerLogoutInvalidation(
      key: 'farmMapDownloadControllerProvider',
      invalidate: (ref) {
        ref
            .read(farmMapDownloadControllerProvider.notifier)
            .cancelAllForLogout();
        ref.invalidate(farmMapDownloadControllerProvider);
      },
    );
    ref.listen(isOnlineProvider, (previous, next) {
      final online = next.asData?.value ?? true;
      final paused = !online;
      var changed = false;
      final updated = <String, FarmMapDownloadJob>{};
      for (final entry in state.entries) {
        final job = entry.value;
        if (job.isRunning && job.isPaused != paused) {
          changed = true;
          updated[entry.key] = job.copyWith(isPaused: paused);
        } else {
          updated[entry.key] = job;
        }
      }
      if (changed) state = updated;
    });
    return {};
  }

  FarmMapDownloadJob? jobFor(String farmId) => state[farmId];

  bool isRunningFor(String farmId) => state[farmId]?.isRunning ?? false;

  bool get _isOffline => !(ref.read(isOnlineProvider).asData?.value ?? true);

  void acknowledgeSnackbar(String farmId) {
    final job = state[farmId];
    if (job == null || job.pendingSnackbar == null) return;
    state = {...state, farmId: job.copyWith(clearSnackbar: true)};
  }

  void cancel(String farmId) {
    _cancelRequested[farmId] = true;
  }

  /// Usado no logout: pede cancelamento de todos os jobs em andamento.
  void cancelAllForLogout() {
    for (final farmId in {...state.keys, ..._cancelRequested.keys}) {
      _cancelRequested[farmId] = true;
    }
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
        isPaused: _isOffline,
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
            farmId: current.copyWith(progress: value, isPaused: _isOffline),
          };
        },
        shouldCancel: () => _cancelRequested[farmId] ?? false,
        shouldPause: () => _isOffline,
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
    final id = 'farm:$farmId';
    OfflineMapAreaConfig? existing;
    for (final area in ref.read(offlineMapAreasProvider)) {
      if (area.id == id) {
        existing = area;
        break;
      }
    }

    ref
        .read(offlineMapAreasProvider.notifier)
        .updateArea(
          existing != null
              ? existing.mergeWithViewport(
                  south: plan.south,
                  west: plan.west,
                  north: plan.north,
                  east: plan.east,
                  minZoom: plan.minZoom.toDouble(),
                  maxZoom: plan.maxZoom.toDouble(),
                  createdAt: downloaded > 0
                      ? DateTime.now()
                      : existing.createdAt,
                )
              : OfflineMapAreaConfig(
                  id: id,
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
