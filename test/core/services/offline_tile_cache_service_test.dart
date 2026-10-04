import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';

import '../../support/path_provider_test_bindings.dart';

void main() {
  const service = OfflineTileCacheService();

  group('OfflineTileCacheService.estimateTileCount', () {
    test('calcula um tile para bbox contido no zoom zero', () {
      final total = service.estimateTileCount(
        south: -10,
        west: -50,
        north: -9,
        east: -49,
        minZoom: 0,
        maxZoom: 0,
      );

      expect(total, 1);
    });

    test('rejeita intervalo de zoom invertido', () {
      expect(
        () => service.estimateTileCount(
          south: -10,
          west: -50,
          north: -9,
          east: -49,
          minZoom: 18,
          maxZoom: 12,
        ),
        throwsA(isA<OfflineTileCacheException>()),
      );
    });

    test('rejeita latitude fora do Web Mercator', () {
      expect(
        () => service.estimateTileCount(
          south: -90,
          west: -50,
          north: -9,
          east: -49,
          minZoom: 12,
          maxZoom: 12,
        ),
        throwsA(isA<OfflineTileCacheException>()),
      );
    });
  });

  group('OfflineTileCacheService.prefetchArea concurrency', () {
    test('baixa tiles em paralelo até prefetchConcurrency', () async {
      installPathProviderTestBindings();
      var inFlight = 0;
      var maxInFlight = 0;

      Future<http.Response> fakeGet(
        http.Client client,
        Uri uri,
        Map<String, String> headers,
      ) async {
        inFlight++;
        maxInFlight = math.max(maxInFlight, inFlight);
        await Future<void>.delayed(const Duration(milliseconds: 15));
        inFlight--;
        return http.Response.bytes(const [1, 2, 3], 200);
      }

      const south = -10.0;
      const west = -50.0;
      const north = -9.0;
      const east = -47.0;
      const zoom = 9;

      final total = service.estimateTileCount(
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: zoom,
        maxZoom: zoom,
      );
      expect(total, greaterThan(OfflineTileCacheService.prefetchConcurrency));

      final result = await service.prefetchArea(
        layerKey: 'test-concurrency',
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: zoom,
        maxZoom: zoom,
        forceRefresh: true,
        tileHttpGet: fakeGet,
      );

      expect(result.isComplete, isTrue);
      expect(maxInFlight, greaterThan(1));
      expect(
        maxInFlight,
        lessThanOrEqualTo(OfflineTileCacheService.prefetchConcurrency),
      );
    });
  });

  group('OfflineTileCacheService.prefetchArea resume', () {
    const south = -10.0;
    const west = -50.0;
    const north = -9.9;
    const east = -49.9;
    const zoom = 0;

    test('GET que nunca completa respeita timeout e não trava', () async {
      installPathProviderTestBindings();
      final started = DateTime.now();
      final result = await service.prefetchArea(
        layerKey: 'test-timeout-${started.microsecondsSinceEpoch}',
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: zoom,
        maxZoom: zoom,
        forceRefresh: true,
        requestTimeout: const Duration(milliseconds: 40),
        pausePoll: const Duration(milliseconds: 5),
        tileHttpGet: (client, uri, headers) => Completer<http.Response>().future,
      );

      expect(DateTime.now().difference(started).inSeconds, lessThan(3));
      expect(result.cancelled, isFalse);
      expect(result.failed, result.total);
      expect(result.isComplete, isFalse);
    });

    test('segundo prefetch pula tiles já gravados no disco', () async {
      installPathProviderTestBindings();
      final layerKey = 'test-skip-${DateTime.now().microsecondsSinceEpoch}';

      Future<http.Response> okGet(
        http.Client client,
        Uri uri,
        Map<String, String> headers,
      ) async {
        return http.Response.bytes(const [1, 2, 3], 200);
      }

      final first = await service.prefetchArea(
        layerKey: layerKey,
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: zoom,
        maxZoom: zoom,
        tileHttpGet: okGet,
      );
      expect(first.isComplete, isTrue);
      expect(first.downloaded, first.total);

      final second = await service.prefetchArea(
        layerKey: layerKey,
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: zoom,
        maxZoom: zoom,
        tileHttpGet: okGet,
      );
      expect(second.isComplete, isTrue);
      expect(second.skipped, second.total);
      expect(second.downloaded, 0);
      expect(second.failed, 0);
    });

    test('shouldPause não incrementa failed e retoma depois', () async {
      installPathProviderTestBindings();
      var paused = false;
      var downloads = 0;
      final pauseHit = Completer<void>();

      Future<http.Response> okGet(
        http.Client client,
        Uri uri,
        Map<String, String> headers,
      ) async {
        downloads++;
        if (downloads == 1 && !pauseHit.isCompleted) {
          paused = true;
          pauseHit.complete();
        }
        return http.Response.bytes(const [1, 2, 3], 200);
      }

      final future = service.prefetchArea(
        layerKey: 'test-pause-${DateTime.now().microsecondsSinceEpoch}',
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        south: -10,
        west: -50,
        north: -9,
        east: -47,
        minZoom: 8,
        maxZoom: 8,
        forceRefresh: true,
        pausePoll: const Duration(milliseconds: 5),
        shouldPause: () => paused,
        tileHttpGet: okGet,
      );

      await pauseHit.future.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(const Duration(milliseconds: 30));
      paused = false;
      final result = await future;

      expect(result.failed, 0);
      expect(result.isComplete, isTrue);
      expect(result.cancelled, isFalse);
    });

    test('falha HTTP com pause logo depois não conta failed', () async {
      installPathProviderTestBindings();
      var paused = false;
      var calls = 0;

      Future<http.Response> flakyGet(
        http.Client client,
        Uri uri,
        Map<String, String> headers,
      ) async {
        calls++;
        if (calls == 1) {
          Future<void>.delayed(const Duration(milliseconds: 30), () {
            paused = true;
          });
          throw Exception('socket');
        }
        return http.Response.bytes(const [1, 2, 3], 200);
      }

      final future = service.prefetchArea(
        layerKey: 'test-fail-grace-${DateTime.now().microsecondsSinceEpoch}',
        urlTemplate: 'https://example.test/{z}/{x}/{y}.png',
        subdomains: const [],
        south: south,
        west: west,
        north: north,
        east: east,
        minZoom: zoom,
        maxZoom: zoom,
        forceRefresh: true,
        pausePoll: const Duration(milliseconds: 20),
        shouldPause: () => paused,
        tileHttpGet: flakyGet,
      );

      await Future<void>.delayed(const Duration(milliseconds: 120));
      paused = false;
      final result = await future;
      expect(result.failed, 0);
      expect(result.isComplete, isTrue);
    });
  });
}
