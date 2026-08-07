import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../modules/consultoria/clients/presentation/providers/field_providers.dart';
import '../../../../modules/consultoria/services/talhao_map_adapter.dart';

/// Renderiza polígonos de talhões.
///
/// Culling usa [MapCamera] live (não o snapshot throttled) para não sumir
/// talhões durante pan. O snapshot throttled continua para tiles/offline.
class TalhaoPolygonLayer extends ConsumerWidget {
  const TalhaoPolygonLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapFields = ref.watch(mapFieldsProvider);
    final selectedTalhaoId = ref.watch(selectedTalhaoIdProvider);

    if (!mapFields.hasValue) return const SizedBox.shrink();

    final fields = mapFields.value!;
    final bounds = MapCamera.maybeOf(context)?.visibleBounds;
    final polygons = <Polygon>[];

    for (final t in fields) {
      if (t.geometry == null) continue;
      final base = TalhaoMapAdapter.toPolygon(
        t,
        isSelected: t.id == selectedTalhaoId,
      );
      if (base.points.isEmpty) continue;

      if (bounds != null && !_intersectsBounds(base.points, bounds)) {
        continue;
      }

      polygons.add(base);
    }

    return PolygonLayer(polygons: polygons);
  }

  static bool _intersectsBounds(List<LatLng> points, LatLngBounds bounds) {
    for (final p in points) {
      if (bounds.contains(p)) return true;
    }
    final b = LatLngBounds.fromPoints(points);
    return b.north >= bounds.south &&
        b.south <= bounds.north &&
        b.east >= bounds.west &&
        b.west <= bounds.east;
  }
}
