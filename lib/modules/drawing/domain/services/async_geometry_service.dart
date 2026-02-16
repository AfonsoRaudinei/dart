import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';
import '../models/drawing_models.dart';
import 'geometry_service.dart';

/// Serviço de geometria otimizado para operações pesadas.
/// 
/// Usa `compute()` para executar cálculos em isolate separado quando:
/// - Número de vértices > complexityThreshold (2000)
/// - Operações de simplificação/validação intensivas
/// 
/// Para geometrias simples (menos de 2000 vértices), usa GeometryService direto
/// para evitar overhead de serialização.
/// 
/// Benefícios:
/// - UI responsiva durante cálculos pesados
/// - Não bloqueia thread principal
/// - Escalável para geometrias com dezenas de milhares de pontos
class AsyncGeometryService {
  AsyncGeometryService._();

  /// Threshold de complexidade (número de vértices) para usar isolate.
  /// 
  /// Valores típicos:
  /// - Polígono simples: 10-100 vértices
  /// - Pivô com alta precisão: 360 vértices
  /// - Importação KML complexa: 1000-50000 vértices
  static const int complexityThreshold = 2000;

  // ===========================================================================
  // CÁLCULOS ASSÍNCRONOS
  // ===========================================================================

  /// Calcula área de forma assíncrona se geometria for complexa.
  /// 
  /// Retorna `Future<double>` em hectares.
  static Future<double> calculateAreaAsync(DrawingGeometry? geometry) async {
    if (geometry == null) return 0.0;

    final vertexCount = _getVertexCount(geometry);

    // Fast path: geometrias simples
    if (vertexCount < complexityThreshold) {
      return GeometryService.calculateArea(geometry);
    }

    // Heavy path: usar isolate
    return compute(_calculateAreaIsolate, geometry);
  }

  /// Calcula perímetro de forma assíncrona se geometria for complexa.
  static Future<double> calculatePerimeterAsync(
    DrawingGeometry? geometry,
  ) async {
    if (geometry == null) return 0.0;

    final vertexCount = _getVertexCount(geometry);

    if (vertexCount < complexityThreshold) {
      return GeometryService.calculatePerimeter(geometry);
    }

    return compute(_calculatePerimeterIsolate, geometry);
  }

  /// Calcula distâncias de segmentos de forma assíncrona.
  static Future<List<double>> calculateSegmentDistancesAsync(
    DrawingGeometry? geometry,
  ) async {
    if (geometry == null) return [];

    final vertexCount = _getVertexCount(geometry);

    if (vertexCount < complexityThreshold) {
      return GeometryService.calculateSegmentDistances(geometry);
    }

    return compute(_calculateSegmentDistancesIsolate, geometry);
  }

  // ===========================================================================
  // VALIDAÇÃO E NORMALIZAÇÃO ASSÍNCRONAS
  // ===========================================================================

  /// Valida polígono de forma assíncrona se complexo.
  /// 
  /// ⚠️ Validação de auto-interseção é O(n²), logo muito cara para n>1000.
  static Future<ValidationResult> validatePolygonAsync(
    DrawingPolygon polygon,
  ) async {
    final vertexCount = _getPolygonVertexCount(polygon);

    if (vertexCount < complexityThreshold) {
      return GeometryService.validatePolygon(polygon);
    }

    return compute(_validatePolygonIsolate, polygon);
  }

  /// Normaliza polígono de forma assíncrona.
  static Future<DrawingPolygon> normalizePolygonAsync(
    DrawingPolygon polygon,
  ) async {
    final vertexCount = _getPolygonVertexCount(polygon);

    if (vertexCount < complexityThreshold) {
      return GeometryService.normalizePolygon(polygon);
    }

    return compute(_normalizePolygonIsolate, polygon);
  }

  /// Simplifica polígono de forma assíncrona.
  /// 
  /// Sempre usa isolate pois simplificação (RDP) é O(n log n).
  static Future<DrawingPolygon> simplifyPolygonAsync(
    DrawingPolygon polygon, {
    double toleranceMeters = 10.0,
  }) async {
    return compute(
      _simplifyPolygonIsolate,
      _SimplifyParams(polygon, toleranceMeters),
    );
  }

  // ===========================================================================
  // OPERAÇÕES BOOLEANAS ASSÍNCRONAS
  // ===========================================================================

  /// Verifica se ponto está dentro do polígono (assíncrono se complexo).
  /// 
  /// Ray Casting é O(n), razoavelmente rápido até ~10k vértices.
  static Future<bool> isPointInPolygonAsync(
    LatLng point,
    List<List<double>> ring,
  ) async {
    if (ring.length < complexityThreshold) {
      return GeometryService.isPointInPolygon(point, ring);
    }

    return compute(
      _isPointInPolygonIsolate,
      _PointInPolygonParams(point, ring),
    );
  }

  // ===========================================================================
  // FUNÇÕES TOP-LEVEL PARA ISOLATE (Obrigatório para compute())
  // ===========================================================================

  /// ⚠️ IMPORTANTE: compute() requer funções top-level ou static.
  /// Não podem capturar variáveis externas.

  static double _calculateAreaIsolate(DrawingGeometry geometry) {
    return GeometryService.calculateArea(geometry);
  }

  static double _calculatePerimeterIsolate(DrawingGeometry geometry) {
    return GeometryService.calculatePerimeter(geometry);
  }

  static List<double> _calculateSegmentDistancesIsolate(
    DrawingGeometry geometry,
  ) {
    return GeometryService.calculateSegmentDistances(geometry);
  }

  static ValidationResult _validatePolygonIsolate(DrawingPolygon polygon) {
    return GeometryService.validatePolygon(polygon);
  }

  static DrawingPolygon _normalizePolygonIsolate(DrawingPolygon polygon) {
    return GeometryService.normalizePolygon(polygon);
  }

  static DrawingPolygon _simplifyPolygonIsolate(_SimplifyParams params) {
    return GeometryService.simplifyPolygon(
      params.polygon,
      toleranceMeters: params.toleranceMeters,
    );
  }

  static bool _isPointInPolygonIsolate(_PointInPolygonParams params) {
    return GeometryService.isPointInPolygon(params.point, params.ring);
  }

  // ===========================================================================
  // HELPERS
  // ===========================================================================

  /// Conta vértices totais em uma geometria.
  static int _getVertexCount(DrawingGeometry geometry) {
    if (geometry is DrawingPolygon) {
      return _getPolygonVertexCount(geometry);
    } else if (geometry is DrawingMultiPolygon) {
      int total = 0;
      for (final polyCoords in geometry.coordinates) {
        for (final ring in polyCoords) {
          total += ring.length;
        }
      }
      return total;
    }
    return 0;
  }

  /// Conta vértices em um polígono.
  static int _getPolygonVertexCount(DrawingPolygon polygon) {
    int total = 0;
    for (final ring in polygon.coordinates) {
      total += ring.length;
    }
    return total;
  }

  /// Verifica se geometria é complexa (>= threshold).
  static bool isComplex(DrawingGeometry? geometry) {
    if (geometry == null) return false;
    return _getVertexCount(geometry) >= complexityThreshold;
  }
}

// =============================================================================
// CLASSES DE PARÂMETROS (Para serialização em compute())
// =============================================================================

/// Parâmetros para simplificação de polígono.
class _SimplifyParams {
  final DrawingPolygon polygon;
  final double toleranceMeters;

  _SimplifyParams(this.polygon, this.toleranceMeters);
}

/// Parâmetros para point-in-polygon.
class _PointInPolygonParams {
  final LatLng point;
  final List<List<double>> ring;

  _PointInPolygonParams(this.point, this.ring);
}
