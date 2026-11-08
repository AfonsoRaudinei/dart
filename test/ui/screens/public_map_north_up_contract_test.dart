import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/map_config.dart';

/// Contrato de flags de gesto: mapa público permanece norte-acima;
/// mapa privado (MapCanvas) habilita rotação em modo explorar.
void main() {
  group('contrato flags de gesto (InteractiveFlag)', () {
    test('mapa público remove rotate e mantém pan/zoom', () {
      expect(
        InteractiveFlag.hasFlag(
          kPublicMapNorthUpInteractionFlags,
          InteractiveFlag.rotate,
        ),
        isFalse,
        reason: 'mapa público: gesto de rotação desabilitado',
      );
      expect(
        InteractiveFlag.hasFlag(
          kPublicMapNorthUpInteractionFlags,
          InteractiveFlag.drag,
        ),
        isTrue,
      );
      expect(
        InteractiveFlag.hasFlag(
          kPublicMapNorthUpInteractionFlags,
          InteractiveFlag.pinchZoom,
        ),
        isTrue,
      );
    });

    test('mapa privado (explorar) inclui rotate', () {
      expect(
        InteractiveFlag.hasFlag(
          kPrivateMapExploreInteractionFlags,
          InteractiveFlag.rotate,
        ),
        isTrue,
        reason: 'mapa privado idle: rotação com dois dedos habilitada',
      );
      expect(
        InteractiveFlag.hasFlag(
          kPrivateMapExploreInteractionFlags,
          InteractiveFlag.drag,
        ),
        isTrue,
      );
    });

    test('mapa privado (desenho/pin) desliga rotate e drag', () {
      expect(
        InteractiveFlag.hasFlag(
          kPrivateMapDrawingLockedInteractionFlags,
          InteractiveFlag.rotate,
        ),
        isFalse,
      );
      expect(
        InteractiveFlag.hasFlag(
          kPrivateMapDrawingLockedInteractionFlags,
          InteractiveFlag.drag,
        ),
        isFalse,
      );
      expect(
        InteractiveFlag.hasFlag(
          kPrivateMapDrawingLockedInteractionFlags,
          InteractiveFlag.pinchZoom,
        ),
        isTrue,
      );
    });

    test('público e privado explorar divergem na rotação', () {
      expect(
        kPublicMapNorthUpInteractionFlags,
        isNot(equals(kPrivateMapExploreInteractionFlags)),
      );
    });

    test('mapa privado explorar amortece gestos multi-dedo', () {
      expect(
        kPrivateMapExploreInteractionOptions.enableMultiFingerGestureRace,
        isTrue,
        reason: 'um gesto vence por vez — menos mapa “flutuando”',
      );
      expect(
        kPrivateMapExploreInteractionOptions.rotationThreshold,
        greaterThan(20),
      );
      expect(
        kPrivateMapExploreInteractionOptions.pinchMoveThreshold,
        greaterThan(40),
      );
    });
  });
}
