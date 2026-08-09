import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_sheet_form_padding.dart';

void main() {
  test('clientSheetFormPaddingFromMedia soma viewInsets ao padding inferior', () {
    const media = MediaQueryData(
      padding: EdgeInsets.only(bottom: 20),
      viewInsets: EdgeInsets.only(bottom: 300),
    );

    final padding = clientSheetFormPaddingFromMedia(media);

    expect(padding.bottom, 344);
    expect(padding.left, 24);
    expect(padding.top, 12);
  });

  test('clientSheetFormPaddingFromMedia sem teclado mantém safe-area + 24', () {
    const media = MediaQueryData(
      padding: EdgeInsets.only(bottom: 34),
    );

    final padding = clientSheetFormPaddingFromMedia(media);

    expect(padding.bottom, 58);
  });
}
