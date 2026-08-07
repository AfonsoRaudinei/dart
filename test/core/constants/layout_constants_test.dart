import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';

void main() {
  group('kFabSafeArea vs AppShell', () {
    test('margem inferior bate com AppShell (padding.bottom + 16)', () {
      expect(kFabBottomMargin, 16.0);
    });

    test('reserva fixa = FAB 56 + margem 16 + clearance 4', () {
      expect(kFabHeight, 56.0);
      expect(kFabContentClearance, 4.0);
      expect(kFabSafeArea, 76.0);
      expect(
        kFabSafeArea,
        kFabHeight + kFabBottomMargin + kFabContentClearance,
      );
    });
  });
}
