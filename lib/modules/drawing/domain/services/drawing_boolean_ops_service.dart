import '../models/drawing_models.dart';
import '../drawing_utils.dart';

/// Serviço puro de operações booleanas entre geometrias.
///
/// Sem estado, sem I/O. Testável com fixtures determinísticas.
class DrawingBooleanOpsService {
  const DrawingBooleanOpsService();

  /// Calcula a operação booleana entre [featureA] e [featureB]
  /// com base no [mode] atual de interação.
  ///
  /// Retorna a geometria simplificada do resultado, ou null se:
  /// - o modo não é uma operação booleana
  /// - a operação produz geometria vazia/inválida
  DrawingGeometry? calculate(
    DrawingFeature featureA,
    DrawingFeature featureB,
    DrawingInteraction mode,
  ) {
    DrawingGeometry? result;

    switch (mode) {
      case DrawingInteraction.unionSelection:
        result = DrawingUtils.unionGeometries(
          featureA.geometry,
          featureB.geometry,
        );
        break;
      case DrawingInteraction.differenceSelection:
        result = DrawingUtils.difference(featureA.geometry, featureB.geometry);
        break;
      case DrawingInteraction.intersectionSelection:
        result = DrawingUtils.intersection(
          featureA.geometry,
          featureB.geometry,
        );
        break;
      default:
        return null;
    }

    if (result == null) return null;
    return DrawingUtils.simplifyGeometry(result);
  }

  /// Prepara a geometria final para confirmação (simplify + normalize).
  DrawingGeometry finalizeResult(DrawingGeometry geometry) {
    final simplified = DrawingUtils.simplifyGeometry(geometry);
    return DrawingUtils.normalizeGeometry(simplified);
  }
}
