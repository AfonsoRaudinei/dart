/// Contrato neutro para comandos sobre talhoes originados do mapa.
///
/// Consumidores externos nao devem importar drawing/ diretamente. A
/// implementacao concreta vive no bounded context dono dos dados.
abstract interface class IDrawingFieldWriter {
  Future<void> deleteFieldAndRecalculateClientArea({
    required String fieldId,
    required String clientId,
  });
}
