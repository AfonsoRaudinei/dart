import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_forecast_widgets.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

void main() {
  group('Clima forecast gradient cards', () {
    testWidgets('hour card exibe hora e temperatura com tokens de gradiente', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClimaHoraryContent(
              unidade: ClimaUnidade.celsius,
              previsoes: [
                PrevisaoHoraria(
                  hora: DateTime(2026, 7, 28, 14),
                  temperatura: 31,
                  precipitacao: 2,
                  probabilidadeChuva: 40,
                  condicao: 'Parcialmente nublado',
                  condicaoCodigo: '02d',
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final hourInCarousel = find.descendant(
        of: find.byType(ListView),
        matching: find.text('14h'),
      );
      expect(hourInCarousel, findsOneWidget);

      final hourLabel = tester.widget<Text>(hourInCarousel);
      expect(hourLabel.style?.color, kClimaOnGradientTextMuted);
      expect(hourLabel.style?.fontSize, 12);

      final tempInCarousel = find.descendant(
        of: find.byType(ListView),
        matching: find.text('31°'),
      );
      expect(tempInCarousel, findsOneWidget);
      final temp = tester.widget<Text>(tempInCarousel);
      expect(temp.style?.color, kClimaOnGradientText);
    });

    testWidgets('weekly card exibe temperaturas com tokens de gradiente', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClimaWeeklyContent(
                unidade: ClimaUnidade.celsius,
                previsoes: [
                  PrevisaoDiaria(
                    data: DateTime(2026, 7, 28),
                    tempMin: 22,
                    tempMax: 33,
                    precipitacao: 5,
                    ventoMedio: 8,
                    condicao: 'Chuvas isoladas',
                    condicaoCodigo: '10d',
                    temAlerta: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final temp = tester.widget<Text>(find.textContaining('33°'));
      expect(temp.style?.color, kClimaOnGradientText);

      final rain = tester.widget<Text>(find.textContaining('5 mm'));
      expect(rain.style?.color, kClimaOnGradientAccent);
    });
  });
}
