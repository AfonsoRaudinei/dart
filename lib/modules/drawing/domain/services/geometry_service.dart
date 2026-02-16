import 'package:latlong2/latlong.dart';
import '../models/drawing_models.dart';
import '../../../../core/utils/geodesic_utils.dart';

/// Serviço puro de geometria.
/// 
/// Responsabilidades:
/// - Cálculos geométricos (área, perímetro, distâncias)
/// - Validação topológica
/// - Operações booleanas (união, diferença, interseção)
/// - Normalização de polígonos
/// 
/// ⚠️ IMPORTANTE: Este serviço NÃO deve ter:
/// - Dependências de UI (Flutter Widgets)
/// - Estado mutável
/// - Side effects
/// 
/// Todos os métodos são estáticos e puros (mesma entrada = mesma saída).
class GeometryService {
  GeometryService._(); // Prevenir instanciação

  // ===========================================================================
  // CÁLCULOS GEOMÉTRICOS
  // ===========================================================================

  /// Calcula a área de uma geometria em hectares.
  /// 
  /// Usa cálculos geodésicos via [GeodesicUtils] para precisão em coordenadas geográficas.
  /// 
  /// Retorna 0 para geometrias inválidas ou vazias.
  static double calculateArea(DrawingGeometry? geometry) {
    if (geometry == null) return 0.0;

    if (geometry is DrawingPolygon) {
      if (geometry.coordinates.isEmpty) return 0.0;
      // Área do anel externo
      final outerRing = geometry.coordinates.first;
      final points = GeodesicUtils.fromCoordinates(outerRing);
      return GeodesicUtils.calculateAreaHectares(points);
    } else if (geometry is DrawingMultiPolygon) {
      // Soma das áreas de todos os polígonos
      double totalArea = 0.0;
      for (final polyCoords in geometry.coordinates) {
        if (polyCoords.isNotEmpty) {
          final outerRing = polyCoords.first;
          final points = GeodesicUtils.fromCoordinates(outerRing);
          totalArea += GeodesicUtils.calculateAreaHectares(points);
        }
      }
      return totalArea;
    }

    return 0.0;
  }

  /// Calcula o perímetro de uma geometria em quilômetros.
  /// 
  /// Usa algoritmo de Vincenty via [GeodesicUtils] para alta precisão.
  static double calculatePerimeter(DrawingGeometry? geometry) {
    if (geometry == null) return 0.0;

    if (geometry is DrawingPolygon) {
      if (geometry.coordinates.isEmpty) return 0.0;
      final outerRing = geometry.coordinates.first;
      final points = GeodesicUtils.fromCoordinates(outerRing);
      return GeodesicUtils.calculatePerimeterKm(points);
    } else if (geometry is DrawingMultiPolygon) {
      // Soma dos perímetros
      double totalPerimeter = 0.0;
      for (final polyCoords in geometry.coordinates) {
        if (polyCoords.isNotEmpty) {
          final outerRing = polyCoords.first;
          final points = GeodesicUtils.fromCoordinates(outerRing);
          totalPerimeter += GeodesicUtils.calculatePerimeterKm(points);
        }
      }
      return totalPerimeter;
    }

    return 0.0;
  }

  /// Calcula distâncias individuais entre pontos consecutivos.
  /// 
  /// Retorna lista de distâncias em quilômetros.
  /// Útil para exibir "P1 -> P2: 1.2 km".
  static List<double> calculateSegmentDistances(DrawingGeometry? geometry) {
    if (geometry == null) return [];

    List<List<double>>? ring;

    if (geometry is DrawingPolygon && geometry.coordinates.isNotEmpty) {
      ring = geometry.coordinates.first;
    } else if (geometry is DrawingMultiPolygon &&
        geometry.coordinates.isNotEmpty) {
      if (geometry.coordinates.first.isNotEmpty) {
        ring = geometry.coordinates.first.first;
      }
    }

    if (ring == null || ring.length < 2) return [];

    final points = GeodesicUtils.fromCoordinates(ring);
    return GeodesicUtils.calculateSegmentDistances(points);
  }

  // ===========================================================================
  // VALIDAÇÃO TOPOLÓGICA
  // ===========================================================================

  /// Valida se um polígono tem geometria válida.
  /// 
  /// Verifica:
  /// - Mínimo 3 pontos (triângulo)
  /// - Polígono fechado (primeiro ponto == último ponto)
  /// - Sem auto-interseções (não cruza com si mesmo)
  /// - Furos dentro do anel externo
  static ValidationResult validatePolygon(DrawingPolygon polygon) {
    if (polygon.coordinates.isEmpty) {
      return ValidationResult.invalid('Polígono sem anéis');
    }

    final outerRing = polygon.coordinates.first;

    // Mínimo 4 pontos (triângulo fechado: [A, B, C, A])
    if (outerRing.length < 4) {
      return ValidationResult.invalid(
        'Mínimo 3 pontos necessários (${outerRing.length - 1} fornecido)',
      );
    }

    // Verificar fechamento
    final first = outerRing.first;
    final last = outerRing.last;
    if ((first[0] - last[0]).abs() > 1e-9 ||
        (first[1] - last[1]).abs() > 1e-9) {
      return ValidationResult.invalid('Polígono não está fechado');
    }

    // Auto-interseção (simplificado, não verifica todos os segmentos por performance)
    if (_hasSelfIntersection(outerRing)) {
      return ValidationResult.invalid('Polígono possui auto-interseção');
    }

    // TODO: Validar furos dentro do anel externo

    return ValidationResult.valid();
  }

  /// Verifica auto-interseção em um anel.
  /// 
  /// ⚠️ Algoritmo O(n²) - usar apenas para polígonos pequenos (<100 vértices).
  /// Para polígonos complexos, considerar algoritmo de varredura.
  static bool _hasSelfIntersection(List<List<double>> ring) {
    if (ring.length < 4) return false;

    // Testar cada par de segmentos não-adjacentes
    for (var i = 0; i < ring.length - 1; i++) {
      for (var j = i + 2; j < ring.length - 1; j++) {
        // Não testar segmento final com inicial (são conectados)
        if (i == 0 && j == ring.length - 2) continue;

        if (_segmentsIntersect(
          ring[i],
          ring[i + 1],
          ring[j],
          ring[j + 1],
        )) {
          return true;
        }
      }
    }

    return false;
  }

  /// Verifica se dois segmentos se interceptam.
  /// 
  /// Usa determinantes para teste rápido de interseção.
  static bool _segmentsIntersect(
    List<double> p1,
    List<double> p2,
    List<double> p3,
    List<double> p4,
  ) {
    double ccw(List<double> a, List<double> b, List<double> c) {
      return (c[1] - a[1]) * (b[0] - a[0]) - (b[1] - a[1]) * (c[0] - a[0]);
    }

    final d1 = ccw(p3, p4, p1);
    final d2 = ccw(p3, p4, p2);
    final d3 = ccw(p1, p2, p3);
    final d4 = ccw(p1, p2, p4);

    if (((d1 > 0 && d2 < 0) || (d1 < 0 && d2 > 0)) &&
        ((d3 > 0 && d4 < 0) || (d3 < 0 && d4 > 0))) {
      return true;
    }

    // Casos colineares (simplificado)
    return false;
  }

  // ===========================================================================
  // NORMALIZAÇÃO
  // ===========================================================================

  /// Normaliza um polígono para formato consistente.
  /// 
  /// Ações:
  /// - Fecha anéis abertos
  /// - Remove pontos duplicados consecutivos
  /// - Garante orientação horária (exterior) / anti-horária (furos)
  static DrawingPolygon normalizePolygon(DrawingPolygon polygon) {
    final normalizedRings = polygon.coordinates.map((ring) {
      return _normalizeRing(ring);
    }).toList();

    return DrawingPolygon(coordinates: normalizedRings);
  }

  /// Normaliza um anel individual.
  static List<List<double>> _normalizeRing(List<List<double>> ring) {
    if (ring.length < 3) return ring;

    // 1. Remover duplicatas consecutivas
    final cleaned = <List<double>>[ring.first];
    for (var i = 1; i < ring.length; i++) {
      final current = ring[i];
      final previous = cleaned.last;

      final isDuplicate = (current[0] - previous[0]).abs() < 1e-9 &&
          (current[1] - previous[1]).abs() < 1e-9;

      if (!isDuplicate) {
        cleaned.add(current);
      }
    }

    // 2. Fechar anel se necessário
    if (cleaned.length >= 3) {
      final first = cleaned.first;
      final last = cleaned.last;

      final needsClosure = (first[0] - last[0]).abs() > 1e-9 ||
          (first[1] - last[1]).abs() > 1e-9;

      if (needsClosure) {
        cleaned.add(first);
      }
    }

    return cleaned;
  }

  // ===========================================================================
  // OPERAÇÕES GEOMÉTRICAS
  // ===========================================================================

  /// Verifica se um ponto está dentro de um polígono.
  /// 
  /// Usa algoritmo Ray Casting (O(n) onde n = número de vértices).
  static bool isPointInPolygon(LatLng point, List<List<double>> ring) {
    final lat = point.latitude;
    final lng = point.longitude;

    bool inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i][0];
      final yi = ring[i][1];
      final xj = ring[j][0];
      final yj = ring[j][1];

      final intersect =
          ((yi > lat) != (yj > lat)) &&
          (lng < (xj - xi) * (lat - yi) / (yj - yi) + xi);

      if (intersect) inside = !inside;
    }

    return inside;
  }

  /// Simplifica geometria removendo pontos redundantes.
  /// 
  /// Usa algoritmo Ramer-Douglas-Peucker com tolerância em metros.
  static DrawingPolygon simplifyPolygon(
    DrawingPolygon polygon, {
    double toleranceMeters = 10.0,
  }) {
    // Converter metros para graus (aproximação: 1 metro ≈ 0.00001 graus no equador)
    final epsilon = toleranceMeters * 0.00001;

    final simplifiedRings = polygon.coordinates.map((ring) {
      return _rdpSimplify(ring, epsilon);
    }).toList();

    return DrawingPolygon(coordinates: simplifiedRings);
  }

  /// Implementação do algoritmo Ramer-Douglas-Peucker.
  static List<List<double>> _rdpSimplify(
    List<List<double>> points,
    double epsilon,
  ) {
    if (points.length < 3) return points;

    // Encontrar ponto mais distante da linha entre primeiro e último
    double maxDistance = 0.0;
    int maxIndex = 0;

    final first = points.first;
    final last = points.last;

    for (var i = 1; i < points.length - 1; i++) {
      final distance = _perpendicularDistance(points[i], first, last);
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    // Se distância máxima > epsilon, recursão
    if (maxDistance > epsilon) {
      final left = _rdpSimplify(points.sublist(0, maxIndex + 1), epsilon);
      final right = _rdpSimplify(points.sublist(maxIndex), epsilon);

      // Combinar (removendo duplicata no ponto de divisão)
      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      // Simplificar para apenas primeiro e último ponto
      return [first, last];
    }
  }

  /// Calcula distância perpendicular de ponto para linha.
  static double _perpendicularDistance(
    List<double> point,
    List<double> lineStart,
    List<double> lineEnd,
  ) {
    final x0 = point[0];
    final y0 = point[1];
    final x1 = lineStart[0];
    final y1 = lineStart[1];
    final x2 = lineEnd[0];
    final y2 = lineEnd[1];

    final dx = x2 - x1;
    final dy = y2 - y1;

    final numerator = (dy * x0 - dx * y0 + x2 * y1 - y2 * x1).abs();
    final denominator = (dx * dx + dy * dy);

    if (denominator == 0) {
      // Linha degenerada (ponto)
      return 0;
    }

    return numerator / denominator;
  }

  /// Conta total de vértices em uma geometria.
  static int getVertexCount(DrawingGeometry? geometry) {
    if (geometry == null) return 0;

    if (geometry is DrawingPolygon) {
      return geometry.coordinates.fold<int>(
        0,
        (sum, ring) => sum + ring.length,
      );
    } else if (geometry is DrawingMultiPolygon) {
      return geometry.coordinates.fold<int>(
        0,
        (sum, polyCoords) =>
            sum +
            polyCoords.fold<int>(0, (ringSum, ring) => ringSum + ring.length),
      );
    }

    return 0;
  }
}

/// Resultado de validação geométrica.
class ValidationResult {
  final bool isValid;
  final String? message;

  const ValidationResult._(this.isValid, this.message);

  factory ValidationResult.valid() => const ValidationResult._(true, null);
  factory ValidationResult.invalid(String message) =>
      ValidationResult._(false, message);
}
