import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_tokens.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/parametro_comparativo.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/comparativo_chart.dart';

void main() {
  testWidgets('ComparativoChart mostra todos os pares no sheet escuro', (
    tester,
  ) async {
    final sheetTheme = ThemeData(
      brightness: Brightness.dark,
      extensions: const [SoloForteThemeExtension(themeId: 'black')],
      colorScheme: const ColorScheme.dark(primary: Color(0xFF1428A0)),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: sheetTheme,
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
              ParametroComparativo(
                id: 'vagens',
                titulo: 'vagens',
                testemunha: 10,
                teste: 12,
              ),
            ],
            selecionadoId: 'graos',
            onSelect: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('grãos'), findsWidgets);
    expect(find.text('vagens'), findsWidgets);
    expect(find.text('Testemunha'), findsOneWidget);
    expect(find.text('Produto'), findsOneWidget);
    expect(find.text('Visão Geral'), findsNothing);
    expect(find.text('Resultado Geral'), findsNothing);
    expect(find.text('+12,5%'), findsNothing);

    final chart = tester.widget<BarChart>(find.byType(BarChart));
    expect(chart.data.maxY, 45);
    expect(chart.data.barGroups, hasLength(2));
    expect(chart.data.barGroups[0].barRods[0].toY, 40);
    expect(chart.data.barGroups[0].barRods[0].color, const Color(0xFFE11D48));
    expect(chart.data.barGroups[0].barRods[1].toY, 45);
    expect(chart.data.barGroups[0].barRods[1].color, const Color(0xFF2563EB));
    expect(chart.data.barGroups[1].barRods[0].toY, 10);
    expect(chart.data.barGroups[1].barRods[1].toY, 12);

    final title = tester.widget<Text>(find.text('grãos').first);
    final onDark = SoloForteSheetVisuals.of(
      tester.element(find.byType(ComparativoChart)),
    ).inputText;
    expect(title.style?.color, onDark);
  });
}
