import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/ui/components/map/widgets/publication_actions_bottom_sheet.dart';

void main() {
  Future<void> openSheet(
    WidgetTester tester, {
    VoidCallback? onResultado,
    VoidCallback? onAntesDepois,
    VoidCallback? onAvaliacao,
    VoidCallback? onOcorrencia,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                onPressed: () {
                  PublicationActionsBottomSheet.show(
                    context: context,
                    onResultado: onResultado ?? () {},
                    onAntesDepois: onAntesDepois ?? () {},
                    onAvaliacao: onAvaliacao ?? () {},
                    onOcorrencia: onOcorrencia ?? () {},
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
  }

  testWidgets(
      'exibe ações de case e ocorrência; sem foto rápida nem inversão vegetal',
      (tester) async {
    var ocorrenciaTapped = false;

    await openSheet(
      tester,
      onOcorrencia: () => ocorrenciaTapped = true,
    );

    expect(find.text('Resultado'), findsOneWidget);
    expect(find.text('Antes/Depois'), findsOneWidget);
    expect(find.text('Avaliação'), findsOneWidget);
    expect(find.text('Ocorrência'), findsOneWidget);
    expect(find.text('Foto rápida'), findsNothing);
    expect(find.text('Inversão vegetal'), findsNothing);

    await tester.tap(find.text('Ocorrência'));
    await tester.pumpAndSettle();

    expect(ocorrenciaTapped, isTrue);
  });

  testWidgets('Resultado dispara callback no pós-frame após pop',
      (tester) async {
    var resultadoTapped = false;

    await openSheet(
      tester,
      onResultado: () => resultadoTapped = true,
    );

    await tester.tap(find.text('Resultado'));
    await tester.pump();

    expect(resultadoTapped, isTrue);
  });

  testWidgets('Antes/Depois dispara callback no pós-frame após pop',
      (tester) async {
    var antesDepoisTapped = false;

    await openSheet(
      tester,
      onAntesDepois: () => antesDepoisTapped = true,
    );

    await tester.tap(find.text('Antes/Depois'));
    await tester.pump();

    expect(antesDepoisTapped, isTrue);
  });

  testWidgets('Avaliação dispara callback no pós-frame após pop',
      (tester) async {
    var avaliacaoTapped = false;

    await openSheet(
      tester,
      onAvaliacao: () => avaliacaoTapped = true,
    );

    await tester.tap(find.text('Avaliação'));
    await tester.pump();

    expect(avaliacaoTapped, isTrue);
  });
}
