import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_charts.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_forecast_widgets.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_pulverizacao_card.dart';

void main() {
  group('ClimaPulverizacaoCard', () {
    testWidgets('exibe status FAVORÁVEL para condições ideais', (tester) async {
      final clima = _criarClima(
        temperatura: 24,
        umidade: 65,
        ventoVelocidade: 6,
        precipitacao: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClimaPulverizacaoCard(clima: clima),
          ),
        ),
      );

      expect(find.text('FAVORÁVEL'), findsOneWidget);
      expect(find.text('PULVERIZAÇÃO AGRÍCOLA'), findsOneWidget);
      expect(find.textContaining('ideais para pulverização'), findsOneWidget);
    });

    testWidgets('exibe status ATENÇÃO para vento moderado', (tester) async {
      final clima = _criarClima(
        temperatura: 25,
        umidade: 60,
        ventoVelocidade: 12,
        precipitacao: 0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClimaPulverizacaoCard(clima: clima),
          ),
        ),
      );

      expect(find.text('ATENÇÃO'), findsOneWidget);
      expect(find.textContaining('Vento moderado'), findsOneWidget);
    });

    testWidgets('exibe status DESFAVORÁVEL quando há chuva', (tester) async {
      final clima = _criarClima(
        temperatura: 22,
        umidade: 80,
        ventoVelocidade: 8,
        precipitacao: 3.5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClimaPulverizacaoCard(clima: clima),
          ),
        ),
      );

      expect(find.text('DESFAVORÁVEL'), findsOneWidget);
      expect(find.textContaining('Chuva detectada'), findsOneWidget);
    });
  });

  group('ClimaWeeklySummaryCard', () {
    testWidgets('calcula e exibe total acumulado e dias de chuva', (tester) async {
      final dias = List.generate(7, (i) {
        return PrevisaoDiaria(
          data: DateTime(2026, 6, 1).add(Duration(days: i)),
          tempMin: 18,
          tempMax: 29,
          precipitacao: i < 3 ? 10.0 : 0.0,
          probabilidadeChuva: i < 3 ? 80 : 10,
          ventoMedio: 10,
          condicao: 'Parcialmente nublado',
          condicaoCodigo: '02d',
          temAlerta: false,
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ClimaWeeklySummaryCard(previsoes: dias),
          ),
        ),
      );

      expect(find.text('VOLUME PREVISTO (7 DIAS)'), findsOneWidget);
      expect(find.text('30 mm'), findsOneWidget);
      expect(find.text('Previsão de chuva em 3 dos 7 dias'), findsOneWidget);
    });
  });

  group('ClimaPrecipitacaoBarChart', () {
    testWidgets('mostra total acumulado no cabeçalho quando houver chuva', (tester) async {
      final horas = List.generate(12, (i) {
        return PrevisaoHoraria(
          hora: DateTime(2026, 6, 1, i),
          temperatura: 22,
          precipitacao: 2.0,
          probabilidadeChuva: 60,
          condicao: 'Chuva leve',
          condicaoCodigo: '10d',
        );
      });

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ClimaPrecipitacaoBarChart(previsoes: horas),
            ),
          ),
        ),
      );

      expect(find.textContaining('total: 24 mm'), findsOneWidget);
    });
  });
}

ClimaAtual _criarClima({
  required double temperatura,
  required int umidade,
  required double ventoVelocidade,
  required double precipitacao,
}) {
  return ClimaAtual(
    temperatura: temperatura,
    sensacaoTermica: temperatura,
    condicao: 'Parcialmente Nublado',
    condicaoCodigo: '02d',
    ventoVelocidade: ventoVelocidade,
    ventoDirecao: 'NE',
    umidade: umidade,
    precipitacao: precipitacao,
    pressao: 1013,
    visibilidade: 10,
    coberturaNuvens: 20,
    indiceUV: 5,
    nascerSol: DateTime(2026, 6, 1, 6),
    porSol: DateTime(2026, 6, 1, 18),
    latitude: -12.97,
    longitude: -38.50,
    cidade: 'Salvador',
    atualizadoEm: DateTime(2026, 6, 1, 10),
  );
}
