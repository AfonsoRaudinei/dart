import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/inpe_satellite_overlay_mode.dart';

void main() {
  group('InpeSatelliteOverlayMode', () {
    test('cycle percorre Off → Cerrado → Brasil → Off', () {
      expect(
        InpeSatelliteOverlayMode.off.cycle(),
        InpeSatelliteOverlayMode.cerradoInpe,
      );
      expect(
        InpeSatelliteOverlayMode.cerradoInpe.cycle(),
        InpeSatelliteOverlayMode.brazilMosaic,
      );
      expect(
        InpeSatelliteOverlayMode.brazilMosaic.cycle(),
        InpeSatelliteOverlayMode.off,
      );
    });

    test('persistência round-trip', () {
      for (final mode in InpeSatelliteOverlayMode.values) {
        expect(
          InpeSatelliteOverlayMode.fromPersisted(mode.persisted),
          mode,
        );
      }
    });
  });
}
