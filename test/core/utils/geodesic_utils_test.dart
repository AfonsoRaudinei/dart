import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/utils/geodesic_utils.dart';

void main() {
  group('GeodesicUtils - Area Calculations', () {
    test('Quadrado 1km x 1km deve ter ~100 hectares (±5%)', () {
      // Quadrado com ~1km de lado próximo ao equador (baixa distorção)
      // Lat: 0.0, Lng: -47.0 até -47.009 (≈1km)
      final square1km = [
        const LatLng(0.0, -47.0),
        const LatLng(0.009, -47.0), // ≈1km norte
        const LatLng(0.009, -47.009), // ≈1km leste
        const LatLng(0.0, -47.009),
        const LatLng(0.0, -47.0), // Fechar polígono
      ];

      final areaHa = GeodesicUtils.calculateAreaHectares(square1km);

      // Área esperada: ~100 hectares (1km² = 100ha)
      // Tolerância: ±5% = 95-105 hectares
      expect(areaHa, greaterThan(95.0));
      expect(areaHa, lessThan(105.0));
    });

    test('Retângulo 2km x 1km deve ter ~200 hectares (±5%)', () {
      // Retângulo 2km (lat) x 1km (lng) próximo ao equador
      final rectangle2x1 = [
        const LatLng(0.0, -47.0),
        const LatLng(0.018, -47.0), // ≈2km norte
        const LatLng(0.018, -47.009), // ≈1km leste
        const LatLng(0.0, -47.009),
        const LatLng(0.0, -47.0),
      ];

      final areaHa = GeodesicUtils.calculateAreaHectares(rectangle2x1);

      // Área esperada: ~200 hectares (2km² = 200ha)
      // Tolerância: ±5% = 190-210 hectares
      expect(areaHa, greaterThan(190.0));
      expect(areaHa, lessThan(210.0));
    });

    test('Polígono vazio deve retornar 0 hectares', () {
      final empty = <LatLng>[];
      final areaHa = GeodesicUtils.calculateAreaHectares(empty);
      expect(areaHa, equals(0.0));
    });

    test('Polígono com apenas 2 pontos deve retornar 0 hectares', () {
      final twoPoints = [const LatLng(0.0, 0.0), const LatLng(1.0, 1.0)];
      final areaHa = GeodesicUtils.calculateAreaHectares(twoPoints);
      expect(areaHa, equals(0.0));
    });

    test('Triângulo em Brasília deve ter área positiva', () {
      // Triângulo no Plano Piloto (coordenadas reais)
      final triangle = [
        const LatLng(-15.7935, -47.8828), // Torre de TV
        const LatLng(-15.8034, -47.8897), // Congresso
        const LatLng(-15.8000, -47.8650), // Catedral
        const LatLng(-15.7935, -47.8828), // Fechar
      ];

      final areaHa = GeodesicUtils.calculateAreaHectares(triangle);

      // Esperamos área entre 100-300 hectares (área do Eixo Monumental)
      expect(areaHa, greaterThan(100.0));
      expect(areaHa, lessThan(300.0));
    });
  });

  group('GeodesicUtils - Perimeter Calculations', () {
    test('Quadrado 1km x 1km deve ter perímetro ~4km (±5%)', () {
      final square1km = [
        const LatLng(0.0, -47.0),
        const LatLng(0.009, -47.0),
        const LatLng(0.009, -47.009),
        const LatLng(0.0, -47.009),
        const LatLng(0.0, -47.0),
      ];

      final perimeterKm = GeodesicUtils.calculatePerimeterKm(square1km);

      // Perímetro esperado: ~4km
      // Tolerância: ±5% = 3.8-4.2 km
      expect(perimeterKm, greaterThan(3.8));
      expect(perimeterKm, lessThan(4.2));
    });

    test('Linha reta 10km deve ter perímetro ~20km (ida+volta)', () {
      final straightLine = [
        const LatLng(0.0, -47.0),
        const LatLng(0.09, -47.0), // ≈10km norte
      ];

      final perimeterKm = GeodesicUtils.calculatePerimeterKm(straightLine);
      // Perímetro = distância ida + volta = ~20km
      expect(perimeterKm, greaterThan(19.0));
      expect(perimeterKm, lessThan(21.0));
    });

    test('Polígono vazio deve ter perímetro 0', () {
      final empty = <LatLng>[];
      final perimeterKm = GeodesicUtils.calculatePerimeterKm(empty);
      expect(perimeterKm, equals(0.0));
    });
  });

  group('GeodesicUtils - Segment Distance Calculations', () {
    test('Distâncias entre segmentos consecutivos de 1km', () {
      final line1km = [
        const LatLng(0.0, -47.0),
        const LatLng(0.009, -47.0), // ≈1km
        const LatLng(0.009, -47.009), // ≈1km
        const LatLng(0.0, -47.009), // ≈1km de volta
      ];

      final segments = GeodesicUtils.calculateSegmentDistances(line1km);

      expect(segments.length, equals(3)); // 4 pontos = 3 segmentos

      // Todos os segmentos devem ter ~1km
      for (var i = 0; i < segments.length; i++) {
        expect(
          segments[i],
          greaterThan(0.95),
          reason: 'Segmento $i deve ser >= 0.95km',
        );
        expect(
          segments[i],
          lessThan(1.05),
          reason: 'Segmento $i deve ser <= 1.05km',
        );
      }
    });

    test('Segmentos vazios devem retornar lista vazia', () {
      final empty = <LatLng>[];
      final segments = GeodesicUtils.calculateSegmentDistances(empty);
      expect(segments, isEmpty);
    });

    test('Apenas 1 ponto não forma segmentos', () {
      final onePoint = [const LatLng(0.0, 0.0)];
      final segments = GeodesicUtils.calculateSegmentDistances(onePoint);
      expect(segments, isEmpty);
    });
  });

  group('GeodesicUtils - Coordinate Conversions', () {
    test('fromCoordinates deve converter [lng,lat] para LatLng', () {
      final coords = [
        [-47.0, -15.7935], // Brasília: [lng, lat]
        [-47.8897, -15.8034],
      ];

      final points = GeodesicUtils.fromCoordinates(coords);

      expect(points.length, equals(2));
      expect(points[0].latitude, equals(-15.7935));
      expect(points[0].longitude, equals(-47.0));
      expect(points[1].latitude, equals(-15.8034));
      expect(points[1].longitude, equals(-47.8897));
    });

    test('fromCoordinates com lista vazia deve retornar lista vazia', () {
      final coords = <List<double>>[];
      final points = GeodesicUtils.fromCoordinates(coords);
      expect(points, isEmpty);
    });

    test('fromCoordinates deve lidar com coordenadas válidas', () {
      final coords = <List<double>>[
        [-47.0, -15.7935],
        [-47.8897, -15.8034], // Válido
      ];

      final points = GeodesicUtils.fromCoordinates(coords);

      expect(points.length, equals(2));
      expect(points[0].latitude, equals(-15.7935));
      expect(points[0].longitude, equals(-47.0));
      expect(points[1].latitude, equals(-15.8034));
      expect(points[1].longitude, equals(-47.8897));
    });
  });

  group('GeodesicUtils - Precision Validation', () {
    test('Área de fazenda real (50 hectares) deve ter precisão ±5%', () {
      // Polígono simulando fazenda de 50ha (~707m x 707m)
      final farm50ha = [
        const LatLng(-15.7935, -47.8828),
        const LatLng(-15.7935 + 0.00636, -47.8828), // ≈707m norte
        const LatLng(-15.7935 + 0.00636, -47.8828 - 0.00636), // ≈707m oeste
        const LatLng(-15.7935, -47.8828 - 0.00636),
        const LatLng(-15.7935, -47.8828),
      ];

      final areaHa = GeodesicUtils.calculateAreaHectares(farm50ha);

      // Esperado: 50ha ±5% = 47.5-52.5 hectares (esférico vs elipsoidal)
      expect(areaHa, greaterThan(47.5));
      expect(areaHa, lessThan(52.5));
    });
  });
}
