import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/geo/br_state_boundary_style.dart';

void main() {
  group('strokeWidthForZoom', () {
    test('segue 1.2 + zoom * 0.35 entre 2.0 e 6.0', () {
      expect(strokeWidthForZoom(0), 2.0);
      expect(strokeWidthForZoom(2), 2.0); // 1.9 → clamp mínimo 2.0
      expect(strokeWidthForZoom(2.3), closeTo(2.005, 0.001));
      expect(strokeWidthForZoom(10), closeTo(4.7, 0.001));
      expect(strokeWidthForZoom(13), closeTo(5.75, 0.001));
      expect(strokeWidthForZoom(20), 6.0);
    });
  });
}
