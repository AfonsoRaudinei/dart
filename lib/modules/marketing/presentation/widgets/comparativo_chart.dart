import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/parametro_comparativo.dart';
import 'novo_case_form_helpers.dart';

const Color _testemunhaColor = Color(0xFFE11D48);
const Color _produtoColor = Color(0xFF2563EB);

/// Um gráfico por comparação: cada parâmetro é um par de colunas
/// (testemunha vermelha, produto azul), na mesma escala.
///
/// [selecionadoId] permanece na API para os callers. O desenho ignora a
/// seleção e sempre mostra todos os pares.
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
    final primary = novoCasePrimaryTextColor(context);
    final maxY = _maxValor(parametros);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: novoCaseInnerCardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxY,
                minY: 0,
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barTouchData: const BarTouchData(enabled: false),
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
                      reservedSize: 36,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 ||
                            index >= parametros.length ||
                            value != index.toDouble()) {
                          return const SizedBox.shrink();
                        }
                        final slot = meta.parentAxisSize / parametros.length;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: SizedBox(
                            width: slot,
                            child: Text(
                              parametros[index].titulo,
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
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
                      barsSpace: 4,
                      barRods: [
                        BarChartRodData(
                          toY: parametros[i].testemunha,
                          width: 16,
                          borderRadius: BorderRadius.circular(6),
                          color: _testemunhaColor,
                        ),
                        BarChartRodData(
                          toY: parametros[i].teste,
                          width: 16,
                          borderRadius: BorderRadius.circular(6),
                          color: _produtoColor,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendaItem(color: _testemunhaColor, label: testemunhaLabel),
              const SizedBox(width: 16),
              _LegendaItem(color: _produtoColor, label: testeLabel),
            ],
          ),
        ],
      ),
    );
  }
}

double _maxValor(List<ParametroComparativo> parametros) {
  var maxValue = 1.0;
  for (final item in parametros) {
    if (item.testemunha > maxValue) maxValue = item.testemunha;
    if (item.teste > maxValue) maxValue = item.teste;
  }
  return maxValue;
}

class _LegendaItem extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendaItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: novoCasePrimaryTextColor(context),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
