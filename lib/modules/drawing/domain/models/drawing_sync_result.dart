import '../models/drawing_models.dart';

/// Resultado de uma operação de sincronização remota.
/// Definido no domínio para que [IDrawingRepository] seja independente
/// da camada de dados.
class DrawingSyncResult {
  final List<DrawingFeature> updated;
  final List<DrawingFeature> conflicts;
  final int errors;

  const DrawingSyncResult({
    this.updated = const [],
    this.conflicts = const [],
    this.errors = 0,
  });
}
