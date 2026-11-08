import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_info_edit_sheet.dart';

void main() {
  group('drawingInfoEditSheetBottomPadding', () {
    test('embedded no host do mapa não soma o teclado', () {
      expect(
        drawingInfoEditSheetBottomPadding(
          embedded: true,
          keyboardInset: 300,
        ),
        24,
      );
    });

    test('modal isolado soma viewInsets', () {
      expect(
        drawingInfoEditSheetBottomPadding(
          embedded: false,
          keyboardInset: 300,
        ),
        324,
      );
    });

    test('sem teclado mantém extra', () {
      expect(
        drawingInfoEditSheetBottomPadding(
          embedded: false,
          keyboardInset: 0,
        ),
        24,
      );
    });
  });
}
