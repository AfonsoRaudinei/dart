import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:soloforte_app/ui/theme/premium/design_tokens.dart';

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
    final accent = Theme.of(context).colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.premiumSurface,
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
          Text(
            'Sugestões por módulo',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: context.premiumTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ajuda a ver onde as melhorias estão concentradas.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: context.premiumTextSecondary,
            ),
          ),
          const SizedBox(height: 18),
          if (isUnavailable)
            SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'Não foi possível carregar estatísticas',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.premiumTextSecondary),
                ),
              ),
            )
          else if (visibleEntries.isEmpty)
            SizedBox(
              height: 140,
              child: Center(
                child: Text(
                  'Nenhuma sugestão enviada ainda',
                  style: TextStyle(color: context.premiumTextSecondary),
                ),
              ),
            )
          else
            SizedBox(
              height: 240,
              child: BarChart(_buildChartData(context, visibleEntries, accent)),
            ),
        ],
      ),
    );
  }

  BarChartData _buildChartData(
    BuildContext context,
    List<MapEntry<FeedbackModule, int>> entries,
    Color accent,
  ) {
    final maxValue = entries.fold<int>(
      0,
      (previous, entry) => math.max(previous, entry.value),
    );
    final maxY = math.max(1, maxValue + 1).toDouble();
    final textSecondary = context.premiumTextSecondary;
    final textPrimary = context.premiumTextPrimary;

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
          getTooltipColor: (_) => context.premiumSurface,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            return BarTooltipItem(
              rod.toY.toInt().toString(),
              TextStyle(
                color: textPrimary,
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
                style: TextStyle(color: textSecondary, fontSize: 11),
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
                  style: TextStyle(
                    color: textPrimary,
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
                color: accent,
                width: 20,
                borderRadius: BorderRadius.circular(6),
              ),
            ],
          ),
      ],
    );
  }
}
