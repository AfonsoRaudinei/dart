import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' hide Path;
import 'package:soloforte_app/core/config/map_config.dart';
import 'package:soloforte_app/core/domain/map_models.dart';

class TalhaoMapPreviewWidget extends StatelessWidget {
  const TalhaoMapPreviewWidget({
    super.key,
    required this.vertices,
    required this.nome,
    required this.areaHa,
    this.subtitle,
    this.onTap,
    this.actions = const [],
    this.showNdvi = false,
    this.ndviIsColormap = false,
    this.ndviLocalPath,
    this.ndviImageUrl,
    this.ndviCaption,
    this.ndviBadge,
    this.onNdviImageTap,
  });

  final List<LatLng> vertices;
  final String nome;
  final double areaHa;
  final String? subtitle;
  final VoidCallback? onTap;
  final List<Widget> actions;
  final bool showNdvi;

  /// Raster NDVI georreferenciável. Preview RGB não entra no mapa.
  final bool ndviIsColormap;
  final String? ndviLocalPath;
  final String? ndviImageUrl;
  final String? ndviCaption;

  /// Selo sobre o mapa, por exemplo `Preview RGB`.
  final String? ndviBadge;
  final VoidCallback? onNdviImageTap;

  @override
  Widget build(BuildContext context) {
    final ndviImage = _ndviImageProvider;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMapSlot(ndviImage),
          InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nome,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        if (subtitle != null && subtitle!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            subtitle!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (showNdvi &&
                            ndviCaption != null &&
                            ndviCaption!.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(
                            ndviCaption!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (actions.isEmpty) ...[
                    const SizedBox(width: 12),
                    Text(
                      '${areaHa.toStringAsFixed(2)} ha',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    if (onTap != null) ...[
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFFC7C7CC),
                        size: 20,
                      ),
                    ],
                  ] else ...[
                    const SizedBox(width: 8),
                    Row(mainAxisSize: MainAxisSize.min, children: actions),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Raster no card (Sentinel colormap ou preview Planet recortado ao polígono).
  /// Path no registro sem arquivo no disco não conta — cai para [ndviImageUrl].
  ImageProvider<Object>? get _ndviImageProvider {
    if (!showNdvi) return null;
    final path = ndviLocalPath?.trim();
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) return FileImage(file);
    }
    final url = ndviImageUrl?.trim();
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  Widget _buildMapSlot(ImageProvider<Object>? ndviImage) {
    final badge = ndviBadge?.trim();
    final hasCaption = ndviCaption != null && ndviCaption!.trim().isNotEmpty;
    final showLegend =
        showNdvi &&
        ndviImage == null &&
        !hasCaption &&
        (badge == null || badge.isEmpty) &&
        vertices.length >= 3;
    Widget body = vertices.length < 3
        ? _buildPlaceholder()
        : _buildMap(ndviImage);
    if (showLegend || (badge != null && badge.isNotEmpty)) {
      body = Stack(
        fit: StackFit.expand,
        children: [
          body,
          if (showLegend)
            const Positioned(left: 8, bottom: 8, child: _SemNdviLabel()),
          if (badge != null && badge.isNotEmpty)
            Positioned(left: 8, bottom: 8, child: _NdviBadge(label: badge)),
        ],
      );
    }

    final opensNdvi = showNdvi && onNdviImageTap != null;
    final openHistory = onNdviImageTap;
    return SizedBox(
      height: 160,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(child: body),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: opensNdvi ? openHistory : onTap,
              ),
            ),
          ),
          if (showNdvi && openHistory != null)
            Positioned(
              right: 8,
              bottom: 8,
              child: _NdviHistoryChip(onPressed: openHistory),
            ),
        ],
      ),
    );
  }

  Widget _buildMap(ImageProvider<Object>? ndviImage) {
    // Colormap preenche o polígono; satélite competiria com as cores NDVI.
    // Preview RGB (Planet) e modo mapa mantêm o basemap.
    final hideSatellite = ndviIsColormap && ndviImage != null;
    // Mesma resolução de provedor da camada satélite do mapa principal
    // (MapTiler com key; fallback licenciado sem key). Auditoria A-001.
    final tileConfig = hideSatellite
        ? null
        : MapConfig.tileConfigForLayer(
            LayerType.satellite,
            mapTilerApiKey: MapConfig.mapTilerApiKey,
          );
    return FlutterMap(
      options: MapOptions(
        initialCameraFit: CameraFit.bounds(
          bounds: LatLngBounds.fromPoints(vertices),
          padding: const EdgeInsets.all(16),
        ),
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        if (tileConfig != null)
          TileLayer(
            urlTemplate: tileConfig.urlTemplate,
            subdomains: tileConfig.subdomains,
            maxZoom: tileConfig.maxZoom,
            maxNativeZoom: tileConfig.maxNativeZoom,
            userAgentPackageName: MapConfig.userAgent,
          ),
        if (ndviImage != null)
          _PolygonClippedNdviOverlay(
            key: const Key('ndvi-polygon-overlay'),
            imageProvider: ndviImage,
            vertices: vertices,
          ),
        PolygonLayer(
          polygons: [
            Polygon(
              points: vertices,
              color: ndviImage == null
                  ? Colors.blue.withAlpha(77)
                  : Colors.transparent,
              borderColor: Colors.blue,
              borderStrokeWidth: 2,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: const Color(0xFFF2F2F7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 36, color: Colors.grey.shade500),
            const SizedBox(height: 8),
            Text(
              'Sem geometria',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SemNdviLabel extends StatelessWidget {
  const _SemNdviLabel();

  @override
  Widget build(BuildContext context) {
    return const _NdviBadge(label: 'Sem NDVI');
  }
}

class _NdviHistoryChip extends StatelessWidget {
  const _NdviHistoryChip({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.black.withAlpha(175),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.history_rounded, size: 16, color: Colors.white),
              SizedBox(width: 6),
              Text(
                'Histórico',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NdviBadge extends StatelessWidget {
  const _NdviBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Raster NDVI esticado no bbox e recortado ao anel do talhão.
class _PolygonClippedNdviOverlay extends StatelessWidget {
  const _PolygonClippedNdviOverlay({
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
      clipper: _PolygonClipper(polygon),
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

class _PolygonClipper extends CustomClipper<Path> {
  const _PolygonClipper(this.points);

  final List<Offset> points;

  @override
  Path getClip(Size size) {
    final path = Path();
    if (points.length < 3) return path;
    path.addPolygon(points, true);
    return path;
  }

  @override
  bool shouldReclip(covariant _PolygonClipper oldClipper) {
    return oldClipper.points != points;
  }
}
