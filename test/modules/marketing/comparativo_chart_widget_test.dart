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
    final overviewText = tester.widget<Text>(find.text('Visão Geral'));

    expect(legendText.style?.color, SoloForteSheetTokens.inputText);
    expect(valueText.style?.color, SoloForteSheetTokens.inputText);
    expect(overviewText.style?.color, const Color(0xFF34C759));
  });
}
