import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/farm_map_download_controller.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/farm_map_download_plan.dart';

class _FakeOfflineTileCacheService extends OfflineTileCacheService {
  _FakeOfflineTileCacheService({required this.onPrefetch});

  final Future<OfflinePrefetchResult> Function() onPrefetch;

  @override
  Future<OfflinePrefetchResult> prefetchArea({
    required String layerKey,
    required String urlTemplate,
    required List<String> subdomains,
    required double south,
    required double west,
    required double north,
    required double east,
    required int minZoom,
    required int maxZoom,
    Map<String, String> headers = const {},
    void Function(OfflinePrefetchProgress progress)? onProgress,
    bool Function()? shouldCancel,
    bool forceRefresh = false,
    Future<http.Response> Function(
      http.Client client,
      Uri uri,
      Map<String, String> headers,
    )?
    tileHttpGet,
  }) {
    return onPrefetch();
  }
}

void main() {
  const farmId = 'farm-1';
  final plan = FarmMapDownloadPlan(
    south: -10,
    west: -48,
    north: -9,
    east: -47,
    minZoom: 14,
    maxZoom: 14,
    tileCount: 4,
  );

  test('cancel marca snackbar de cancelamento', () async {
    final container = ProviderContainer(
      overrides: [
        offlineTileCacheServiceProvider.overrideWithValue(
          _FakeOfflineTileCacheService(
            onPrefetch: () async {
              return const OfflinePrefetchResult(
                total: 4,
                processed: 1,
                downloaded: 0,
                skipped: 0,
                failed: 0,
                cancelled: true,
              );
            },
          ),
        ),
      ],
    );

    final notifier = container.read(farmMapDownloadControllerProvider.notifier);
    await notifier.startDownload(
      farmId: farmId,
      plan: plan,
      layerKey: 'layer',
      urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
      subdomains: const [],
      headers: const {},
    );

    final job = container.read(farmMapDownloadControllerProvider)[farmId];
    expect(job?.isRunning, isFalse);
    expect(job?.pendingSnackbar, 'Download do mapa cancelado.');
    container.dispose();
  });
}
