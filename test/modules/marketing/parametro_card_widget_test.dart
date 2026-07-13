import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/parametro_comparativo.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/novo_case_antes_depois_section.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/parametro_card.dart';

void main() {
  testWidgets('ParametroCard propaga testemunha e teste do produto', (
    tester,
  ) async {
    ParametroComparativo? changed;
    var selected = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ParametroCard(
            parametro: const ParametroComparativo(
              id: 'param-1',
              titulo: '',
              testemunha: 0,
              teste: 0,
            ),
            selected: selected,
            onChanged: (parametro) => changed = parametro,
            onDelete: () {},
            onTap: () => selected = true,
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));

    await tester.enterText(fields.at(0), 'Número de Grãos');
    await tester.enterText(fields.at(1), '10');
    await tester.enterText(fields.at(2), '12');
    await tester.pump();

    expect(selected, isTrue);
    expect(changed, isNotNull);
    expect(changed!.titulo, 'Número de Grãos');
    expect(changed!.testemunha, 10);
    expect(changed!.teste, 12);
    expect(changed!.deltaPercent, 20);
  });

  testWidgets('Antes/Depois propaga o valor de Teste produto pelo parametro', (
    tester,
  ) async {
    ParametroComparativo current = const ParametroComparativo(
      id: 'param-1',
      titulo: '',
      testemunha: 0,
      teste: 0,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              return SingleChildScrollView(
                child: NovoCaseAntesDepoisSection(
                  fotoAntesUrl: 'https://example.com/antes.jpg',
                  fotoDepoisUrl: 'https://example.com/depois.jpg',
                  onFotoAntesChanged: (_) {},
                  onFotoDepoisChanged: (_) {},
                  parametros: [current],
                  parametroSelecionadoId: current.id,
                  onAddParametro: () {},
                  onSelectParametro: (_) {},
                  onParametroChanged: (parametro) {
                    setState(() => current = parametro);
                  },
                  onDeleteParametro: (_) {},
                ),
              );
            },
          ),
        ),
      ),
    );

    final fields = find.byType(TextFormField);
    expect(fields, findsNWidgets(4));

    await tester.enterText(fields.at(0), 'Vagens por Planta');
    await tester.enterText(fields.at(1), '38');
    await tester.enterText(fields.at(2), '47');
    await tester.pump();

    expect(current.titulo, 'Vagens por Planta');
    expect(current.testemunha, 38);
    expect(current.teste, 47);
    expect(current.deltaPercent, closeTo(23.68, 0.01));
  });
}
