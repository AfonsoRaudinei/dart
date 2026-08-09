import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/map/presentation/providers/map_location_mode_provider.dart';
import 'package:soloforte_app/ui/screens/map/handlers/map_location_handler.dart';

void main() {
  group('MapLocationHandler.mapRotationForMode', () {
    test('northLocked sempre trava norte em 0°', () {
      expect(
        MapLocationHandler.mapRotationForMode(
          mode: MapLocationMode.northLocked,
        ),
        0,
      );
    });

    test('following mantém norte em 0°', () {
      expect(
        MapLocationHandler.mapRotationForMode(
          mode: MapLocationMode.following,
        ),
        0,
      );
    });

    test('idle não altera rotação', () {
      expect(
        MapLocationHandler.mapRotationForMode(
          mode: MapLocationMode.idle,
        ),
        isNull,
      );
    });
  });
}
