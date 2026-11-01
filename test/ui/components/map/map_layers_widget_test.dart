import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_layers.dart';

void main() {
  group('shouldShowCerradoSatelliteOverlay', () {
    test('exibe overlay quando online, satelliteUpdated e camera no Cerrado', () {
      expect(
        shouldShowCerradoSatelliteOverlay(
          activeLayer: LayerType.satelliteUpdated,
          isOnline: true,
          cameraLat: -12.54,
          cameraLng: -55.72,
        ),
        isTrue,
      );
    });

    test('nao exibe overlay offline — base MapTiler segue via TileLayer', () {
      expect(
        shouldShowCerradoSatelliteOverlay(
          activeLayer: LayerType.satelliteUpdated,
          isOnline: false,
          cameraLat: -12.54,
          cameraLng: -55.72,
        ),
        isFalse,
      );
    });

    test('nao exibe overlay fora do bbox do Cerrado', () {
      expect(
        shouldShowCerradoSatelliteOverlay(
          activeLayer: LayerType.satelliteUpdated,
          isOnline: true,
          cameraLat: -25.42,
          cameraLng: -49.27,
        ),
        isFalse,
      );
    });

    test('nao exibe overlay no modo satellite MapTiler only', () {
      expect(
        shouldShowCerradoSatelliteOverlay(
          activeLayer: LayerType.satellite,
          isOnline: true,
          cameraLat: -12.54,
          cameraLng: -55.72,
        ),
        isFalse,
      );
    });
  });

  group('shouldShowBrazilSatelliteMosaicOverlay', () {
    test('exibe mosaico Brasil fora do Cerrado com satelliteUpdated online', () {
      expect(
        shouldShowBrazilSatelliteMosaicOverlay(
          activeLayer: LayerType.satelliteUpdated,
          isOnline: true,
          cameraLat: -25.42,
          cameraLng: -49.27,
        ),
        isTrue,
      );
    });

    test('nao exibe mosaico offline', () {
      expect(
        shouldShowBrazilSatelliteMosaicOverlay(
          activeLayer: LayerType.satelliteUpdated,
          isOnline: false,
          cameraLat: -25.42,
          cameraLng: -49.27,
        ),
        isFalse,
      );
    });

    test('nao exibe Cerrado e Brasil juntos', () {
      const lat = -12.54;
      const lng = -55.72;
      final cerrado = shouldShowCerradoSatelliteOverlay(
        activeLayer: LayerType.satelliteUpdated,
        isOnline: true,
        cameraLat: lat,
        cameraLng: lng,
      );
      final brasil = shouldShowBrazilSatelliteMosaicOverlay(
        activeLayer: LayerType.satelliteUpdated,
        isOnline: true,
        cameraLat: lat,
        cameraLng: lng,
      );
      expect(cerrado, isTrue);
      expect(brasil, isFalse);
    });
  });

  group('satelliteUpdated basemap fallback', () {
    test('tileConfigForVisibleLayer usa MapTiler satelite como satellite', () {
      const key = 'test-key';
      final updated = MapConfig.tileConfigForVisibleLayer(
        LayerType.satelliteUpdated,
        satelliteLabelsEnabled: false,
        mapTilerApiKey: key,
      );
      final satellite = MapConfig.tileConfigForVisibleLayer(
        LayerType.satellite,
        satelliteLabelsEnabled: false,
        mapTilerApiKey: key,
      );
      expect(updated.urlTemplate, satellite.urlTemplate);
      expect(updated.attribution, satellite.attribution);
    });
  });

  group('shouldServePersistedOfflineTile', () {
    test('tile gravado permanece no mapa mesmo com internet', () {
      expect(
        OfflineTileCacheService.shouldServePersistedOfflineTile(
          localTileExists: true,
        ),
        isTrue,
      );
    });

    test('tile ausente segue para a rede', () {
      expect(
        OfflineTileCacheService.shouldServePersistedOfflineTile(
          localTileExists: false,
        ),
        isFalse,
      );
    });
  });
}
