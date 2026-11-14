/// Escopo de leitura compartilhada de ocorrencias para o usuario autenticado.
///
/// Ownership continua sendo determinado por `occurrences.user_id`. Esta lista
/// contem apenas `clients.id` concedidos por vinculos ativos.
abstract interface class IOccurrenceAccessReader {
  /// Ocorrências: vínculo ativo, `share_occurrences` e Bronze+ dos dois lados.
  Future<Set<String>> loadActiveClientIds();

  /// Vínculo ativo: visita confirmada e fazenda, sem plano do produtor.
  Future<Set<String>> loadLinkedClientIds();

  /// Pin Bronze e cases Bronze do consultor: vínculo ativo e consultor Bronze+.
  Future<Set<String>> loadBronzePinClientIds();

  /// Vínculo ativo com relatórios marcados no convite. Sem plano.
  Future<Set<String>> loadReportClientIds();

  /// Talhões cujas ocorrências o produtor pode ler (vínculo + `share_occurrences`).
  Future<Set<String>> loadActiveFieldIdsForOccurrences();

  /// Nome do cadastro do consultor (`clients.id` → nome), para a ocorrência
  /// compartilhada aparecer no nome do produtor.
  Future<Map<String, String>> loadLinkedClientNames();
}
