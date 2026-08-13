import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:soloforte_app/modules/carteira/domain/oportunidades_aggregation.dart';

/// Card com donut de oportunidades (só apresentação).
class OportunidadesChartCard extends StatelessWidget {
  const OportunidadesChartCard({
    super.key,
    required this.slices,
    required this.title,
    required this.totalValue,
  });

  final List<OpportunityChartSlice> slices;
  final String title;
  final double totalValue;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    final sections = slices.isEmpty
        ? [
            PieChartSectionData(
              color: Colors.grey.shade300,
              value: 1,
              radius: 55,
              title: '',
            ),
          ]
        : slices
              .map(
                (s) => PieChartSectionData(
                  color: Color(s.colorArgb),
                  value: s.value > 0 ? s.value : 0.01,
                  radius: 55,
                  title: '',
                ),
              )
              .toList();

    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 50,
                  sectionsSpace: 2,
                  borderData: FlBorderData(show: false),
                  pieTouchData: PieTouchData(enabled: false),
                  startDegreeOffset: -90,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              'Total: ${_currencyFormat.format(totalValue)}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}

/// Legenda compacta das fatias (sem ações).
class OportunidadesChartLegend extends StatelessWidget {
  const OportunidadesChartLegend({super.key, required this.slices});

  final List<OpportunityChartSlice> slices;

  static final _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 0,
  );

  @override
  Widget build(BuildContext context) {
    if (slices.isEmpty) return const SizedBox.shrink();

    final total = slices.fold<double>(0.0, (sum, s) => sum + s.value);

    return Column(
      children: slices.map((s) {
        final pct = total > 0 ? s.value / total * 100 : 0.0;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Color(s.colorArgb),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                '${_currencyFormat.format(s.value)} · ${pct.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
