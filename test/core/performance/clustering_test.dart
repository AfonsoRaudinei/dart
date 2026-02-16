import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/performance/clustering.dart';

void main() {
  group('MarkerClusterer - Grid Clustering', () {
    test('returns individual markers at high zoom', () {
      final clusterer = MarkerClusterer<String>(minZoom: 14.0);
      final items = [
        ClusterItem(position: LatLng(0, 0), data: 'A'),
        ClusterItem(position: LatLng(0.01, 0.01), data: 'B'),
        ClusterItem(position: LatLng(0.02, 0.02), data: 'C'),
      ];

      final clusters = clusterer.cluster(items, 15.0, null);

      expect(clusters.length, 3); // All individual
      expect(clusters.every((c) => !c.isCluster), true);
    });

    test('clusters nearby markers at low zoom', () {
      final clusterer = MarkerClusterer<String>(
        minZoom: 14.0,
        gridSize: 0.1, // Large grid cells
      );
      final items = [
        ClusterItem(position: LatLng(0, 0), data: 'A'),
        ClusterItem(position: LatLng(0.01, 0.01), data: 'B'),
        ClusterItem(position: LatLng(0.02, 0.02), data: 'C'),
      ];

      final clusters = clusterer.cluster(items, 10.0, null);

      expect(clusters.length, 1); // All in one cluster
      expect(clusters.first.isCluster, true);
      expect(clusters.first.count, 3);
    });

    test('filters markers outside bounds', () {
      final clusterer = MarkerClusterer<String>(minZoom: 14.0);
      final items = [
        ClusterItem(position: LatLng(0, 0), data: 'A'),
        ClusterItem(position: LatLng(10, 10), data: 'B'), // Far away
        ClusterItem(position: LatLng(0.01, 0.01), data: 'C'),
      ];

      final bounds = MapBounds(
        southwest: LatLng(-1, -1),
        northeast: LatLng(1, 1),
      );

      final clusters = clusterer.cluster(items, 10.0, bounds);

      // Only A and C are within bounds
      final totalItems = clusters.fold<int>(
        0,
        (sum, cluster) => sum + cluster.count,
      );
      expect(totalItems, 2);
    });

    test('calculates cluster centroid correctly', () {
      final clusterer = MarkerClusterer<String>(
        minZoom: 14.0,
        gridSize: 0.1, // Grid que agrupa ambos os pontos
      );
      final items = [
        ClusterItem(position: LatLng(0, 0), data: 'A'),
        ClusterItem(position: LatLng(0.02, 0.02), data: 'B'),
      ];

      final clusters = clusterer.cluster(items, 10.0, null);

      expect(clusters.length, 1);
      final cluster = clusters.first;

      // Centroid should be average: (0+0.02)/2 = 0.01
      expect(cluster.position.latitude, closeTo(0.01, 0.01));
      expect(cluster.position.longitude, closeTo(0.01, 0.01));
    });

    test('handles empty items list', () {
      final clusterer = MarkerClusterer<String>(minZoom: 14.0);
      final clusters = clusterer.cluster([], 10.0, null);

      expect(clusters.isEmpty, true);
    });

    test('handles single item', () {
      final clusterer = MarkerClusterer<String>(minZoom: 14.0);
      final items = [
        ClusterItem(position: LatLng(0, 0), data: 'A'),
      ];

      final clusters = clusterer.cluster(items, 10.0, null);

      expect(clusters.length, 1);
      expect(clusters.first.count, 1);
    });
  });

  group('ClusterItem', () {
    test('stores position and data', () {
      final item = ClusterItem<String>(
        position: LatLng(1.5, 2.5),
        data: 'test',
      );

      expect(item.position.latitude, 1.5);
      expect(item.position.longitude, 2.5);
      expect(item.data, 'test');
    });
  });

  group('Cluster', () {
    test('count returns number of items', () {
      final items = [
        ClusterItem(position: LatLng(0, 0), data: 'A'),
        ClusterItem(position: LatLng(1, 1), data: 'B'),
        ClusterItem(position: LatLng(2, 2), data: 'C'),
      ];

      final cluster = Cluster<String>(
        position: LatLng(1, 1),
        items: items,
      );

      expect(cluster.count, 3);
    });

    test('isCluster returns true for multiple items', () {
      final items = [
        ClusterItem(position: LatLng(0, 0), data: 'A'),
        ClusterItem(position: LatLng(1, 1), data: 'B'),
      ];

      final cluster = Cluster<String>(
        position: LatLng(0.5, 0.5),
        items: items,
      );

      expect(cluster.isCluster, true);
    });

    test('isCluster returns false for single item', () {
      final items = [
        ClusterItem(position: LatLng(0, 0), data: 'A'),
      ];

      final cluster = Cluster<String>(
        position: LatLng(0, 0),
        items: items,
      );

      expect(cluster.isCluster, false);
    });
  });

  group('MapBounds', () {
    test('contains returns true for point inside bounds', () {
      final bounds = MapBounds(
        southwest: LatLng(0, 0),
        northeast: LatLng(10, 10),
      );

      expect(bounds.contains(LatLng(5, 5)), true);
      expect(bounds.contains(LatLng(0, 0)), true); // Edge
      expect(bounds.contains(LatLng(10, 10)), true); // Edge
    });

    test('contains returns false for point outside bounds', () {
      final bounds = MapBounds(
        southwest: LatLng(0, 0),
        northeast: LatLng(10, 10),
      );

      expect(bounds.contains(LatLng(-1, 5)), false); // Too far south
      expect(bounds.contains(LatLng(5, -1)), false); // Too far west
      expect(bounds.contains(LatLng(11, 5)), false); // Too far north
      expect(bounds.contains(LatLng(5, 11)), false); // Too far east
    });

    test('fromCenter creates correct bounds', () {
      final bounds = MapBounds.fromCenter(
        center: LatLng(0, 0),
        radiusKm: 111.0, // ~1 degree
      );

      expect(bounds.southwest.latitude, closeTo(-1.0, 0.01));
      expect(bounds.southwest.longitude, closeTo(-1.0, 0.01));
      expect(bounds.northeast.latitude, closeTo(1.0, 0.01));
      expect(bounds.northeast.longitude, closeTo(1.0, 0.01));
    });
  });

  group('Performance with large datasets', () {
    test('clusters 1000 items efficiently', () {
      final clusterer = MarkerClusterer<int>(
        minZoom: 14.0,
        gridSize: 0.1,
      );

      // Generate 1000 random items
      final items = List.generate(
        1000,
        (i) => ClusterItem(
          position: LatLng(
            (i % 100) * 0.01,
            (i ~/ 100) * 0.01,
          ),
          data: i,
        ),
      );

      final stopwatch = Stopwatch()..start();
      final clusters = clusterer.cluster(items, 10.0, null);
      stopwatch.stop();

      // Should cluster significantly
      expect(clusters.length, lessThan(500));

      // Should complete in reasonable time (<100ms)
      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('handles 10000 items', () {
      final clusterer = MarkerClusterer<int>(
        minZoom: 14.0,
        gridSize: 0.1,
      );

      final items = List.generate(
        10000,
        (i) => ClusterItem(
          position: LatLng(
            (i % 100) * 0.01,
            (i ~/ 100) * 0.01,
          ),
          data: i,
        ),
      );

      final stopwatch = Stopwatch()..start();
      final clusters = clusterer.cluster(items, 10.0, null);
      stopwatch.stop();

      expect(clusters.length, lessThan(5000));
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });
  });
}
