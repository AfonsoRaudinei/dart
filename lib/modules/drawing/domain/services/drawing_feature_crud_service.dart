import '../models/drawing_models.dart';
import '../drawing_utils.dart';

/// Serviço puro de CRUD para [DrawingFeature].
///
/// Sem estado, sem I/O — apenas transforma dados.
/// Testável sem qualquer mock.
class DrawingFeatureCrudService {
  const DrawingFeatureCrudService();

  /// Constrói uma nova [DrawingFeature] com ID gerado, área calculada
  /// e status inicial `rascunho` / `local_only`.
  DrawingFeature buildFeature({
    required DrawingGeometry geometry,
    required String nome,
    required DrawingType tipo,
    required DrawingOrigin origem,
    required String autorId,
    required AuthorType autorTipo,
    String? subtipo,
    double? raioMetros,
    String? clienteId,
    String? fazendaId,
    String? grupo,
    int? cor,
  }) {
    final areaHa = DrawingUtils.calculateGeometryArea(geometry);
    return DrawingFeature(
      id: DrawingUtils.generateId(),
      geometry: geometry,
      properties: DrawingProperties(
        nome: nome,
        tipo: tipo,
        origem: origem,
        status: DrawingStatus.rascunho,
        autorId: autorId,
        autorTipo: autorTipo,
        clienteId: clienteId,
        fazendaId: fazendaId,
        areaHa: areaHa,
        versao: 1,
        ativo: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        subtipo: subtipo,
        raioMetros: raioMetros,
        syncStatus: SyncStatus.local_only,
        grupo: grupo,
        cor: cor,
      ),
    );
  }

  /// Prepara a feature atualizada (e a versão desativada se geometria mudou).
  ///
  /// Retorna `(updated, deactivated)` onde:
  /// - `updated` é sempre não-nulo
  /// - `deactivated` é não-nulo apenas quando houve mudança de geometria (versioning)
  ({DrawingFeature updated, DrawingFeature? deactivated}) buildUpdate(
    DrawingFeature oldFeature, {
    String? nome,
    DrawingStatus? status,
    DrawingGeometry? newGeometry,
    String? editorId,
    AuthorType? editorType,
  }) {
    if (newGeometry != null && editorId != null && editorType != null) {
      final newArea = DrawingUtils.calculateGeometryArea(newGeometry);
      final updated = oldFeature.createNewVersion(
        newId: DrawingUtils.generateId(),
        newName: nome ?? oldFeature.properties.nome,
        newGeometry: newGeometry,
        newAreaHa: newArea,
        authorId: editorId,
        authorType: editorType,
      );
      final deactivated = DrawingFeature(
        id: oldFeature.id,
        geometry: oldFeature.geometry,
        properties: oldFeature.properties.copyWith(ativo: false),
      );
      return (updated: updated, deactivated: deactivated);
    }

    final updated = DrawingFeature(
      id: oldFeature.id,
      geometry: oldFeature.geometry,
      properties: oldFeature.properties.copyWith(
        nome: nome,
        status: status,
        updatedAt: DateTime.now(),
        syncStatus: SyncStatus.pending_sync,
      ),
    );
    return (updated: updated, deactivated: null);
  }

  /// Aplica propriedades visuais (grupo, cor) sem alterar geometria nem versão.
  DrawingFeature applyProperties(
    DrawingFeature feature, {
    String? grupo,
    int? cor,
  }) {
    return DrawingFeature(
      id: feature.id,
      geometry: feature.geometry,
      properties: feature.properties.copyWith(
        grupo: grupo,
        cor: cor,
        updatedAt: DateTime.now(),
      ),
    );
  }
}
