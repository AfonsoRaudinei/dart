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
}
