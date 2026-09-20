import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/modules/drawing/data/repositories/drawing_repository.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';

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

  @override
  Future<void> linkFieldToFarm({
    required String fieldId,
    required String clientId,
    required String farmId,
  }) async {
    if (fieldId.isEmpty || farmId.isEmpty) {
      throw ArgumentError('fieldId e farmId são obrigatórios para vincular.');
    }

    final existing = await _repository.getFeatureById(fieldId);
    if (existing == null || !existing.properties.ativo) {
      throw StateError('Talhão do mapa não encontrado: $fieldId');
    }

    final updated = DrawingFeature(
      id: existing.id,
      geometry: existing.geometry,
      properties: existing.properties.copyWith(
        clienteId: clientId.isEmpty ? existing.properties.clienteId : clientId,
        fazendaId: farmId,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.local_only,
      ),
    );

    await _repository.saveFeature(updated);
  }

  @override
  Future<void> updateFieldName({
    required String fieldId,
    required String name,
  }) async {
    final trimmed = name.trim();
    if (fieldId.isEmpty) {
      throw ArgumentError('fieldId é obrigatório para renomear.');
    }
    if (trimmed.isEmpty) {
      throw ArgumentError('Nome do talhão não pode ser vazio.');
    }

    final existing = await _repository.getFeatureById(fieldId);
    if (existing == null || !existing.properties.ativo) {
      throw StateError('Talhão do mapa não encontrado: $fieldId');
    }

    final syncStatus = existing.properties.syncStatus == SyncStatus.synced
        ? SyncStatus.local_only
        : existing.properties.syncStatus;

    final updated = DrawingFeature(
      id: existing.id,
      geometry: existing.geometry,
      properties: existing.properties.copyWith(
        nome: trimmed,
        updatedAt: DateTime.now(),
        syncStatus: syncStatus,
      ),
    );

    await _repository.saveFeature(updated);
  }
}
