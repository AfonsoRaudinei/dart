import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/widgets/publication_actions_bottom_sheet.dart';

void main() {
  testWidgets('exibe e aciona inversão vegetal', (tester) async {
    var tapped = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  PublicationActionsBottomSheet.show(
                    context: context,
                    onResultado: () {},
                    onAntesDepois: () {},
                    onAvaliacao: () {},
                    onOcorrencia: () {},
                    onFotoRapida: () {},
                    onInversaoVegetal: () => tapped = true,
                  );
                },
                child: const Text('Abrir'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    expect(find.text('Inversão vegetal'), findsOneWidget);

    await tester.tap(find.text('Inversão vegetal'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
  });
}
