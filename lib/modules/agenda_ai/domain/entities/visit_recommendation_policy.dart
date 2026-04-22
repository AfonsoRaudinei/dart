/// Política de recomendação para cruzamento Agenda + Carteira.
///
/// Fase 1 (contrato): apenas regras de negócio e parâmetros fixos.
class VisitRecommendationPolicy {
  /// Top N candidatos retornados pelo motor de recomendação.
  final int topN;

  /// Priorização por mesma cidade do compromisso atual.
  final bool prioritizeSameCity;

  /// Distância máxima de fallback quando não houver candidato na mesma cidade.
  final double maxDistanceKm;

  /// Cooldown para evitar re-sugestão do mesmo cliente recém-visitado.
  final Duration cooldown;

  /// Janela da meta (ex.: anual).
  final MetaWindow metaWindow;

  const VisitRecommendationPolicy({
    required this.topN,
    required this.prioritizeSameCity,
    required this.maxDistanceKm,
    required this.cooldown,
    required this.metaWindow,
  });

  /// Política padrão definida com o usuário para o MVP.
  static const VisitRecommendationPolicy annualTop1 =
      VisitRecommendationPolicy(
        topN: 1,
        prioritizeSameCity: true,
        maxDistanceKm: 50,
        cooldown: Duration(days: 7),
        metaWindow: MetaWindow.annual,
      );
}

enum MetaWindow { annual }
