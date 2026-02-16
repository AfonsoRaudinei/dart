import 'package:latlong2/latlong.dart';

/// Sistema de clustering para markers de mapa.
/// 
/// Agrupa markers próximos quando zoom < threshold para melhorar performance.
/// Usa algoritmo K-means simplificado ou Grid-based clustering.
/// 
/// Exemplo:
/// ```dart
/// final clusterer = MarkerClusterer(
///   minZoom: 12.0,
///   maxDistance: 60, // pixels
/// );
/// 
/// final clusters = clusterer.cluster(markers, zoom, bounds);
/// ```
class MarkerClusterer<T> {
  /// Zoom mínimo para mostrar markers individuais.
  final double minZoom;

  /// Distância máxima em pixels para agrupar markers.
  final double maxDistance;

  /// Tamanho do grid (em graus) para grid-based clustering.
  final double gridSize;

  MarkerClusterer({
    this.minZoom = 14.0,
    this.maxDistance = 60.0,
    this.gridSize = 0.01,
  });

  /// Agrupa markers baseado em zoom e bounds visíveis.
  List<Cluster<T>> cluster(
    List<ClusterItem<T>> items,
    double zoom,
    MapBounds? bounds,
  ) {
    // Zoom alto: mostrar todos os markers individuais
    if (zoom >= minZoom) {
      return items
          .map((item) => Cluster<T>(
                position: item.position,
                items: [item],
              ))
          .toList();
    }

    // Filtrar apenas items visíveis
    final visibleItems = bounds != null
        ? items.where((item) => bounds.contains(item.position)).toList()
        : items;

    // Grid-based clustering (rápido, O(n))
    return _gridCluster(visibleItems);
  }

  /// Clustering baseado em grid.
  /// 
  /// Divide mapa em células e agrupa markers na mesma célula.
  List<Cluster<T>> _gridCluster(List<ClusterItem<T>> items) {
    final Map<String, List<ClusterItem<T>>> grid = {};

    for (final item in items) {
      final cellLat = (item.position.latitude / gridSize).floor();
      final cellLng = (item.position.longitude / gridSize).floor();
      final key = '$cellLat:$cellLng';

      grid.putIfAbsent(key, () => []).add(item);
    }

    return grid.values.map((cellItems) {
      // Calcular centróide da célula
      final avgLat =
          cellItems.map((i) => i.position.latitude).reduce((a, b) => a + b) /
              cellItems.length;
      final avgLng =
          cellItems.map((i) => i.position.longitude).reduce((a, b) => a + b) /
              cellItems.length;

      return Cluster<T>(
        position: LatLng(avgLat, avgLng),
        items: cellItems,
      );
    }).toList();
  }
}

/// Item que pode ser clusterizado.
class ClusterItem<T> {
  final LatLng position;
  final T data;

  ClusterItem({
    required this.position,
    required this.data,
  });
}

/// Cluster de markers.
class Cluster<T> {
  /// Posição do cluster (centróide).
  final LatLng position;

  /// Items agrupados no cluster.
  final List<ClusterItem<T>> items;

  Cluster({
    required this.position,
    required this.items,
  });

  /// Número de items no cluster.
  int get count => items.length;

  /// Se é cluster (múltiplos items) ou marker individual.
  bool get isCluster => items.length > 1;
}

/// Bounds de lat/lng (renomeado para evitar conflito com flutter_map).
class MapBounds {
  final LatLng southwest;
  final LatLng northeast;

  MapBounds({
    required this.southwest,
    required this.northeast,
  });

  /// Verifica se ponto está dentro dos bounds.
  bool contains(LatLng point) {
    return point.latitude >= southwest.latitude &&
        point.latitude <= northeast.latitude &&
        point.longitude >= southwest.longitude &&
        point.longitude <= northeast.longitude;
  }

  /// Cria bounds a partir de centro e raio.
  factory MapBounds.fromCenter({
    required LatLng center,
    required double radiusKm,
  }) {
    const kmPerDegree = 111.0; // Aproximação
    final radiusDeg = radiusKm / kmPerDegree;

    return MapBounds(
      southwest: LatLng(
        center.latitude - radiusDeg,
        center.longitude - radiusDeg,
      ),
      northeast: LatLng(
        center.latitude + radiusDeg,
        center.longitude + radiusDeg,
      ),
    );
  }
}
