import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/widgets/photo/soloforte_photo_picker_sheet.dart';

void main() {
  testWidgets('SoloFortePhotoPickerSheet mostra câmera, galeria e inversão vegetal',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SoloFortePhotoPickerSheet(label: 'Foto Antes'),
        ),
      ),
    );

    expect(find.text('Foto Antes'), findsOneWidget);
    expect(find.text('Câmera'), findsOneWidget);
    expect(find.text('Galeria'), findsOneWidget);
    expect(find.text('Inversão vegetal'), findsOneWidget);
  });
}
