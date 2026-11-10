/// Escopo de leitura compartilhada de ocorrencias para o usuario autenticado.
///
/// Ownership continua sendo determinado por `occurrences.user_id`. Esta lista
/// contem apenas `clients.id` concedidos por vinculos ativos.
abstract interface class IOccurrenceAccessReader {
  Future<Set<String>> loadActiveClientIds();

  /// Nome do cadastro do consultor (`clients.id` → nome), para a ocorrência
  /// compartilhada aparecer no nome do produtor.
  Future<Map<String, String>> loadLinkedClientNames();
}
