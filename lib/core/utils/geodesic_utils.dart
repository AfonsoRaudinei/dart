import 'package:latlong2/latlong.dart';
import 'dart:math' show sin;

/// Utilidades geodésicas para cálculos geoespaciais precisos.
/// 
/// Usa `latlong2` para distâncias (Vincenty) e implementa área geodésica
/// com algoritmo de Shoelace esférico para WGS84.
/// 
/// Precisão: ±2-3% para polígonos agrícolas (<100km²)
class GeodesicUtils {
  static const double _earthRadiusWGS84 = 6378137.0; // metros (semi-major axis)
  
  /// Calcula a área geodésica de um polígono em hectares.
  /// 
  /// Usa aproximação esférica WGS84 com algoritmo de Shoelace.
  /// Adequado para áreas agrícolas (<100km²).
  /// 
  /// [ring] deve ser uma lista de coordenadas LatLng (pode estar aberto ou fechado)
  /// 
  /// Retorna área em hectares (1 ha = 10.000 m²)
  static double calculateAreaHectares(List<LatLng> ring) {
    if (ring.length < 3) return 0.0;
    
    // Garantir que o anel está fechado
    final closed = ring.last == ring.first ? ring : [...ring, ring.first];
    
    double area = 0.0;
    
    for (int i = 0; i < closed.length - 1; i++) {
      final lat1 = closed[i].latitudeInRad;
      final lat2 = closed[i + 1].latitudeInRad;
      final lon1 = closed[i].longitudeInRad;
      final lon2 = closed[i + 1].longitudeInRad;
      
      // Fórmula de área esférica (Shoelace para coordenadas geodésicas)
      area += (lon2 - lon1) * (2 + sin(lat1) + sin(lat2));
    }
    
    area = area * _earthRadiusWGS84 * _earthRadiusWGS84 / 2.0;
    return area.abs() / 10000.0; // Converter m² para hectares
  }
  
  /// Calcula o perímetro geodésico de um polígono em quilômetros.
  /// 
  /// Usa algoritmo de Vincenty (latlong2) para distâncias precisas.
  /// 
  /// [ring] lista de coordenadas LatLng
  /// [closePath] se true, adiciona segmento de volta ao ponto inicial
  /// 
  /// Retorna perímetro em quilômetros
  static double calculatePerimeterKm(List<LatLng> ring, {bool closePath = true}) {
    if (ring.length < 2) return 0.0;
    
    final distance = Distance();
    double total = 0.0;
    
    // Calcular distância entre pontos consecutivos
    for (int i = 0; i < ring.length - 1; i++) {
      total += distance(ring[i], ring[i + 1]);
    }
    
    // Adicionar último segmento (fechar o anel) se necessário
    if (closePath && ring.first != ring.last) {
      total += distance(ring.last, ring.first);
    }
    
    return total / 1000.0; // metros -> quilômetros
  }
  
  /// Calcula as distâncias de cada segmento do polígono.
  /// 
  /// Útil para exibir informações detalhadas de cada aresta.
  /// 
  /// Retorna lista de distâncias em quilômetros
  static List<double> calculateSegmentDistances(List<LatLng> ring) {
    if (ring.length < 2) return [];
    
    final distance = Distance();
    final segments = <double>[];
    
    for (int i = 0; i < ring.length - 1; i++) {
      final distMeters = distance(ring[i], ring[i + 1]);
      segments.add(distMeters / 1000.0); // metros -> km
    }
    
    return segments;
  }
  
  /// Converte coordenadas [lng, lat] para LatLng
  static List<LatLng> fromCoordinates(List<List<double>> coords) {
    return coords.map((c) => LatLng(c[1], c[0])).toList();
  }
  
  /// Converte LatLng para coordenadas [lng, lat]
  static List<List<double>> toCoordinates(List<LatLng> points) {
    return points.map((p) => [p.longitude, p.latitude]).toList();
  }
}
