import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';

void main() {
  test(
    'offlineCoverageProvider retorna true quando metadata e tiles existem',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesService(await SharedPreferences.getInstance());
      const cacheService = _FakeOfflineTileCacheService(hasTiles: true);
      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefs),
          offlineTileCacheServiceProvider.overrideWithValue(cacheService),
        ],
      );
      addTearDown(container.dispose);

      final tileConfig = MapConfig.tileConfigForLayer(
        LayerType.satellite,
        mapTilerApiKey: MapConfig.kMapTilerApiKey,
      );
      final layerKey = cacheService.layerKeyFromTemplate(
        tileConfig.urlTemplate,
      );
      container
          .read(offlineMapAreasProvider.notifier)
          .addArea(
            OfflineMapAreaConfig(
              id: 'area-1',
              layerKey: layerKey,
              south: -10.2,
              west: -48.2,
              north: -9.8,
              east: -47.8,
              minZoom: 12,
              maxZoom: 18,
              createdAt: DateTime(2026, 7, 20),
            ),
          );

      final query = OfflineCoverageQuery(
        layerKey: layerKey,
        lat: -10.0,
        lng: -48.0,
        south: -10.1,
        west: -48.1,
        north: -9.9,
        east: -47.9,
        zoom: 14,
      );

      expect(
        await container.read(offlineCoverageProvider(query).future),
        isTrue,
      );
    },
  );

  test(
    'offlineCoverageProvider retorna false quando faltam tiles locais',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesService(await SharedPreferences.getInstance());
      const cacheService = _FakeOfflineTileCacheService(hasTiles: false);
      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefs),
          offlineTileCacheServiceProvider.overrideWithValue(cacheService),
        ],
      );
      addTearDown(container.dispose);

      final tileConfig = MapConfig.tileConfigForLayer(
        LayerType.satellite,
        mapTilerApiKey: MapConfig.kMapTilerApiKey,
      );
      final layerKey = cacheService.layerKeyFromTemplate(
        tileConfig.urlTemplate,
      );
      container
          .read(offlineMapAreasProvider.notifier)
          .addArea(
            OfflineMapAreaConfig(
              id: 'area-2',
              layerKey: layerKey,
              south: -10.2,
              west: -48.2,
              north: -9.8,
              east: -47.8,
              minZoom: 12,
              maxZoom: 18,
              createdAt: DateTime(2026, 7, 20),
            ),
          );

      final query = OfflineCoverageQuery(
        layerKey: layerKey,
        lat: -10.0,
        lng: -48.0,
        south: -10.1,
        west: -48.1,
        north: -9.9,
        east: -47.9,
        zoom: 14,
      );

      expect(
        await container.read(offlineCoverageProvider(query).future),
        isFalse,
      );
    },
  );
}

class _FakeOfflineTileCacheService extends OfflineTileCacheService {
  const _FakeOfflineTileCacheService({required this.hasTiles});

  final bool hasTiles;

  @override
  Future<bool> hasTilesForArea({
    required String layerKey,
    required double south,
    required double west,
    required double north,
    required double east,
    required int zoom,
  }) async {
    return hasTiles;
  }
}
