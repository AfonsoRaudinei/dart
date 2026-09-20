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

  /// Renomeia um talhão do mapa (`drawings`) sem alterar a geometria.
  Future<void> updateFieldName({
    required String fieldId,
    required String name,
  });

  /// Atualiza cultura e safra de um talhão do mapa sem alterar a geometria.
  ///
  /// Strings vazias são normalizadas para `null`. Feature inexistente ou inativa
  /// lança [StateError]. Ver ADR-038.
  Future<void> updateFieldMetadata({
    required String fieldId,
    String? cultura,
    String? safra,
  });
}
