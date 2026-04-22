import '../entities/visit_recommendation.dart';
import '../entities/visit_recommendation_context.dart';
import '../entities/visit_recommendation_policy.dart';

/// Contrato para motor de recomendação Agenda + Carteira.
///
/// Implementações futuras:
/// - determinística (MVP)
/// - híbrida com explicação via LLM
abstract class IVisitRecommendationEngine {
  Future<List<VisitRecommendation>> recommend({
    required VisitRecommendationContext context,
    required VisitRecommendationPolicy policy,
  });
}
