import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/parametro_comparativo.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/comparativo_chart.dart';

void main() {
  testWidgets('ComparativoChart usa texto legivel no sheet escuro', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: SoloForteSheetTokens.sheetBackground,
          body: ComparativoChart(
            parametros: const [
              ParametroComparativo(
                id: 'graos',
                titulo: 'grãos',
                testemunha: 40,
                teste: 45,
              ),
            ],
            selecionadoId: null,
            onSelect: (_) {},
          ),
        ),
      ),
    );

    final legendText = tester.widget<Text>(find.text('grãos').last);
    final valueText = tester.widget<Text>(find.text('+12,5%'));

    expect(legendText.style?.color, SoloForteSheetTokens.inputText);
    expect(valueText.style?.color, SoloForteSheetTokens.inputText);

    // Na visão geral não existe botão "Visão Geral": ele não levava a lugar
    // nenhum. Só o gráfico de um parâmetro tem a volta.
    expect(find.text('Visão Geral'), findsNothing);
    expect(find.text('Média de ganho: +12,5%'), findsNothing);
  });

  testWidgets('ComparativoChart: parametro selecionado tem volta', (
    tester,
  ) async {
    String? selecionado = 'graos';

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: SoloForteSheetTokens.sheetBackground,
          body: ComparativoChart(
            parametros: const [
              ParametroComparativo(
                id: 'graos',
                titulo: 'grãos',
                testemunha: 40,
                teste: 45,
              ),
            ],
            selecionadoId: selecionado,
            onSelect: (id) => selecionado = id,
          ),
        ),
      ),
    );

    final overviewText = tester.widget<Text>(find.text('Visão Geral'));
    expect(overviewText.style?.color, const Color(0xFF34C759));

    await tester.tap(find.text('Visão Geral'));
    expect(selecionado, isNull);
  });
}
