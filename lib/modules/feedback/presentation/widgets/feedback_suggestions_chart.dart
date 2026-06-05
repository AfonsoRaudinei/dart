import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/feedback_module.dart';

class FeedbackSuggestionsChart extends StatelessWidget {
  final Map<FeedbackModule, int> suggestionsByModule;
  final bool isUnavailable;

  const FeedbackSuggestionsChart({
    super.key,
    required this.suggestionsByModule,
    this.isUnavailable = false,
  });

  @override
  Widget build(BuildContext context) {
    final entries =
        suggestionsByModule.entries.where((entry) => entry.value > 0).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final visibleEntries = entries.take(6).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sugestões por módulo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1D1D1F),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajuda a ver onde as melhorias estão concentradas.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: const Color(0xFF6B7280)),
          ),
          const SizedBox(height: 18),
          if (isUnavailable)
            const SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'Não foi possível carregar estatísticas',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            )
          else if (visibleEntries.isEmpty)
            const SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'Nenhuma sugestão enviada ainda',
                  style: TextStyle(color: Color(0xFF6B7280)),
                ),
              ),
            )
          else
            SizedBox(
              height: 240,
              child: BarChart(_buildChartData(visibleEntries)),
            ),
        ],
      ),
    );
  }

  BarChartData _buildChartData(List<MapEntry<FeedbackModule, int>> entries) {
    final maxValue = entries.fold<int>(
      0,
      (previous, entry) => math.max(previous, entry.value),
    );
    final maxY = math.max(1, maxValue + 1).toDouble();

    return BarChartData(
      alignment: BarChartAlignment.spaceAround,
      maxY: maxY,
      barTouchData: BarTouchData(
        enabled: true,
        handleBuiltInTouches: false,
        touchTooltipData: BarTouchTooltipData(
          tooltipMargin: 4,
          tooltipPadding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 4,
          ),
          tooltipBorderRadius: BorderRadius.circular(8),
          fitInsideHorizontally: true,
          fitInsideVertically: true,
          getTooltipColor: (_) => const Color(0xFF111827),
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              rod.toY.toInt().toString(),
              const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            );
          },
        ),
      ),
      borderData: FlBorderData(show: false),
      gridData: const FlGridData(
        drawVerticalLine: false,
        drawHorizontalLine: true,
      ),
      titlesData: FlTitlesData(
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value % 1 != 0) return const SizedBox.shrink();
              return Text(
                value.toInt().toString(),
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 11),
              );
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 44,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index < 0 || index >= entries.length) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  entries[index].key.shortLabel,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ),
      barGroups: [
        for (var index = 0; index < entries.length; index++)
          BarChartGroupData(
            x: index,
            showingTooltipIndicators: const [0],
            barRods: [
              BarChartRodData(
                toY: entries[index].value.toDouble(),
                color: const Color(0xFF0F62FE),
                width: 20,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
      ],
    );
  }
}
