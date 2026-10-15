import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_keyboard_inset.dart';

void main() {
  group('sheetStickyActionBottomPadding', () {
    test('com teclado no modal sobe a barra sticky', () {
      expect(
        sheetStickyActionBottomPadding(
          safeBottom: 34,
          keyboard: 300,
          liftForKeyboard: true,
          closedExtra: kFabSafeArea,
        ),
        312,
      );
    });

    test('sem teclado mantém safe-area + FAB', () {
      expect(
        sheetStickyActionBottomPadding(
          safeBottom: 34,
          keyboard: 0,
          liftForKeyboard: true,
          closedExtra: kFabSafeArea,
        ),
        34 + kFabSafeArea,
      );
    });

    test('host do mapa não soma teclado no footer', () {
      expect(
        sheetStickyActionBottomPadding(
          safeBottom: 34,
          keyboard: 300,
          liftForKeyboard: false,
          closedExtra: kFabSafeArea,
        ),
        34 + kFabSafeArea,
      );
    });
  });

  group('sheetFormKeyboardBottomPadding', () {
    test('soma viewInsets ao padding inferior dos search sheets', () {
      expect(
        sheetFormKeyboardBottomPadding(safeBottom: 20, keyboard: 300),
        336,
      );
    });

    test('sem teclado mantém extra + safe-area', () {
      expect(sheetFormKeyboardBottomPadding(safeBottom: 34, keyboard: 0), 50);
    });
  });
}
