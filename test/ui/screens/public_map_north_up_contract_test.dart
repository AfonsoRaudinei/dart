import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';

/// Contrato norte-acima: mapa privado (MapCanvas) e mapa público usam a mesma
/// máscara de flags — rotate desabilitado.
///
/// Espelha:
/// - lib/ui/components/map/widgets/map_canvas.dart
/// - lib/ui/screens/public_map_screen.dart
void main() {
  group('contrato norte-acima (InteractiveFlag)', () {
    const northUpFlags = InteractiveFlag.all & ~InteractiveFlag.rotate;

    test('remove InteractiveFlag.rotate e mantém pan/zoom', () {
      expect(
        InteractiveFlag.hasFlag(northUpFlags, InteractiveFlag.rotate),
        isFalse,
        reason: 'gesto de rotação deve estar desabilitado',
      );
      expect(
        InteractiveFlag.hasFlag(northUpFlags, InteractiveFlag.drag),
        isTrue,
      );
      expect(
        InteractiveFlag.hasFlag(northUpFlags, InteractiveFlag.pinchZoom),
        isTrue,
      );
    });

    test('máscara pública espelha MapCanvas (all & ~rotate)', () {
      const publicFlags = InteractiveFlag.all & ~InteractiveFlag.rotate;
      const privateFlags = InteractiveFlag.all & ~InteractiveFlag.rotate;
      expect(publicFlags, privateFlags);
      expect(publicFlags, northUpFlags);
    });
  });
}
