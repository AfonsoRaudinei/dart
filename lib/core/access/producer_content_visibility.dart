/// Regras de visibilidade de conteúdo para o perfil produtor.
///
/// - Próprios: `ownerUserId == currentUserId`
/// - Vinculados: `clientId` concedido via `IOccurrenceAccessReader` (ADR-041)
///
/// Neutro de domínio — sem imports de `modules/`.
class ProducerContentVisibility {
  const ProducerContentVisibility._();

  /// Conteúdo criado pelo produtor ou associado a um `clients.id` autorizado.
  static bool ownsOrLinkedClient({
    required String currentUserId,
    required String? ownerUserId,
    required String? clientId,
    required Set<String> authorizedClientIds,
  }) {
    if (currentUserId.isNotEmpty &&
        ownerUserId != null &&
        ownerUserId.isNotEmpty &&
        ownerUserId == currentUserId) {
      return true;
    }
    final id = clientId;
    return id != null &&
        id.isNotEmpty &&
        authorizedClientIds.contains(id);
  }

  /// Relatório de visita visível ao produtor (ADR-009: publicado/arquivado).
  static bool isProducerVisibleVisitStatus(String status) {
    return status == 'publicado' || status == 'arquivado';
  }
}
