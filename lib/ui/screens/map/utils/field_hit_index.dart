import 'package:latlong2/latlong.dart';

/// Índice espacial simples (grid) para hit-test de talhões.
///
/// Substitui scan linear O(n) por candidatos em células vizinhas.
class FieldHitIndex {
  FieldHitIndex({
    required List<({String id, List<LatLng> points})> entries,
    this.cellSizeDeg = 0.02,
  }) {
    for (final entry in entries) {
      if (entry.points.length < 3) continue;
      double minLat = entry.points.first.latitude;
      double maxLat = minLat;
      double minLng = entry.points.first.longitude;
      double maxLng = minLng;
      for (final p in entry.points) {
        if (p.latitude < minLat) minLat = p.latitude;
        if (p.latitude > maxLat) maxLat = p.latitude;
        if (p.longitude < minLng) minLng = p.longitude;
        if (p.longitude > maxLng) maxLng = p.longitude;
      }
      _items.add(
        _IndexedField(
          id: entry.id,
          points: entry.points,
          minLat: minLat,
          maxLat: maxLat,
          minLng: minLng,
          maxLng: maxLng,
        ),
      );
      final i0 = _cell(minLat);
      final i1 = _cell(maxLat);
      final j0 = _cell(minLng);
      final j1 = _cell(maxLng);
      for (var i = i0; i <= i1; i++) {
        for (var j = j0; j <= j1; j++) {
          _grid.putIfAbsent(_key(i, j), () => <int>[]).add(_items.length - 1);
        }
      }
    }
  }

  final double cellSizeDeg;
  final List<_IndexedField> _items = [];
  final Map<int, List<int>> _grid = {};

  /// Retorna o id do primeiro polígono que contém [point], ou null.
  String? hitTest(LatLng point, bool Function(LatLng, List<LatLng>) contains) {
    final candidates = _grid[_key(_cell(point.latitude), _cell(point.longitude))];
    if (candidates == null || candidates.isEmpty) return null;

    for (final idx in candidates) {
      final item = _items[idx];
      if (point.latitude < item.minLat ||
          point.latitude > item.maxLat ||
          point.longitude < item.minLng ||
          point.longitude > item.maxLng) {
        continue;
      }
      if (contains(point, item.points)) return item.id;
    }
    return null;
  }

  int _cell(double v) => (v / cellSizeDeg).floor();

  int _key(int i, int j) => (i * 73856093) ^ (j * 19349663);
}

class _IndexedField {
  const _IndexedField({
    required this.id,
    required this.points,
    required this.minLat,
    required this.maxLat,
    required this.minLng,
    required this.maxLng,
  });

  final String id;
  final List<LatLng> points;
  final double minLat;
  final double maxLat;
  final double minLng;
  final double maxLng;
}
