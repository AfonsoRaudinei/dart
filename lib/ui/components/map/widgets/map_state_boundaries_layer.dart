import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/geo/br_state_boundaries_datasource.dart';
import '../../../../core/geo/br_state_boundary_style.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/state/map_ui_providers.dart';

final brStateBoundariesPolygonsProvider = FutureProvider<List<Polygon>>((
  ref,
) async {
  if (!ref.watch(mapStateBoundariesEnabledProvider)) {
    return const [];
  }
  return BrStateBoundariesDatasource().fetchStatePolygons();
});

List<Polygon> _polygonsWithStyle(
  List<Polygon> source, {
  required Color borderColor,
  required double borderStrokeWidth,
  Color? fillColor,
}) {
  return source
      .map(
        (polygon) => Polygon(
          points: polygon.points,
          holePointsList: polygon.holePointsList,
          borderColor: borderColor,
          borderStrokeWidth: borderStrokeWidth,
          color: fillColor,
        ),
      )
      .toList(growable: false);
}

/// Overlay de divisas UF (IBGE) — abaixo de talhões e acima do satélite.
class MapStateBoundariesLayer extends ConsumerWidget {
  const MapStateBoundariesLayer({super.key});

  static const double _defaultZoom = 13;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(mapStateBoundariesEnabledProvider)) {
      return const SizedBox.shrink();
    }

    final zoom = ref.watch(
          mapCameraSnapshotProvider.select((s) => s?.zoom),
        ) ??
        _defaultZoom;
    final stroke = strokeWidthForZoom(zoom);
    final haloStroke = stroke + 2.0;
    final fill = stateBoundarySubtleFillColor();

    final polygonsAsync = ref.watch(brStateBoundariesPolygonsProvider);
    return polygonsAsync.when(
      data: (polygons) {
        if (polygons.isEmpty) return const SizedBox.shrink();
        return Stack(
          children: [
            PolygonLayer(
              polygons: _polygonsWithStyle(
                polygons,
                borderColor: stateBoundaryHaloBorderColor(),
                borderStrokeWidth: haloStroke,
                fillColor: fill,
              ),
            ),
            PolygonLayer(
              polygons: _polygonsWithStyle(
                polygons,
                borderColor: stateBoundaryLineBorderColor(),
                borderStrokeWidth: stroke,
                fillColor: fill,
              ),
            ),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
