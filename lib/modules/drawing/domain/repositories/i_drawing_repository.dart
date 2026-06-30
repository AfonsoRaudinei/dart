import '../models/drawing_models.dart';
import '../models/drawing_sync_result.dart';

/// Contrato de repositório para [DrawingFeature].
///
/// Abstraí toda persistência local e sincronização remota,
/// permitindo mocks em testes unitários sem banco de dados.
abstract interface class IDrawingRepository {
  Future<void> saveFeature(DrawingFeature feature);
  Future<void> deleteFeature(String id);
  Future<List<DrawingFeature>> getAllFeatures();
  Future<DrawingSyncResult> sync();
  Future<void> markAllForSync();
}
