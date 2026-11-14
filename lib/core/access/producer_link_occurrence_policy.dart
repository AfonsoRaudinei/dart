/// Compartilhar ocorrência no vínculo produtor — docs/case.md (Bronze+).
class ProducerLinkOccurrencePolicy {
  const ProducerLinkOccurrencePolicy._();

  /// Mesma regra que marketing sem plano pago: `id == free` ou plano expirado/inativo.
  ///
  /// Parâmetros espelham [UserPlan] sem importar `modules/planos` em `core/`.
  static bool consultorPodeCompartilharOcorrencia({
    required bool isAdmin,
    required String planId,
    required bool ocultaPinsMarketingNoMapa,
  }) {
    if (isAdmin) return true;
    if (planId == 'free' || ocultaPinsMarketingNoMapa) return false;
    return true;
  }
}