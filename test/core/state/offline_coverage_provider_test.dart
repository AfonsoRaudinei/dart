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

  test(
    'centro em A com viewport maior cobre pela interseção, não pela câmera',
    () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = PreferencesService(await SharedPreferences.getInstance());
      const farmSouth = -10.0;
      const farmWest = -48.0;
      const farmNorth = -9.0;
      const farmEast = -47.0;
      final cacheService = _RecordingOfflineTileCacheService(
        coveredSouth: farmSouth,
        coveredWest: farmWest,
        coveredNorth: farmNorth,
        coveredEast: farmEast,
      );
      final container = ProviderContainer(
        overrides: [
          preferencesServiceProvider.overrideWithValue(prefs),
          offlineTileCacheServiceProvider.overrideWithValue(cacheService),
        ],
      );
      addTearDown(container.dispose);

      container
          .read(offlineMapAreasProvider.notifier)
          .addArea(
            OfflineMapAreaConfig(
              id: 'farm:A',
              layerKey: 'sat',
              south: farmSouth,
              west: farmWest,
              north: farmNorth,
              east: farmEast,
              minZoom: 12,
              maxZoom: 18,
              createdAt: DateTime(2026, 10, 5),
            ),
          );

      const query = OfflineCoverageQuery(
        layerKey: 'sat',
        lat: -9.5,
        lng: -47.5,
        south: -10.5,
        west: -48.5,
        north: -8.5,
        east: -46.5,
        zoom: 14,
      );

      expect(
        await container.read(offlineCoverageProvider(query).future),
        isTrue,
      );
      expect(cacheService.lastBounds, isNotNull);
      expect(cacheService.lastBounds!.south, farmSouth);
      expect(cacheService.lastBounds!.west, farmWest);
      expect(cacheService.lastBounds!.north, farmNorth);
      expect(cacheService.lastBounds!.east, farmEast);
    },
  );

  test('centro fora de qualquer área registrada retorna false', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    final cacheService = _RecordingOfflineTileCacheService(
      coveredSouth: -10,
      coveredWest: -48,
      coveredNorth: -9,
      coveredEast: -47,
    );
    final container = ProviderContainer(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
        offlineTileCacheServiceProvider.overrideWithValue(cacheService),
      ],
    );
    addTearDown(container.dispose);

    container
        .read(offlineMapAreasProvider.notifier)
        .addArea(
          OfflineMapAreaConfig(
            id: 'farm:A',
            layerKey: 'sat',
            south: -10,
            west: -48,
            north: -9,
            east: -47,
            minZoom: 12,
            maxZoom: 18,
            createdAt: DateTime(2026, 10, 5),
          ),
        );

    final query = const OfflineCoverageQuery(
      layerKey: 'sat',
      lat: -8.0,
      lng: -46.0,
      south: -8.5,
      west: -46.5,
      north: -7.5,
      east: -45.5,
      zoom: 14,
    );

    expect(
      await container.read(offlineCoverageProvider(query).future),
      isFalse,
    );
    expect(cacheService.lastBounds, isNull);
  });
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

/// Tiles só existem no bbox da fazenda. Query que extrapola o bbox falha —
/// o mesmo all-or-nothing que apagava o mapa do outro produtor na câmera.
class _RecordingOfflineTileCacheService extends OfflineTileCacheService {
  _RecordingOfflineTileCacheService({
    required this.coveredSouth,
    required this.coveredWest,
    required this.coveredNorth,
    required this.coveredEast,
  });

  final double coveredSouth;
  final double coveredWest;
  final double coveredNorth;
  final double coveredEast;
  ({double south, double west, double north, double east})? lastBounds;

  @override
  Future<bool> hasTilesForArea({
    required String layerKey,
    required double south,
    required double west,
    required double north,
    required double east,
    required int zoom,
  }) async {
    lastBounds = (south: south, west: west, north: north, east: east);
    final extendsOutside =
        south < coveredSouth ||
        west < coveredWest ||
        north > coveredNorth ||
        east > coveredEast;
    return !extendsOutside;
  }
}
