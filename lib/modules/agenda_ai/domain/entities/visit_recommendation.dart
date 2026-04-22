/// Resultado de recomendação de visita para agenda.
class VisitRecommendation {
  final String clientId;
  final String clientName;
  final String city;
  final String categoryId;

  /// Motivo curto para exibição ao usuário.
  final String reason;

  const VisitRecommendation({
    required this.clientId,
    required this.clientName,
    required this.city,
    required this.categoryId,
    required this.reason,
  });
}
