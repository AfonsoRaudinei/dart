import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/services/drawing_vertex_edit_service.dart';

// Polígono triangular válido (A-B-C-A): 4 pontos, fechado
DrawingPolygon _triangle() => DrawingPolygon(
      coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [0.5, 1.0],
          [0.0, 0.0], // fechamento
        ],
      ],
    );

// Polígono quadrado com 5 pontos (A-B-C-D-A)
DrawingPolygon _square() => DrawingPolygon(
      coordinates: [
        [
          [0.0, 0.0],
          [1.0, 0.0],
          [1.0, 1.0],
          [0.0, 1.0],
          [0.0, 0.0],
        ],
      ],
    );

void main() {
  const service = DrawingVertexEditService();

  // =========================================================================
  group('cloneGeometry', () {
    test('retorna copia profunda de DrawingPolygon', () {
      final original = _square();
      final clone = service.cloneGeometry(original) as DrawingPolygon;

      // mesmos valores
      expect(clone.coordinates[0][0], equals([0.0, 0.0]));

      // estruturas independentes (mutacao nao afeta original)
      clone.coordinates[0][0][0] = 99.0;
      expect(original.coordinates[0][0][0], equals(0.0));
    });

    test('retorna copia de DrawingMultiPolygon', () {
      final multi = DrawingMultiPolygon(
        coordinates: [
          _square().coordinates,
        ],
      );
      final clone = service.cloneGeometry(multi) as DrawingMultiPolygon;
      expect(clone.coordinates.length, equals(1));
    });
  });

  // =========================================================================
  group('moveVertex', () {
    test('move vertice simples e retorna nova geometria', () {
      final poly = _square();
      final result = service.moveVertex(poly, 0, 1, const LatLng(0.0, 2.0));

      expect(result, isNotNull);
      // novo valor
      expect(result!.coordinates[0][1], equals([2.0, 0.0])); // [lon, lat]
      // original nao mudou
      expect(poly.coordinates[0][1], equals([1.0, 0.0]));
    });

    test('manter fechamento ao mover primeiro ponto', () {
      final poly = _square();
      final result = service.moveVertex(poly, 0, 0, const LatLng(0.5, 0.5));

      expect(result, isNotNull);
      // primeiro == ultimo (fechado)
      expect(result!.coordinates[0].first, equals(result.coordinates[0].last));
    });

    test('manter fechamento ao mover ultimo ponto', () {
      final poly = _square();
      final lastIdx = poly.coordinates[0].length - 1;
      final result = service.moveVertex(poly, 0, lastIdx, const LatLng(0.5, 0.5));

      expect(result, isNotNull);
      expect(result!.coordinates[0].first, equals(result.coordinates[0].last));
    });

    test('retorna null para ringIndex invalido', () {
      final result = service.moveVertex(_square(), 5, 0, const LatLng(0, 0));
      expect(result, isNull);
    });

    test('retorna null para pointIndex invalido', () {
      final result = service.moveVertex(_square(), 0, 99, const LatLng(0, 0));
      expect(result, isNull);
    });
  });

  // =========================================================================
  group('insertVertex', () {
    test('insere vertice no meio do ring', () {
      final poly = _square(); // 5 pontos
      // LatLng(lat, lon): lat=0.0, lon=0.5 → GeoJSON [lon, lat] = [0.5, 0.0]
      final newPoint = const LatLng(0.0, 0.5);
      final result = service.insertVertex(poly, 0, 1, newPoint);

      expect(result, isNotNull);
      // deve ter um ponto a mais
      expect(result!.coordinates[0].length, equals(6));
      // novo ponto na posicao 2: [lon=0.5, lat=0.0]
      expect(result.coordinates[0][2], equals([0.5, 0.0]));
    });

    test('retorna null para ringIndex invalido', () {
      final result = service.insertVertex(_square(), 9, 0, const LatLng(0, 0));
      expect(result, isNull);
    });
  });

  // =========================================================================
  group('removeVertex', () {
    test('remove vertice de poligono com mais de 4 pontos', () {
      final poly = _square(); // 5 pontos: A-B-C-D-A
      final (:geometry, :error) = service.removeVertex(poly, 0, 1);

      expect(error, isNull);
      expect(geometry, isNotNull);
      expect(geometry!.coordinates[0].length, equals(4)); // 4 pontos restantes
    });

    test('retorna erro ao tentar remover de triangulo (4 pontos = minimo)', () {
      final poly = _triangle(); // 4 pontos: A-B-C-A
      final (:geometry, :error) = service.removeVertex(poly, 0, 1);

      expect(error, isNotNull);
      expect(geometry, isNull);
      expect(error, contains('pelo menos 3 pontos'));
    });

    test('mantém fechamento ao remover primeiro ponto', () {
      final poly = _square();
      final (:geometry, :error) = service.removeVertex(poly, 0, 0);

      expect(error, isNull);
      expect(geometry, isNotNull);
      // primeiro == ultimo
      expect(geometry!.coordinates[0].first, equals(geometry.coordinates[0].last));
    });

    test('retorna erro para ringIndex invalido', () {
      final (:geometry, :error) = service.removeVertex(_square(), 5, 0);
      expect(error, isNotNull);
      expect(geometry, isNull);
    });
  });
}
