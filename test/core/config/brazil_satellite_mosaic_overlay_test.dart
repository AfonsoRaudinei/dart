import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/brazil_satellite_mosaic_overlay.dart';

void main() {
  group('BrazilSatelliteMosaicOverlay', () {
    test('expõe layer WMS Brasil 3 meses', () {
      expect(BrazilSatelliteMosaicOverlay.layerName, 'mosaic-s2-brazil-3m');
      expect(BrazilSatelliteMosaicOverlay.wmsTimeIso, isNotEmpty);
    });

    test('quarterLabelFromTimeIso formata trimestre', () {
      expect(
        BrazilSatelliteMosaicOverlay.quarterLabelFromTimeIso(
          '2026-04-01T00:00:00.000Z',
        ),
        'abr–jun/2026',
      );
    });

    test('isWithinBounds cobre Sorriso e rejeita fora do Brasil', () {
      expect(BrazilSatelliteMosaicOverlay.isWithinBounds(-12.54, -55.72), isTrue);
      expect(BrazilSatelliteMosaicOverlay.isWithinBounds(40.0, -70.0), isFalse);
    });
  });
}
