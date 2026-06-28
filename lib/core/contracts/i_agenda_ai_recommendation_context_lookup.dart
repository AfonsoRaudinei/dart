import 'agenda_ai_recommendation_context.dart';

/// Monta payload de recomendação IA sem acoplar agenda_ai a agenda/ ou carteira/.
/// ADR-046.
abstract interface class IAgendaAiRecommendationContextLookup {
  Future<AgendaAiRecommendationContext> buildForUser(String userId);
}
