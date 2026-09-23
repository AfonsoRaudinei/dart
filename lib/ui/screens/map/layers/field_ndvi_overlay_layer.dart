import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:soloforte_app/core/contracts/ndvi_latest_summary.dart';
import 'package:soloforte_app/core/state/map_ndvi_overlay.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';

/// Raster NDVI do talhão aberto pela ficha, entre os tiles e o contorno.
class FieldNdviOverlayLayer extends ConsumerWidget {
  const FieldNdviOverlayLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldId = ref.watch(mapNdviOverlayFieldIdProvider);
    final summary = ref.watch(mapNdviOverlaySummaryProvider).asData?.value;
    if (fieldId == null || !mapNdviSummaryCoversField(summary)) {
      return const SizedBox.shrink();
    }

    final controller = ref.watch(drawingControllerProvider);
    final vertices = _verticesFor(controller.features, fieldId);
    final image = _imageProvider(summary!);
    if (vertices.length < 3 || image == null) {
      return const SizedBox.shrink();
    }

    return _ClippedFieldNdviOverlay(
      key: const Key('map-ndvi-overlay'),
      imageProvider: image,
      vertices: vertices,
    );
  }

  ImageProvider<Object>? _imageProvider(NdviLatestSummary summary) {
    final path = summary.localPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) return FileImage(file);
    }
    final url = summary.imageUrl?.trim();
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  List<LatLng> _verticesFor(List<DrawingFeature> features, String fieldId) {
    for (final feature in features) {
      if (feature.id != fieldId) continue;
      final geometry = feature.geometry;
      if (geometry is DrawingPolygon && geometry.coordinates.isNotEmpty) {
        return _ring(geometry.coordinates.first);
      }
      if (geometry is DrawingMultiPolygon &&
          geometry.coordinates.isNotEmpty &&
          geometry.coordinates.first.isNotEmpty) {
        return _ring(geometry.coordinates.first.first);
      }
    }
    return const [];
  }

  List<LatLng> _ring(List<List<double>> ring) {
    return [
      for (final point in ring)
        if (point.length >= 2) LatLng(point[1], point[0]),
    ];
  }
}

class _ClippedFieldNdviOverlay extends StatelessWidget {
  const _ClippedFieldNdviOverlay({
    super.key,
    required this.imageProvider,
    required this.vertices,
  });

  final ImageProvider<Object> imageProvider;
  final List<LatLng> vertices;

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final bounds = LatLngBounds.fromPoints(vertices);
    final northWest = camera.getOffsetFromOrigin(bounds.northWest);
    final southEast = camera.getOffsetFromOrigin(bounds.southEast);
    final polygon = [
      for (final vertex in vertices) camera.getOffsetFromOrigin(vertex),
    ];

    return ClipPath(
      clipper: _FieldNdviClipper(polygon),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fromRect(
            rect: Rect.fromPoints(northWest, southEast),
            child: Image(
              image: imageProvider,
              fit: BoxFit.fill,
              gaplessPlayback: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _FieldNdviClipper extends CustomClipper<Path> {
  const _FieldNdviClipper(this.points);

  final List<Offset> points;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (points.length < 3) return path;
    path.addPolygon(points, true);
    return path;
  }

  @override
  bool shouldReclip(covariant _FieldNdviClipper oldClipper) {
    return oldClipper.points != points;
  }
}
