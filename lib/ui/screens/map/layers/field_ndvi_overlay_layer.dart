import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/ndvi_latest_summary.dart';
import 'package:soloforte_app/core/state/map_ndvi_overlay.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/presentation/providers/drawing_provider.dart';
import 'package:soloforte_app/ui/components/map/map_ndvi_color_legend.dart';

/// Raster NDVI do talhão aberto pela ficha, entre os tiles e o contorno.
class FieldNdviOverlayLayer extends ConsumerWidget {
  const FieldNdviOverlayLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldId = ref.watch(mapNdviOverlayFieldIdProvider);
    final monochrome = ref.watch(mapNdviMonochromeEnabledProvider);
    final summary = ref.watch(mapNdviOverlaySummaryProvider).asData?.value;
    if (fieldId == null || !mapNdviSummaryCoversField(summary)) {
      return const SizedBox.shrink();
    }

    final controller = ref.watch(drawingControllerProvider);
    final vertices = _verticesFor(controller.features, fieldId);
    final hasProcessedGreenMask = monochrome && _hasExistingGreenMask(summary!);
    final image = _imageProvider(summary!, monochrome: monochrome);
    if (vertices.length < 3 || image == null) {
      return const SizedBox.shrink();
    }

    return _ClippedFieldNdviOverlay(
      imageProvider: image,
      vertices: vertices,
      applyMonochromeFilter: monochrome && !hasProcessedGreenMask,
      showColorLegend: !monochrome,
    );
  }

  bool _hasExistingGreenMask(NdviLatestSummary summary) {
    final maskPath = summary.greenMaskLocalPath;
    return maskPath != null &&
        maskPath.isNotEmpty &&
        File(maskPath).existsSync();
  }

  ImageProvider<Object>? _imageProvider(
    NdviLatestSummary summary, {
    required bool monochrome,
  }) {
    if (monochrome) {
      final maskPath = summary.greenMaskLocalPath;
      if (maskPath != null && maskPath.isNotEmpty) {
        final maskFile = File(maskPath);
        if (maskFile.existsSync()) return FileImage(maskFile);
      }
    }
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
    required this.imageProvider,
    required this.vertices,
    this.applyMonochromeFilter = false,
    this.showColorLegend = false,
  });

  final ImageProvider<Object> imageProvider;
  final List<LatLng> vertices;
  final bool applyMonochromeFilter;
  final bool showColorLegend;

  static const double _legendGap = 8;

  static const ColorFilter _monochromeColorFilter = ColorFilter.matrix(<double>[
    0.299,
    0.587,
    0.114,
    0,
    0,
    0.299,
    0.587,
    0.114,
    0,
    0,
    0.299,
    0.587,
    0.114,
    0,
    0,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    final camera = MapCamera.of(context);
    final bounds = LatLngBounds.fromPoints(vertices);
    final northWest = camera.getOffsetFromOrigin(bounds.northWest);
    final southEast = camera.getOffsetFromOrigin(bounds.southEast);
    final polygon = [
      for (final vertex in vertices) camera.getOffsetFromOrigin(vertex),
    ];

    Widget imageWidget = Image(
      image: imageProvider,
      fit: BoxFit.fill,
      gaplessPlayback: true,
    );
    if (applyMonochromeFilter) {
      imageWidget = ColorFiltered(
        colorFilter: _monochromeColorFilter,
        child: imageWidget,
      );
    }

    final imageLeft = math.min(northWest.dx, southEast.dx);
    final imageTop = math.min(northWest.dy, southEast.dy);
    final imageWidth = (northWest.dx - southEast.dx).abs();
    final imageHeight = (northWest.dy - southEast.dy).abs();
    final imageRect = Rect.fromLTWH(
      imageLeft,
      imageTop,
      imageWidth,
      imageHeight,
    );

    // Mesmo espaço dos polígonos: offsets não rotacionados + MobileLayerTransformer.
    // Sem o transformer a imagem fica na tela enquanto o mapa gira.
    // A legenda é irmã do clip: gira com o mapa e não entra no polígono.
    return MobileLayerTransformer(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          ClipPath(
            key: const Key('map-ndvi-overlay'),
            clipper: _FieldNdviClipper(polygon),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Positioned(
                  left: imageLeft,
                  top: imageTop,
                  width: imageWidth,
                  height: imageHeight,
                  child: imageWidget,
                ),
              ],
            ),
          ),
          if (showColorLegend) _ndviColorLegendBeside(camera, imageRect),
        ],
      ),
    );
  }

  Widget _ndviColorLegendBeside(MapCamera camera, Rect imageRect) {
    final onLayerLeft = _ndviLegendOnLayerLeft(camera, imageRect);
    final top =
        imageRect.top + (imageRect.height - MapNdviColorLegend.stripHeight) / 2;
    if (onLayerLeft) {
      // Borda direita (o texto) encosta no vão. O miolo cresce para fora.
      return Positioned(
        top: top,
        right: camera.size.x - (imageRect.left - _legendGap),
        child: const MapNdviColorLegend(labelsToTheRight: true),
      );
    }
    return Positioned(
      top: top,
      left: imageRect.right + _legendGap,
      child: const MapNdviColorLegend(labelsToTheRight: false),
    );
  }
}

/// Lado da bbox com mais folga até a borda da tela. Empate fica à esquerda,
/// longe da coluna direita do mapa.
bool _ndviLegendOnLayerLeft(MapCamera camera, Rect imageRect) {
  final midY = imageRect.center.dy;
  final leftScreenX = _layerToScreen(camera, Offset(imageRect.left, midY)).dx;
  final rightScreenX = _layerToScreen(camera, Offset(imageRect.right, midY)).dx;
  var minScreenX = double.infinity;
  var maxScreenX = double.negativeInfinity;
  for (final corner in <Offset>[
    imageRect.topLeft,
    imageRect.topRight,
    imageRect.bottomLeft,
    imageRect.bottomRight,
  ]) {
    final screenX = _layerToScreen(camera, corner).dx;
    minScreenX = math.min(minScreenX, screenX);
    maxScreenX = math.max(maxScreenX, screenX);
  }
  final rightReserve = kMapActionColumnRightInset + kMapActionColumnButtonSize;
  final spaceLeft = minScreenX;
  final spaceRight = camera.nonRotatedSize.x - rightReserve - maxScreenX;
  final preferScreenLeft = spaceLeft >= spaceRight;
  final layerLeftIsScreenLeft = leftScreenX <= rightScreenX;
  return preferScreenLeft == layerLeftIsScreenLeft;
}

/// Mesma rotação do [MobileLayerTransformer]: o filho gira no centro da caixa.
Offset _layerToScreen(MapCamera camera, Offset layerPoint) {
  final boxWidth = camera.size.x;
  final boxHeight = camera.size.y;
  final origin = Offset(
    (camera.nonRotatedSize.x - boxWidth) / 2,
    (camera.nonRotatedSize.y - boxHeight) / 2,
  );
  final center = Offset(boxWidth / 2, boxHeight / 2);
  final delta = layerPoint - center;
  final cos = math.cos(camera.rotationRad);
  final sin = math.sin(camera.rotationRad);
  final rotated = Offset(
    delta.dx * cos - delta.dy * sin,
    delta.dx * sin + delta.dy * cos,
  );
  return origin + center + rotated;
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
