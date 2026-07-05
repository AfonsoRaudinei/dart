/// Contexto neutro para recomendações do assistente agenda_ai. ADR-046.
class AgendaAiClientOpportunity {
  const AgendaAiClientOpportunity({
    required this.clientId,
    required this.clientName,
    required this.categoryId,
    required this.categoryProgressPercent,
    required this.categoryAchievedValue,
    this.lastVisitAt,
  });

  final String clientId;
  final String clientName;
  final String categoryId;
  final double categoryProgressPercent;
  final double categoryAchievedValue;
  final DateTime? lastVisitAt;
}

class AgendaAiRecommendationContext {
  const AgendaAiRecommendationContext({
    required this.userId,
    required this.targetCategoryId,
    required this.annualTargetValue,
    required this.annualAchievedValue,
    required this.opportunities,
  });

  final String userId;
  final String targetCategoryId;
  final double annualTargetValue;
  final double annualAchievedValue;
  final List<AgendaAiClientOpportunity> opportunities;
}

/// GPS/cidade capturados no mapa antes de abrir o assistente. ADR-046.
class AgendaAiLaunchContext {
  const AgendaAiLaunchContext({
    this.latitude,
    this.longitude,
    this.city,
  });

  final double? latitude;
  final double? longitude;
  final String? city;

  bool get hasLocation => latitude != null && longitude != null;

  Map<String, dynamic>? get locationPayload {
    if (!hasLocation) return null;
    return {'lat': latitude, 'lon': longitude};
  }
}

class AgendaAiSuggestedVisitRequest {
  const AgendaAiSuggestedVisitRequest({
    required this.clientId,
    required this.clientName,
    required this.titulo,
    required this.dataInicioPlanejada,
    required this.dataFimPlanejada,
    this.currentUserId,
  });

  final String clientId;
  final String clientName;
  final String titulo;
  final DateTime dataInicioPlanejada;
  final DateTime dataFimPlanejada;
  final String? currentUserId;
}
