import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
import 'package:soloforte_app/core/services/offline_tile_cache_service.dart';
import 'package:soloforte_app/ui/components/map/widgets/map_layers.dart';

void main() {
  group('shouldShowCerradoSatelliteOverlay', () {
    test('exibe overlay quando online, satelite ativo e camera no Cerrado', () {
      expect(
        shouldShowCerradoSatelliteOverlay(
          activeLayer: LayerType.satellite,
          cerradoOverlayEnabled: true,
          isOnline: true,
          cameraLat: -12.54,
          cameraLng: -55.72,
        ),
        isTrue,
      );
    });

    test('nao exibe overlay offline para nao bloquear cache local', () {
      expect(
        shouldShowCerradoSatelliteOverlay(
          activeLayer: LayerType.satellite,
          cerradoOverlayEnabled: true,
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
          activeLayer: LayerType.satellite,
          cerradoOverlayEnabled: true,
          isOnline: true,
          cameraLat: -25.42,
          cameraLng: -49.27,
        ),
        isFalse,
      );
    });

    test('nao exibe overlay quando toggle INPE desativado', () {
      expect(
        shouldShowCerradoSatelliteOverlay(
          activeLayer: LayerType.satellite,
          cerradoOverlayEnabled: false,
          isOnline: true,
          cameraLat: -12.54,
          cameraLng: -55.72,
        ),
        isFalse,
      );
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
