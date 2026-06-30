import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';

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
}
