import 'package:soloforte_app/core/contracts/opportunity_summary.dart';

/// Fatia do gráfico de oportunidades (apenas agregação de UI).
/// Não altera fórmulas de [OpportunitySummary] (ADR-029).
class OpportunityChartSlice {
  const OpportunityChartSlice({
    required this.id,
    required this.label,
    required this.colorArgb,
    required this.value,
  });

  final String id;
  final String label;
  final int colorArgb;
  final double value;
}

/// Agrega valores já calculados — não recalcula residual/área.
List<OpportunityChartSlice> aggregateOpportunitiesByCategory(
  Iterable<OpportunitySummary> opportunities,
) {
  final byCategory = <String, OpportunityChartSlice>{};

  for (final op in opportunities) {
    final value = op.totalOpportunityValue;
    if (value <= 0) continue;
    final existing = byCategory[op.categoryId];
    if (existing == null) {
      byCategory[op.categoryId] = OpportunityChartSlice(
        id: op.categoryId,
        label: op.categoryName,
        colorArgb: op.categoryColor,
        value: value,
      );
    } else {
      byCategory[op.categoryId] = OpportunityChartSlice(
        id: existing.id,
        label: existing.label,
        colorArgb: existing.colorArgb,
        value: existing.value + value,
      );
    }
  }

  final slices = byCategory.values.toList()
    ..sort((a, b) => b.value.compareTo(a.value));
  return slices;
}

/// Agrega por produtor — [colorArgb] já resolvido pelo caller (UI).
List<OpportunityChartSlice> aggregateOpportunitiesByProducer(
  Iterable<({String clientId, String clientName, int colorArgb, double total})>
  producers,
) {
  final slices =
      producers
          .where((p) => p.total > 0)
          .map(
            (p) => OpportunityChartSlice(
              id: p.clientId,
              label: p.clientName,
              colorArgb: p.colorArgb,
              value: p.total,
            ),
          )
          .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
  return slices;
}

double sumOpportunityValues(Iterable<OpportunitySummary> opportunities) {
  return opportunities.fold<double>(
    0.0,
    (sum, op) => sum + op.totalOpportunityValue,
  );
}
