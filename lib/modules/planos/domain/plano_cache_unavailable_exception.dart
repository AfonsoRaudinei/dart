/// Falha ao resolver [UserPlan] sem cache local válido (ADR-012 Adendo 1).
///
/// [expired] distingue "nunca verificado online" de "verificado, mas TTL
/// de 24h já passou". A mensagem ao usuário é a mesma nos dois casos.
class PlanoCacheUnavailableException implements Exception {
  const PlanoCacheUnavailableException({required this.expired});

  /// `true` = havia cache, mas o TTL de 24h expirou.
  /// `false` = nunca houve verificação online neste dispositivo.
  final bool expired;

  @override
  String toString() =>
      'Conecte-se à internet ao menos uma vez a cada 24h para continuar publicando cases offline';
}
