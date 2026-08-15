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

    test('following e northLocked nunca usam rumo GNSS (sempre 0°)', () {
      // Regressão do course-up: Position.heading parado deixava norte
      // nas laterais. Ambos os modos ativos devem forçar 0°.
      for (final mode in [
        MapLocationMode.following,
        MapLocationMode.northLocked,
      ]) {
        expect(
          MapLocationHandler.mapRotationForMode(mode: mode),
          0,
          reason: '$mode deve travar norte em 0°',
        );
      }
    });
  });
}
