import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_tokens.dart';

// ─── Constantes internas ──────────────────────────────────────────────────────

const _kTintRGBO = Color.fromRGBO(52, 199, 89, 1.0);

BoxDecoration _chartCard() => BoxDecoration(
      color: kClimaCard,
      borderRadius: BorderRadius.circular(20),
      boxShadow: const [
        BoxShadow(color: kClimaShadow, offset: Offset(0, 8), blurRadius: 24),
      ],
    );

// ─── Temperature Line Chart ───────────────────────────────────────────────────

/// Curva de temperatura das próximas N horas usando fl_chart LineChart.
class ClimaTemperatureLineChart extends StatelessWidget {
  final List<PrevisaoHoraria> previsoes;
  final ClimaUnidade unidade;

  const ClimaTemperatureLineChart({
    super.key,
    required this.previsoes,
    required this.unidade,
  });

  @override
  Widget build(BuildContext context) {
    if (previsoes.isEmpty) return const SizedBox.shrink();

    final spots = List.generate(
      previsoes.length,
      (i) => FlSpot(i.toDouble(), climaTempValue(previsoes[i].temperatura, unidade)),
    );

    final temps = previsoes.map((p) => climaTempValue(p.temperatura, unidade));
    final minY = temps.reduce(math.min) - 3;
    final maxY = temps.reduce(math.max) + 3;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 162,
        padding: const EdgeInsets.fromLTRB(12, 14, 16, 8),
        decoration: _chartCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '🌡️  Temperatura (${unidade == ClimaUnidade.celsius ? '°C' : '°F'})',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kClimaTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 18,
                        interval: 4,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= previsoes.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '${previsoes[i].hora.hour}h',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: kClimaTextTertiary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      curveSmoothness: 0.35,
                      color: _kTintRGBO,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: const LinearGradient(
                          colors: [
                            Color.fromRGBO(52, 199, 89, 0.18),
                            Color.fromRGBO(52, 199, 89, 0.0),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Precipitation Bar Chart ──────────────────────────────────────────────────

/// Barras de probabilidade de chuva (%) para as próximas N horas.
class ClimaPrecipitacaoBarChart extends StatelessWidget {
  final List<PrevisaoHoraria> previsoes;

  const ClimaPrecipitacaoBarChart({super.key, required this.previsoes});

  @override
  Widget build(BuildContext context) {
    if (previsoes.isEmpty) return const SizedBox.shrink();

    final barGroups = List.generate(
      previsoes.length,
      (i) => BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: previsoes[i].probabilidadeChuva.toDouble(),
            color: const Color.fromRGBO(52, 199, 89, 0.72),
            width: _barWidth(previsoes.length),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(3),
            ),
          ),
        ],
      ),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Container(
        height: 132,
        padding: const EdgeInsets.fromLTRB(12, 14, 16, 8),
        decoration: _chartCard(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '☔  Prob. de Chuva (%)',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kClimaTextSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: BarChart(
                BarChartData(
                  maxY: 100,
                  minY: 0,
                  barGroups: barGroups,
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 18,
                        interval: 4,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= previsoes.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            '${previsoes[i].hora.hour}h',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 10,
                              color: kClimaTextTertiary,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barTouchData: const BarTouchData(enabled: false),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static double _barWidth(int count) {
    if (count <= 12) return 14;
    if (count <= 24) return 8;
    return 5;
  }
}
