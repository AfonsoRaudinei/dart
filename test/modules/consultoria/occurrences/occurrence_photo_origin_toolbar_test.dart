import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/widgets/photo/soloforte_photo_picker_sheet.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/widgets/occurrence_form_widgets.dart';

void main() {
  testWidgets('OccurrencePhotoOriginToolbar expõe galeria, câmera e inversão vegetal',
      (tester) async {
    SoloFortePhotoPickerOrigin? selected;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: OccurrencePhotoOriginToolbar(
            accent: Colors.green,
            onOriginSelected: (origin) => selected = origin,
          ),
        ),
      ),
    );

    expect(find.byTooltip('Galeria'), findsOneWidget);
    expect(find.byTooltip('Câmera'), findsOneWidget);
    expect(find.byTooltip('Inversão vegetal'), findsOneWidget);

    await tester.tap(find.byTooltip('Inversão vegetal'));
    expect(selected, SoloFortePhotoPickerOrigin.vegetal);
  });
}
