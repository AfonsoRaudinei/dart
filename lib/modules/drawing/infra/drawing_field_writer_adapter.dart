import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';

/// Adapter de comandos de talhao do mapa.
///
/// Mantem drawing/ como dono da escrita em `drawings` e expõe apenas o contrato
/// neutro para outros bounded contexts.
class DrawingFieldWriterAdapter implements IDrawingFieldWriter {
  const DrawingFieldWriterAdapter(this._repository);

  final DrawingRepository _repository;

  @override
  Future<void> deleteFieldAndRecalculateClientArea({
    required String fieldId,
    required String clientId,
  }) async {
    await _repository.deleteFeature(fieldId);
    if (clientId.isEmpty) return;

    final totalAreaHa = await _repository.getTotalAreaByClienteId(clientId);
    await _repository.updateClientAreaTotal(clientId, totalAreaHa);
  }
}
