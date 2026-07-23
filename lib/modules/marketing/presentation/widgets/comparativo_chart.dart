import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../core/ui/sheets/sheet_tokens.dart';
import '../../../../ui/theme/premium/design_tokens.dart';
import '../../domain/entities/parametro_comparativo.dart';

class ComparativoChart extends StatelessWidget {
  final List<ParametroComparativo> parametros;
  final String? selecionadoId;
  final ValueChanged<String?> onSelect;
  final String testemunhaLabel;
  final String testeLabel;

  const ComparativoChart({
    super.key,
    required this.parametros,
    required this.selecionadoId,
    required this.onSelect,
    this.testemunhaLabel = 'Testemunha',
    this.testeLabel = 'Produto',
  });

  @override
  Widget build(BuildContext context) {
    if (parametros.isEmpty) return const SizedBox.shrink();
    final selected = selecionadoId == null
        ? null
        : parametros.where((p) => p.id == selecionadoId).firstOrNull;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: SoloForteSheetTokens.inputBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: PremiumTokens.hairlineLight),
      ),
      child: selected == null
          ? _GeneralChart(parametros: parametros, onSelect: onSelect)
          : _SelectedChart(
              parametro: selected,
              testemunhaLabel: testemunhaLabel,
              testeLabel: testeLabel,
              onBack: () => onSelect(null),
            ),
    );
  }
}

class _GeneralChart extends StatelessWidget {
  final List<ParametroComparativo> parametros;
  final ValueChanged<String?> onSelect;

  const _GeneralChart({required this.parametros, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    final media =
        parametros.fold<double>(0, (sum, item) => sum + item.deltaPercent) /
        parametros.length;
    final maxAbs = parametros
        .map((item) => item.deltaPercent.abs())
        .fold<double>(1, (max, value) => value > max ? value : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Média de ganho: ${_signed(media)}%',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: SoloForteSheetTokens.inputText,
                ),
              ),
            ),
            TextButton(
              onPressed: () => onSelect(null),
              child: const Text(
                'Visão Geral',
                style: TextStyle(color: PremiumTokens.brandGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 180,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxAbs,
              minY: -maxAbs,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              barTouchData: BarTouchData(
                touchCallback: (event, response) {
                  if (!event.isInterestedForInteractions ||
                      response?.spot == null) {
                    return;
                  }
                  final index = response!.spot!.touchedBarGroupIndex;
                  if (index >= 0 && index < parametros.length) {
                    onSelect(parametros[index].id);
                  }
                },
              ),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 38,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= parametros.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          _short(parametros[index].titulo),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            color: SoloForteSheetTokens.inputText,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < parametros.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: parametros[i].deltaPercent,
                        width: 18,
                        borderRadius: BorderRadius.circular(6),
                        color: parametros[i].isNegativo
                            ? PremiumTokens.alertError
                            : PremiumTokens.brandGreen,
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...parametros.map(
          (item) => _LegendRow(
            label: item.titulo,
            value: item.testemunha == 0
                ? '--'
                : '${_signed(item.deltaPercent)}%',
            onTap: () => onSelect(item.id),
          ),
        ),
      ],
    );
  }
}

class _SelectedChart extends StatelessWidget {
  final ParametroComparativo parametro;
  final String testemunhaLabel;
  final String testeLabel;
  final VoidCallback onBack;

  const _SelectedChart({
    required this.parametro,
    required this.testemunhaLabel,
    required this.testeLabel,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final maxValue = [
      parametro.testemunha,
      parametro.teste,
    ].fold<double>(1, (max, value) => value > max ? value : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                parametro.titulo,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                  color: SoloForteSheetTokens.inputText,
                ),
              ),
            ),
            TextButton(
              onPressed: onBack,
              child: const Text(
                'Visão Geral',
                style: TextStyle(color: PremiumTokens.brandGreen),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 170,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxValue,
              minY: 0,
              gridData: const FlGridData(show: false),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                leftTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Text(
                          value.toInt() == 0
                              ? _short(testemunhaLabel)
                              : _short(testeLabel),
                          style: const TextStyle(
                            fontSize: 11,
                            color: SoloForteSheetTokens.inputText,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barGroups: [
                BarChartGroupData(
                  x: 0,
                  barRods: [
                    BarChartRodData(
                      toY: parametro.testemunha,
                      width: 28,
                      borderRadius: BorderRadius.circular(8),
                      color: const Color(0xFF8E8E93),
                    ),
                  ],
                ),
                BarChartGroupData(
                  x: 1,
                  barRods: [
                    BarChartRodData(
                      toY: parametro.teste,
                      width: 28,
                      borderRadius: BorderRadius.circular(8),
                      color: PremiumTokens.brandGreen,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Ganho: ${parametro.testemunha == 0 ? '--' : '${_signed(parametro.deltaPercent)}%'}',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: parametro.isNegativo
                ? PremiumTokens.alertError
                : PremiumTokens.brandGreen,
          ),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _LegendRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: SoloForteSheetTokens.inputText,
                  fontSize: 13,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: SoloForteSheetTokens.inputText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _signed(double value) {
  final formatted = value.toStringAsFixed(1).replaceAll('.', ',');
  return value >= 0 ? '+$formatted' : formatted;
}

String _short(String value) {
  if (value.length <= 10) return value;
  return '${value.substring(0, 9)}…';
}
