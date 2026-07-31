import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/dashboard/domain/user_location_fix.dart';
import 'package:soloforte_app/modules/map/presentation/providers/map_location_mode_provider.dart';
import 'package:soloforte_app/ui/screens/map/handlers/map_location_handler.dart';

void main() {
  group('MapLocationHandler.mapRotationForMode', () {
    const fixWithHeading = UserLocationFix(
      position: LatLng(-10, -48),
      accuracyM: 5,
      headingDeg: 90,
    );
    const fixWithoutHeading = UserLocationFix(
      position: LatLng(-10, -48),
      accuracyM: 5,
    );

    test('northLocked sempre trava norte em 0°', () {
      expect(
        MapLocationHandler.mapRotationForMode(
          mode: MapLocationMode.northLocked,
          fix: fixWithHeading,
        ),
        0,
      );
    });

    test('following usa rumo GNSS quando disponível', () {
      expect(
        MapLocationHandler.mapRotationForMode(
          mode: MapLocationMode.following,
          fix: fixWithHeading,
        ),
        -90,
      );
    });

    test('following mantém rotação atual sem rumo válido', () {
      expect(
        MapLocationHandler.mapRotationForMode(
          mode: MapLocationMode.following,
          fix: fixWithoutHeading,
        ),
        isNull,
      );
    });

    test('idle não altera rotação', () {
      expect(
        MapLocationHandler.mapRotationForMode(
          mode: MapLocationMode.idle,
          fix: fixWithHeading,
        ),
        isNull,
      );
    });
  });
}
