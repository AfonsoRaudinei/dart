/// Contrato neutro para comandos sobre talhoes originados do mapa.
///
/// Consumidores externos nao devem importar drawing/ diretamente. A
/// implementacao concreta vive no bounded context dono dos dados.
abstract interface class IDrawingFieldWriter {
  Future<void> deleteFieldAndRecalculateClientArea({
    required String fieldId,
    required String clientId,
  });

  /// Associa um talhao do mapa (`drawings`) a uma fazenda do cliente.
  ///
  /// Atualiza `fazenda_id` / `cliente_id` sem alterar a geometria.
  /// Ver ADR-049.
  Future<void> linkFieldToFarm({
    required String fieldId,
    required String clientId,
    required String farmId,
  });
}
