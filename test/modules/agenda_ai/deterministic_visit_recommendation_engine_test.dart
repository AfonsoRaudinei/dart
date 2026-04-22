import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda_ai/domain/entities/visit_recommendation_context.dart';
import 'package:soloforte_app/modules/agenda_ai/domain/entities/visit_recommendation_policy.dart';
import 'package:soloforte_app/modules/agenda_ai/domain/services/deterministic_visit_recommendation_engine.dart';

void main() {
  group('DeterministicVisitRecommendationEngine', () {
    const engine = DeterministicVisitRecommendationEngine();

    test('prioriza cliente da mesma cidade', () async {
      const context = VisitRecommendationContext(
        consultantId: 'u1',
        currentCity: 'Brejinho',
        currentLocation: GeoPoint(lat: -6.185, lon: -35.359),
        targetCategoryId: 'cat_quimico',
        annualTargetValue: 100000,
        annualAchievedValue: 50000,
        opportunities: [
          ClientOpportunitySnapshot(
            clientId: 'c1',
            clientName: 'Augusto',
            city: 'Brejinho',
            location: GeoPoint(lat: -6.188, lon: -35.352),
            categoryId: 'cat_quimico',
            categoryProgressPercent: 50,
            categoryAchievedValue: 5000,
            lastVisitAt: null,
          ),
          ClientOpportunitySnapshot(
            clientId: 'c2',
            clientName: 'Jose',
            city: 'Santa Cruz',
            location: GeoPoint(lat: -6.229, lon: -36.022),
            categoryId: 'cat_quimico',
            categoryProgressPercent: 20,
            categoryAchievedValue: 2000,
            lastVisitAt: null,
          ),
        ],
      );

      final result = await engine.recommend(
        context: context,
        policy: VisitRecommendationPolicy.annualTop1,
      );

      expect(result, isNotEmpty);
      expect(result.first.clientId, 'c1');
    });

    test('aplica cooldown de 7 dias', () async {
      final now = DateTime.now();

      final context = VisitRecommendationContext(
        consultantId: 'u1',
        currentCity: 'Brejinho',
        currentLocation: const GeoPoint(lat: -6.185, lon: -35.359),
        targetCategoryId: 'cat_quimico',
        annualTargetValue: 100000,
        annualAchievedValue: 60000,
        opportunities: [
          ClientOpportunitySnapshot(
            clientId: 'c1',
            clientName: 'Recente',
            city: 'Brejinho',
            location: const GeoPoint(lat: -6.188, lon: -35.352),
            categoryId: 'cat_quimico',
            categoryProgressPercent: 10,
            categoryAchievedValue: 1000,
            lastVisitAt: now.subtract(const Duration(days: 2)),
          ),
          ClientOpportunitySnapshot(
            clientId: 'c2',
            clientName: 'Elegivel',
            city: 'Brejinho',
            location: const GeoPoint(lat: -6.190, lon: -35.350),
            categoryId: 'cat_quimico',
            categoryProgressPercent: 30,
            categoryAchievedValue: 3000,
            lastVisitAt: now.subtract(const Duration(days: 10)),
          ),
        ],
      );

      final result = await engine.recommend(
        context: context,
        policy: VisitRecommendationPolicy.annualTop1,
      );

      expect(result, isNotEmpty);
      expect(result.first.clientId, 'c2');
    });

    test('fallback por raio de 50km quando não há mesma cidade', () async {
      const context = VisitRecommendationContext(
        consultantId: 'u1',
        currentCity: 'Brejinho',
        currentLocation: GeoPoint(lat: -6.185, lon: -35.359),
        targetCategoryId: 'cat_soja',
        annualTargetValue: 200000,
        annualAchievedValue: 80000,
        opportunities: [
          ClientOpportunitySnapshot(
            clientId: 'c_near',
            clientName: 'Cliente Próximo',
            city: 'Cidade Vizinha',
            location: GeoPoint(lat: -6.20, lon: -35.45),
            categoryId: 'cat_soja',
            categoryProgressPercent: 40,
            categoryAchievedValue: 4000,
            lastVisitAt: null,
          ),
          ClientOpportunitySnapshot(
            clientId: 'c_far',
            clientName: 'Cliente Distante',
            city: 'Cidade Longe',
            location: GeoPoint(lat: -7.0, lon: -37.0),
            categoryId: 'cat_soja',
            categoryProgressPercent: 10,
            categoryAchievedValue: 1000,
            lastVisitAt: null,
          ),
        ],
      );

      final result = await engine.recommend(
        context: context,
        policy: VisitRecommendationPolicy.annualTop1,
      );

      expect(result, isNotEmpty);
      expect(result.first.clientId, 'c_near');
    });
  });
}
