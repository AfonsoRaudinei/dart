/// Contexto mínimo para recomendação de visita comercial.
///
/// Este contrato modela o que o motor precisa para sugerir cliente
/// com foco em fechamento de meta por categoria.
class VisitRecommendationContext {
  /// Consultor logado.
  final String consultantId;

  /// Cidade do compromisso atual (ou contexto da rota do dia).
  final String? currentCity;

  /// Coordenadas do contexto atual (opcional para fallback por raio).
  final GeoPoint? currentLocation;

  /// Categoria alvo com maior gap de meta no momento.
  final String targetCategoryId;

  /// Valor da meta anual da categoria (R$).
  final double annualTargetValue;

  /// Valor já realizado no ano para a categoria (R$).
  final double annualAchievedValue;

  /// Clientes elegíveis para sugestão.
  final List<ClientOpportunitySnapshot> opportunities;

  const VisitRecommendationContext({
    required this.consultantId,
    required this.currentCity,
    required this.currentLocation,
    required this.targetCategoryId,
    required this.annualTargetValue,
    required this.annualAchievedValue,
    required this.opportunities,
  });

  double get targetGapValue {
    final gap = annualTargetValue - annualAchievedValue;
    return gap <= 0 ? 0 : gap;
  }

  double get achievedPercent {
    if (annualTargetValue <= 0) return 0;
    final pct = (annualAchievedValue / annualTargetValue) * 100;
    return pct.clamp(0, 100);
  }
}

class ClientOpportunitySnapshot {
  final String clientId;
  final String clientName;
  final String city;

  /// Coordenada opcional; usada no fallback por distância.
  final GeoPoint? location;

  /// Categoria avaliada na oportunidade.
  final String categoryId;

  /// Percentual fechado do cliente nesta categoria (0-100).
  final double categoryProgressPercent;

  /// Valor fechado em R$ para a categoria no cliente.
  final double categoryAchievedValue;

  /// Data da última visita (se existir), usada no cooldown.
  final DateTime? lastVisitAt;

  const ClientOpportunitySnapshot({
    required this.clientId,
    required this.clientName,
    required this.city,
    required this.location,
    required this.categoryId,
    required this.categoryProgressPercent,
    required this.categoryAchievedValue,
    required this.lastVisitAt,
  });
}

class GeoPoint {
  final double lat;
  final double lon;

  const GeoPoint({required this.lat, required this.lon});
}
