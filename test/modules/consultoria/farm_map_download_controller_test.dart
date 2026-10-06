import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/providers/connectivity_provider.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/farm_map_download_controller.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/farm_map_download_plan.dart';

class _FakeOfflineTileCacheService extends OfflineTileCacheService {
  _FakeOfflineTileCacheService({required this.onPrefetch});

  final Future<OfflinePrefetchResult> Function(
    bool Function()? shouldCancel,
    bool Function()? shouldPause,
  )
  onPrefetch;

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
    bool Function()? shouldPause,
    bool forceRefresh = false,
    Duration? requestTimeout,
    Duration? pausePoll,
    Future<http.Response> Function(
      http.Client client,
      Uri uri,
      Map<String, String> headers,
    )?
    tileHttpGet,
  }) {
    return onPrefetch(shouldCancel, shouldPause);
  }
}

void main() {
  late PreferencesService preferences;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    preferences = PreferencesService(await SharedPreferences.getInstance());
  });

  const farmId = 'farm-1';
  const plan = FarmMapDownloadPlan(
    south: -10,
    west: -48,
    north: -9,
    east: -47,
    minZoom: 14,
    maxZoom: 14,
    tileCount: 4,
  );

  group('FarmMapDownloadController', () {
    Override alwaysOnline() => isOnlineProvider.overrideWith((ref) async* {
      yield true;
    });

    test('cancel marca snackbar de cancelamento', () async {
      final container = ProviderContainer(
        overrides: [
          alwaysOnline(),
          offlineTileCacheServiceProvider.overrideWithValue(
            _FakeOfflineTileCacheService(
              onPrefetch: (_, __) async {
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

      final notifier = container.read(
        farmMapDownloadControllerProvider.notifier,
      );
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

    test('cancelAllForLogout sinaliza shouldCancel durante prefetch', () async {
      bool Function()? liveCancel;
      final container = ProviderContainer(
        overrides: [
          alwaysOnline(),
          offlineTileCacheServiceProvider.overrideWithValue(
            _FakeOfflineTileCacheService(
              onPrefetch: (shouldCancel, _) async {
                liveCancel = shouldCancel;
                await Future<void>.delayed(const Duration(milliseconds: 20));
                return OfflinePrefetchResult(
                  total: 4,
                  processed: 1,
                  downloaded: 0,
                  skipped: 0,
                  failed: 0,
                  cancelled: shouldCancel?.call() ?? false,
                );
              },
            ),
          ),
        ],
      );

      container.read(farmMapDownloadControllerProvider);
      final notifier = container.read(
        farmMapDownloadControllerProvider.notifier,
      );
      final future = notifier.startDownload(
        farmId: farmId,
        plan: plan,
        layerKey: 'layer',
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        headers: const {},
      );
      await Future<void>.delayed(Duration.zero);
      notifier.cancelAllForLogout();
      expect(liveCancel?.call(), isTrue);
      await future;
      container.dispose();
    });

    test('logout invalidação zera jobs após cancelAllForLogout', () async {
      final container = ProviderContainer(
        overrides: [
          alwaysOnline(),
          preferencesServiceProvider.overrideWithValue(preferences),
          offlineTileCacheServiceProvider.overrideWithValue(
            _FakeOfflineTileCacheService(
              onPrefetch: (_, __) async {
                return const OfflinePrefetchResult(
                  total: 4,
                  processed: 4,
                  downloaded: 4,
                  skipped: 0,
                  failed: 0,
                  cancelled: false,
                );
              },
            ),
          ),
        ],
      );

      container.read(farmMapDownloadControllerProvider);
      final notifier = container.read(
        farmMapDownloadControllerProvider.notifier,
      );
      await notifier.startDownload(
        farmId: farmId,
        plan: plan,
        layerKey: 'layer',
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        headers: const {},
      );

      expect(container.read(farmMapDownloadControllerProvider), isNotEmpty);
      notifier.cancelAllForLogout();
      container.invalidate(farmMapDownloadControllerProvider);
      expect(container.read(farmMapDownloadControllerProvider), isEmpty);
      container.dispose();
    });

    test('pausa offline não dispara snackbar de incompleto', () async {
      final connectivity = StreamController<bool>.broadcast();
      addTearDown(connectivity.close);
      final enteredPause = Completer<void>();
      final container = ProviderContainer(
        overrides: [
          isOnlineProvider.overrideWith((ref) async* {
            yield true;
            yield* connectivity.stream;
          }),
          offlineTileCacheServiceProvider.overrideWithValue(
            _FakeOfflineTileCacheService(
              onPrefetch: (shouldCancel, shouldPause) async {
                while (!(shouldPause?.call() ?? false)) {
                  if (shouldCancel?.call() ?? false) {
                    return const OfflinePrefetchResult(
                      total: 4,
                      processed: 1,
                      downloaded: 0,
                      skipped: 0,
                      failed: 0,
                      cancelled: true,
                    );
                  }
                  await Future<void>.delayed(const Duration(milliseconds: 5));
                }
                if (!enteredPause.isCompleted) enteredPause.complete();
                while (shouldPause?.call() ?? false) {
                  if (shouldCancel?.call() ?? false) {
                    return const OfflinePrefetchResult(
                      total: 4,
                      processed: 1,
                      downloaded: 0,
                      skipped: 0,
                      failed: 0,
                      cancelled: true,
                    );
                  }
                  await Future<void>.delayed(const Duration(milliseconds: 5));
                }
                return const OfflinePrefetchResult(
                  total: 4,
                  processed: 4,
                  downloaded: 4,
                  skipped: 0,
                  failed: 0,
                  cancelled: false,
                );
              },
            ),
          ),
        ],
      );

      container.read(farmMapDownloadControllerProvider);
      final notifier = container.read(
        farmMapDownloadControllerProvider.notifier,
      );
      final future = notifier.startDownload(
        farmId: farmId,
        plan: plan,
        layerKey: 'layer',
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        headers: const {},
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
      connectivity.add(false);
      await enteredPause.future.timeout(const Duration(seconds: 2));
      final paused = container.read(farmMapDownloadControllerProvider)[farmId];
      expect(paused?.isRunning, isTrue);
      expect(paused?.pendingSnackbar, isNull);
      notifier.cancel(farmId);
      await future;
      final job = container.read(farmMapDownloadControllerProvider)[farmId];
      expect(job?.pendingSnackbar, isNot(contains('incompleto')));
      container.dispose();
    });

    test(
      'duas fazendas vizinhas registram farm:A e farm:B, sem fundir ids',
      () async {
        final container = ProviderContainer(
          overrides: [
            alwaysOnline(),
            preferencesServiceProvider.overrideWithValue(preferences),
            offlineTileCacheServiceProvider.overrideWithValue(
              _FakeOfflineTileCacheService(
                onPrefetch: (_, __) async {
                  return const OfflinePrefetchResult(
                    total: 4,
                    processed: 4,
                    downloaded: 4,
                    skipped: 0,
                    failed: 0,
                    cancelled: false,
                  );
                },
              ),
            ),
          ],
        );
        addTearDown(container.dispose);
        container.read(offlineMapAreasProvider.notifier).clear();

        final notifier = container.read(
          farmMapDownloadControllerProvider.notifier,
        );
        const planA = FarmMapDownloadPlan(
          south: -10,
          west: -48,
          north: -9,
          east: -47,
          minZoom: 14,
          maxZoom: 14,
          tileCount: 4,
        );
        // Centro de B (-9.3, -47.3) cai no bbox de A.
        const planB = FarmMapDownloadPlan(
          south: -9.6,
          west: -47.6,
          north: -9.0,
          east: -47.0,
          minZoom: 14,
          maxZoom: 14,
          tileCount: 4,
        );

        await notifier.startDownload(
          farmId: 'A',
          plan: planA,
          layerKey: 'layer',
          urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
          subdomains: const [],
          headers: const {},
        );
        await notifier.startDownload(
          farmId: 'B',
          plan: planB,
          layerKey: 'layer',
          urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
          subdomains: const [],
          headers: const {},
        );

        final areas = container.read(offlineMapAreasProvider);
        expect(areas.map((a) => a.id), ['farm:A', 'farm:B']);
        expect(areas.firstWhere((a) => a.id == 'farm:A').south, planA.south);
      },
    );
  });

  group('farmMapDownloadNewSnackbars', () {
    test('detecta pending snackbar sem FarmMapDownloadButton montado', () {
      const progress = OfflinePrefetchProgress(
        total: 4,
        processed: 4,
        downloaded: 4,
        skipped: 0,
        failed: 0,
      );
      final previous = {
        farmId: const FarmMapDownloadJob(isRunning: true, progress: progress),
      };
      final next = {
        farmId: const FarmMapDownloadJob(
          isRunning: false,
          progress: progress,
          pendingSnackbar: 'Mapa da fazenda baixado.',
        ),
      };

      final items = farmMapDownloadNewSnackbars(previous: previous, next: next);
      expect(items, hasLength(1));
      expect(items.first.farmId, farmId);
      expect(items.first.message, 'Mapa da fazenda baixado.');
    });

    test('ignora mensagem já exibida', () {
      const progress = OfflinePrefetchProgress(
        total: 4,
        processed: 4,
        downloaded: 4,
        skipped: 0,
        failed: 0,
      );
      const job = FarmMapDownloadJob(
        isRunning: false,
        progress: progress,
        pendingSnackbar: 'Mapa da fazenda baixado.',
      );
      final items = farmMapDownloadNewSnackbars(
        previous: {farmId: job},
        next: {farmId: job},
      );
      expect(items, isEmpty);
    });
  });
}
