import 'dart:math' as math;

import '../entities/visit_recommendation.dart';
import '../entities/visit_recommendation_context.dart';
import '../entities/visit_recommendation_policy.dart';
import 'i_visit_recommendation_engine.dart';

/// Motor determinístico (Fase 2) para sugestão de visitas.
///
/// Regras:
/// 1) somente oportunidades em aberto da categoria alvo
/// 2) respeita cooldown
/// 3) prioriza mesma cidade
/// 4) fallback por raio (km) quando houver localização disponível
/// 5) ordena por menor progresso na categoria (maior oportunidade)
class DeterministicVisitRecommendationEngine
    implements IVisitRecommendationEngine {
  const DeterministicVisitRecommendationEngine();

  @override
  Future<List<VisitRecommendation>> recommend({
    required VisitRecommendationContext context,
    required VisitRecommendationPolicy policy,
  }) async {
    final now = DateTime.now();

    final openByCategory = context.opportunities
        .where((o) => o.categoryId == context.targetCategoryId)
        .where((o) => o.categoryProgressPercent < 100)
        .where((o) => _isOutsideCooldown(o.lastVisitAt, now, policy.cooldown))
        .toList(growable: false);

    if (openByCategory.isEmpty) return const [];

    final sameCity = context.currentCity == null || context.currentCity!.trim().isEmpty
        ? <ClientOpportunitySnapshot>[]
        : openByCategory.where((o) => _sameCity(o.city, context.currentCity!)).toList();

    List<ClientOpportunitySnapshot> pool;
    if (policy.prioritizeSameCity && sameCity.isNotEmpty) {
      pool = sameCity;
    } else {
      pool = _filterByRadiusOrFallback(
        candidates: openByCategory,
        origin: context.currentLocation,
        maxDistanceKm: policy.maxDistanceKm,
      );
    }

    if (pool.isEmpty) return const [];

    pool.sort((a, b) {
      final p = a.categoryProgressPercent.compareTo(b.categoryProgressPercent);
      if (p != 0) return p;

      final v = a.categoryAchievedValue.compareTo(b.categoryAchievedValue);
      if (v != 0) return v;

      // mais antigo primeiro (ou nunca visitado)
      final aTs = a.lastVisitAt?.millisecondsSinceEpoch ?? 0;
      final bTs = b.lastVisitAt?.millisecondsSinceEpoch ?? 0;
      return aTs.compareTo(bTs);
    });

    return pool.take(policy.topN).map((o) {
      return VisitRecommendation(
        clientId: o.clientId,
        clientName: o.clientName,
        city: o.city,
        categoryId: o.categoryId,
        reason: _buildReason(
          currentCity: context.currentCity,
          candidate: o,
        ),
      );
    }).toList(growable: false);
  }

  bool _isOutsideCooldown(DateTime? lastVisitAt, DateTime now, Duration cooldown) {
    if (lastVisitAt == null) return true;
    return now.difference(lastVisitAt) >= cooldown;
  }

  bool _sameCity(String a, String b) {
    return a.trim().toLowerCase() == b.trim().toLowerCase();
  }

  List<ClientOpportunitySnapshot> _filterByRadiusOrFallback({
    required List<ClientOpportunitySnapshot> candidates,
    required GeoPoint? origin,
    required double maxDistanceKm,
  }) {
    if (origin == null) {
      return candidates;
    }

    final within = candidates.where((c) {
      final point = c.location;
      if (point == null) return false;
      final km = _haversineKm(origin, point);
      return km <= maxDistanceKm;
    }).toList(growable: false);

    if (within.isNotEmpty) return within;

    // Sem coordenada útil para filtrar, devolve lista original
    return candidates;
  }

  double _haversineKm(GeoPoint a, GeoPoint b) {
    const r = 6371.0;
    final dLat = _degToRad(b.lat - a.lat);
    final dLon = _degToRad(b.lon - a.lon);

    final la1 = _degToRad(a.lat);
    final la2 = _degToRad(b.lat);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(la1) * math.cos(la2) * math.sin(dLon / 2) * math.sin(dLon / 2);

    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return r * c;
  }

  double _degToRad(double deg) => deg * math.pi / 180.0;

  String _buildReason({
    required String? currentCity,
    required ClientOpportunitySnapshot candidate,
  }) {
    final sameCity = currentCity != null && _sameCity(currentCity, candidate.city);
    final pct = candidate.categoryProgressPercent.clamp(0, 100).toStringAsFixed(1);

    if (sameCity) {
      return 'Cliente em ${candidate.city}, com $pct% na categoria alvo.';
    }

    return 'Melhor oportunidade próxima para avançar a categoria alvo ($pct%).';
  }
}
