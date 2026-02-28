import 'package:latlong2/latlong.dart';
import '../models/drawing_models.dart';

/// Serviço puro de edição de vértices em [DrawingPolygon].
///
/// Todas as operações são imutáveis: recebem a geometria e retornam
/// uma nova instância, sem alterar o original.
/// Testável sem qualquer mock.
class DrawingVertexEditService {
  const DrawingVertexEditService();

  /// Clona uma geometria de forma profunda (deep copy).
  DrawingGeometry cloneGeometry(DrawingGeometry g) {
    if (g is DrawingPolygon) {
      return DrawingPolygon(
        coordinates: g.coordinates
            .map((ring) => ring.map((p) => [p[0], p[1]]).toList())
            .toList(),
      );
    } else if (g is DrawingMultiPolygon) {
      return DrawingMultiPolygon(
        coordinates: g.coordinates
            .map(
              (polygon) => polygon
                  .map((ring) => ring.map((p) => [p[0], p[1]]).toList())
                  .toList(),
            )
            .toList(),
      );
    }
    return g;
  }

  /// Move o vértice [pointIndex] do ring [ringIndex] para [newPos].
  /// Mantém o fechamento do polígono automaticamente.
  /// Retorna null se os índices forem inválidos.
  DrawingPolygon? moveVertex(
    DrawingPolygon poly,
    int ringIndex,
    int pointIndex,
    LatLng newPos,
  ) {
    if (ringIndex >= poly.coordinates.length) return null;
    final ring = poly.coordinates[ringIndex];
    if (pointIndex >= ring.length) return null;

    final newRing = ring.map((p) => List<double>.from(p)).toList();

    final isClosed =
        newRing.isNotEmpty &&
        newRing.first[0] == newRing.last[0] &&
        newRing.first[1] == newRing.last[1];

    newRing[pointIndex] = [newPos.longitude, newPos.latitude];

    if (isClosed) {
      if (pointIndex == 0) {
        newRing[newRing.length - 1] = [newPos.longitude, newPos.latitude];
      } else if (pointIndex == newRing.length - 1) {
        newRing[0] = [newPos.longitude, newPos.latitude];
      }
    }

    final newCoords = List<List<List<double>>>.from(poly.coordinates);
    newCoords[ringIndex] = newRing;
    return DrawingPolygon(coordinates: newCoords);
  }

  /// Insere um novo vértice após o segmento [segmentIndex] no ring [ringIndex].
  DrawingPolygon? insertVertex(
    DrawingPolygon poly,
    int ringIndex,
    int segmentIndex,
    LatLng point,
  ) {
    if (ringIndex >= poly.coordinates.length) return null;

    final newRing = List<List<double>>.from(poly.coordinates[ringIndex]);

    if (segmentIndex >= 0 && segmentIndex < newRing.length - 1) {
      newRing.insert(segmentIndex + 1, [point.longitude, point.latitude]);
    } else {
      newRing.add([point.longitude, point.latitude]);
    }

    final newCoords = List<List<List<double>>>.from(poly.coordinates);
    newCoords[ringIndex] = newRing;
    return DrawingPolygon(coordinates: newCoords);
  }

  /// Remove o vértice [pointIndex] do ring [ringIndex].
  ///
  /// Retorna `(geometry: null, error: 'mensagem')` se o ring tiver ≤ 4 pontos
  /// (triângulo fechado), pois removeria a geometria mínima válida.
  ({DrawingPolygon? geometry, String? error}) removeVertex(
    DrawingPolygon poly,
    int ringIndex,
    int pointIndex,
  ) {
    if (ringIndex >= poly.coordinates.length) {
      return (geometry: null, error: 'Ring index fora dos limites.');
    }

    final ring = poly.coordinates[ringIndex];
    if (ring.length <= 4) {
      return (geometry: null, error: 'A área precisa ter pelo menos 3 pontos.');
    }

    final newRing = List<List<double>>.from(ring);

    final isClosed =
        newRing.first[0] == newRing.last[0] &&
        newRing.first[1] == newRing.last[1];

    newRing.removeAt(pointIndex);

    if (isClosed) {
      if (pointIndex == 0) {
        newRing.last = [newRing.first[0], newRing.first[1]];
      } else if (pointIndex == ring.length - 1) {
        newRing.add([newRing.first[0], newRing.first[1]]);
      }
    }

    // Robust closure check
    if (newRing.isNotEmpty &&
        (newRing.first[0] != newRing.last[0] ||
            newRing.first[1] != newRing.last[1])) {
      if (pointIndex == 0 || pointIndex == ring.length - 1) {
        newRing.add([newRing.first[0], newRing.first[1]]);
      }
    }

    final newCoords = List<List<List<double>>>.from(poly.coordinates);
    newCoords[ringIndex] = newRing;
    return (geometry: DrawingPolygon(coordinates: newCoords), error: null);
  }
}
