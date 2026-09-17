import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/widgets/publication_actions_bottom_sheet.dart';

void main() {
  testWidgets('exibe ações de case e ocorrência; sem foto rápida nem inversão vegetal',
      (tester) async {
    var ocorrenciaTapped = false;
    var areaVisitadaTapped = false;

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
                    onAreaVisitada: () => areaVisitadaTapped = true,
                    onOcorrencia: () => ocorrenciaTapped = true,
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

    expect(find.text('Resultado'), findsOneWidget);
    expect(find.text('Antes/Depois'), findsOneWidget);
    expect(find.text('Avaliação'), findsOneWidget);
    expect(find.text('Área Visitada'), findsOneWidget);
    expect(find.text('Ocorrência'), findsOneWidget);
    expect(find.text('Foto rápida'), findsNothing);
    expect(find.text('Inversão vegetal'), findsNothing);

    await tester.tap(find.text('Área Visitada'));
    await tester.pumpAndSettle();
    expect(areaVisitadaTapped, isTrue);

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ocorrência'));
    await tester.pumpAndSettle();

    expect(ocorrenciaTapped, isTrue);
  });
}
