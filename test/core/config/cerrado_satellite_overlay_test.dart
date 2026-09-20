import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/cerrado_satellite_overlay.dart';
import 'package:soloforte_app/core/config/satellite_freshness_policy.dart';

void main() {
  group('CerradoSatelliteOverlay', () {
    test('expõe configuração WMS INPE esperada', () {
      expect(
        CerradoSatelliteOverlay.wmsBaseUrl,
        'https://data.inpe.br/bdc/geoserver/mosaics/ows',
      );
      expect(CerradoSatelliteOverlay.layerName, 'mosaic-s2-cerrado-2m');
      expect(CerradoSatelliteOverlay.acquisitionLabel, 'nov/2023 – ago/2024');
      expect(CerradoSatelliteOverlay.defaultOpacity, 1.0);
      expect(CerradoSatelliteOverlay.wmsTransparent, isTrue);
    });

    test('tileBounds cobre bbox do Cerrado', () {
      final bounds = CerradoSatelliteOverlay.tileBounds;
      expect(bounds.southWest.latitude, kCerradoSouth);
      expect(bounds.southWest.longitude, kCerradoWest);
      expect(bounds.northEast.latitude, kCerradoNorth);
      expect(bounds.northEast.longitude, kCerradoEast);
    });

    test('isWithinBounds segue bbox do Cerrado', () {
      expect(CerradoSatelliteOverlay.isWithinBounds(-12.54, -55.72), isTrue);
      expect(CerradoSatelliteOverlay.isWithinBounds(-25.42, -49.27), isFalse);
    });
  });
}
