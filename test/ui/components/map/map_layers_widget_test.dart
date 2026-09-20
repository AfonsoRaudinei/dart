import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/domain/map_models.dart';
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

  group('shouldUseOfflineTileLayer', () {
    test(
      'prioriza cache local quando viewport offline esta coberta e conectividade inicial nao confirmou online',
      () {
        expect(
          shouldUseOfflineTileLayer(
            hasOfflineCoverageForViewport: true,
            offlineTemplate: '/tmp/offline_tiles/{z}/{x}/{y}.tile',
            isOnline: null,
          ),
          isTrue,
        );
      },
    );

    test('usa cache local quando o app inicia explicitamente offline', () {
      expect(
        shouldUseOfflineTileLayer(
          hasOfflineCoverageForViewport: true,
          offlineTemplate: '/tmp/offline_tiles/{z}/{x}/{y}.tile',
          isOnline: false,
        ),
        isTrue,
      );
    });

    test('nao usa cache local sem cobertura offline da viewport', () {
      expect(
        shouldUseOfflineTileLayer(
          hasOfflineCoverageForViewport: false,
          offlineTemplate: '/tmp/offline_tiles/{z}/{x}/{y}.tile',
          isOnline: false,
        ),
        isFalse,
      );
    });

    test('nao usa cache local quando o app confirmou estado online', () {
      expect(
        shouldUseOfflineTileLayer(
          hasOfflineCoverageForViewport: true,
          offlineTemplate: '/tmp/offline_tiles/{z}/{x}/{y}.tile',
          isOnline: true,
        ),
        isFalse,
      );
    });
  });
}
