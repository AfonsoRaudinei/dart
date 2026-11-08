import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/cerrado_satellite_overlay.dart';
import 'package:soloforte_app/core/domain/map_basemap_labels.dart';
import 'package:soloforte_app/core/domain/map_models.dart';

void main() {
  group('shortBasemapLayerLabel', () {
    test('standard', () {
      expect(shortBasemapLayerLabel(LayerType.standard), 'Mapa');
    });

    test('satellite', () {
      expect(shortBasemapLayerLabel(LayerType.satellite), 'Satélite');
    });

    test('satelliteUpdated com período STAC', () {
      expect(
        shortBasemapLayerLabel(
          LayerType.satelliteUpdated,
          inpeAcquisitionPeriod: 'jan/2024 – dez/2024',
        ),
        'Mapa INPE · jan/2024 – dez/2024',
      );
    });

    test('satelliteUpdated sem período usa fallback Cerrado', () {
      expect(
        shortBasemapLayerLabel(LayerType.satelliteUpdated),
        'Mapa INPE · ${CerradoSatelliteOverlay.acquisitionLabel}',
      );
    });
  });
}
