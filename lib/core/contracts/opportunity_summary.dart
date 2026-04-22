/// DTO imutável — resumo de oportunidade comercial por categoria/cliente.
/// Zona neutra: sem Flutter, sem Riverpod, sem imports externos.
/// ADR-029 — IOpportunityLookup
class OpportunitySummary {
  const OpportunitySummary({
    required this.clientId,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.referenceValuePerHa,
    required this.closedPercent,
    required this.areaHa,
    required this.unit,
  });

  final String clientId;
  final String categoryId;
  final String categoryName;

  /// Cor da categoria em formato ARGB int.
  final int categoryColor;

  /// Valor de referência por hectare (valor_referencia de carteira_categorias).
  final double referenceValuePerHa;

  /// Percentual já fechado (soma dos closed_percent dos lançamentos do cliente).
  final double closedPercent;

  /// Área total do cliente em hectares (area_total da tabela clients).
  final double areaHa;

  /// Unidade: 'R$/ha' | 'ton/ha' | 'Big Bag' | 'Sacas 60k'
  final String unit;

  // ── Getters calculados (não persistidos) ──────────────────────────────────

  double get closedValuePerHa => referenceValuePerHa * closedPercent / 100;

  double get residualValuePerHa => referenceValuePerHa - closedValuePerHa;

  double get residualPercent => 100.0 - closedPercent;

  double get totalOpportunityValue => residualValuePerHa * areaHa;

  // ── copyWith ──────────────────────────────────────────────────────────────

  OpportunitySummary copyWith({
    String? clientId,
    String? categoryId,
    String? categoryName,
    int? categoryColor,
    double? referenceValuePerHa,
    double? closedPercent,
    double? areaHa,
    String? unit,
  }) {
    return OpportunitySummary(
      clientId: clientId ?? this.clientId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      categoryColor: categoryColor ?? this.categoryColor,
      referenceValuePerHa: referenceValuePerHa ?? this.referenceValuePerHa,
      closedPercent: closedPercent ?? this.closedPercent,
      areaHa: areaHa ?? this.areaHa,
      unit: unit ?? this.unit,
    );
  }
}
