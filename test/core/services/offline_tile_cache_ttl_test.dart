import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';

void main() {
  group('OfflineTileCacheService TTL', () {
    test('kOfflineTileCacheTtl é 180 dias', () {
      expect(kOfflineTileCacheTtl, const Duration(days: 180));
    });

    test('isAreaExpired retorna false dentro do prazo', () {
      final createdAt = DateTime.now().subtract(const Duration(days: 30));
      expect(OfflineTileCacheService.isAreaExpired(createdAt), isFalse);
    });

    test('isAreaExpired retorna true após 180 dias', () {
      final createdAt = DateTime.now().subtract(const Duration(days: 181));
      expect(OfflineTileCacheService.isAreaExpired(createdAt), isTrue);
    });

    test('isAreaExpired retorna false um dia antes do limite', () {
      final createdAt = DateTime.now().subtract(const Duration(days: 179));
      expect(OfflineTileCacheService.isAreaExpired(createdAt), isFalse);
    });
  });
}
