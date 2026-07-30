import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/br_state_boundaries_datasource.dart';
import '../../../../core/state/map_state.dart';

final brStateBoundariesPolygonsProvider = FutureProvider<List<Polygon>>((
  ref,
) async {
  if (!ref.watch(mapStateBoundariesEnabledProvider)) {
    return const [];
  }
  return BrStateBoundariesDatasource().fetchStatePolygons();
});

/// Overlay de divisas UF (IBGE) — abaixo de talhões e acima do satélite.
class MapStateBoundariesLayer extends ConsumerWidget {
  const MapStateBoundariesLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(mapStateBoundariesEnabledProvider)) {
      return const SizedBox.shrink();
    }

    final polygonsAsync = ref.watch(brStateBoundariesPolygonsProvider);
    return polygonsAsync.when(
      data: (polygons) {
        if (polygons.isEmpty) return const SizedBox.shrink();
        return PolygonLayer(polygons: polygons);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
