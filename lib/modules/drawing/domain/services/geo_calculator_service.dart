import 'dart:math' as math;

import 'package:latlong2/latlong.dart';

/// Serviço puro de cálculos geoespaciais para o módulo drawing.
///
/// Todos os métodos são estáticos e sem efeitos colaterais, tornando
/// este serviço completamente testável de forma unitária.
///
/// ### Algoritmos utilizados
/// - **Perímetro:** soma das distâncias Haversine entre pontos consecutivos,
///   fechando o polígono (último → primeiro ponto).
/// - **Área:** fórmula de Gauss (Shoelace) com projeção local em metros,
///   usando o centroide do polígono como referência e o raio terrestre médio
///   (6.371.000 m). Não depende de bibliotecas externas.
///
/// ### Precisão
/// Adequada para polígonos de campo de até ~50 km de extensão.
/// Para geometrias intercontinentais, a projeção plana local acumula erro.
class GeoCalculatorService {
  const GeoCalculatorService._();

  /// Raio médio da Terra em metros.
  static const double _earthRadiusM = 6371000.0;

  // ─── API pública ──────────────────────────────────────────────────────────

  /// Calcula o perímetro do polígono em metros.
  ///
  /// Fecha o polígono automaticamente (último → primeiro ponto).
  /// Retorna `0.0` se [points] tiver menos de 2 elementos.
  static double calculatePerimeterMeters(List<LatLng> points) {
    if (points.length < 2) return 0.0;

    double total = 0.0;
    final n = points.length;
    for (int i = 0; i < n; i++) {
      final next = points[(i + 1) % n];
      total += _haversineM(points[i], next);
    }
    return total;
  }

  /// Calcula a área do polígono em metros quadrados.
  ///
  /// Usa a fórmula de Gauss (Shoelace) com projeção local plana.
  /// Retorna `0.0` se [points] tiver menos de 3 elementos.
  static double calculateAreaSquareMeters(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    // Calcular centroide para reduzir erro de projeção
    final lat0 =
        points.map((p) => p.latitude).reduce((a, b) => a + b) / points.length;
    final lng0 =
        points.map((p) => p.longitude).reduce((a, b) => a + b) / points.length;

    // Fatores de conversão grau → metros na latitude de referência
    const degToRad = math.pi / 180.0;
    final metersPerDegLat = _earthRadiusM * degToRad;
    final metersPerDegLng =
        _earthRadiusM * math.cos(lat0 * degToRad) * degToRad;

    // Projetar pontos em coordenadas locais (metros)
    final xs =
        points.map((p) => (p.longitude - lng0) * metersPerDegLng).toList();
    final ys =
        points.map((p) => (p.latitude - lat0) * metersPerDegLat).toList();

    // Shoelace (Gauss)
    double area = 0.0;
    final n = points.length;
    for (int i = 0; i < n; i++) {
      final j = (i + 1) % n;
      area += xs[i] * ys[j];
      area -= xs[j] * ys[i];
    }
    return area.abs() / 2.0;
  }

  // ─── Helpers privados ─────────────────────────────────────────────────────

  /// Distância Haversine entre dois pontos em metros.
  static double _haversineM(LatLng a, LatLng b) {
    const degToRad = math.pi / 180.0;
    final lat1 = a.latitude * degToRad;
    final lat2 = b.latitude * degToRad;
    final dLat = (b.latitude - a.latitude) * degToRad;
    final dLng = (b.longitude - a.longitude) * degToRad;

    final sinHalfDLat = math.sin(dLat / 2);
    final sinHalfDLng = math.sin(dLng / 2);

    final h = sinHalfDLat * sinHalfDLat +
        math.cos(lat1) * math.cos(lat2) * sinHalfDLng * sinHalfDLng;

    return 2 * _earthRadiusM * math.asin(math.sqrt(h.clamp(0.0, 1.0)));
  }
}
