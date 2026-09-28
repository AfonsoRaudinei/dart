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
    this.ndviScenes = const [],
    this.onNdviSceneChanged,
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

  /// Cenas do histórico. Com mais de uma, o arrasto horizontal troca a data.
  final List<TalhaoNdviScene> ndviScenes;
  final ValueChanged<TalhaoNdviScene>? onNdviSceneChanged;
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
                        if (ndviImage != null &&
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

  /// Imagem NDVI renderizável: arquivo local existente ou URL não vazia.
  ImageProvider<Object>? get _ndviImageProvider {
    if (!showNdvi || !ndviIsColormap) return null;
    final path = ndviLocalPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) return FileImage(file);
    }
    final url = ndviImageUrl?.trim();
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  Widget _buildMapSlot(ImageProvider<Object>? ndviImage) {
    if (ndviScenes.length > 1) {
      return SizedBox(
        height: 160,
        child: _NdviScenePager(
          key: const Key('ndvi-scene-pager'),
          scenes: ndviScenes,
          onChanged: onNdviSceneChanged,
          pageBuilder: (scene) {
            final image = _sceneImage(scene);
            return _sceneFrame(scene, image, child: _mapForImage(image));
          },
        ),
      );
    }
    final badge = ndviBadge?.trim();
    final showLegend =
        showNdvi &&
        ndviImage == null &&
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

    final opensNdvi =
        ndviImage != null && vertices.length >= 3 && onNdviImageTap != null;
    return InkWell(
      onTap: opensNdvi ? onNdviImageTap : onTap,
      child: SizedBox(height: 160, child: body),
    );
  }

  ImageProvider<Object>? _sceneImage(TalhaoNdviScene scene) {
    if (!scene.isColormap) return null;
    final path = scene.localPath;
    if (path != null && path.isNotEmpty) {
      final file = File(path);
      if (file.existsSync()) return FileImage(file);
    }
    final url = scene.imageUrl?.trim();
    if (url != null && url.isNotEmpty) return NetworkImage(url);
    return null;
  }

  Widget _sceneFrame(
    TalhaoNdviScene scene,
    ImageProvider<Object>? image, {
    required Widget child,
  }) {
    final badge = scene.badge?.trim();
    final showLegend = image == null && (badge == null || badge.isEmpty);
    return Stack(
      fit: StackFit.expand,
      children: [
        child,
        if (showLegend)
          const Positioned(left: 8, bottom: 8, child: _SemNdviLabel()),
        if (badge != null && badge.isNotEmpty)
          Positioned(left: 8, bottom: 8, child: _NdviBadge(label: badge)),
        if (scene.caption != null && scene.caption!.isNotEmpty)
          Positioned(
            right: 8,
            bottom: 8,
            child: _NdviBadge(label: scene.caption!),
          ),
      ],
    );
  }

  Widget _mapForImage(ImageProvider<Object>? ndviImage) {
    if (vertices.length < 3) return _buildPlaceholder();
    return _buildMap(ndviImage);
  }

  Widget _buildMap(ImageProvider<Object>? ndviImage) {
    // Mesma resolução de provedor da camada satélite do mapa principal
    // (MapTiler com key; fallback licenciado sem key). Auditoria A-001.
    final tileConfig = ndviImage == null
        ? MapConfig.tileConfigForLayer(
            LayerType.satellite,
            mapTilerApiKey: MapConfig.mapTilerApiKey,
          )
        : null;
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

/// Uma data do histórico NDVI mostrada no card.
class TalhaoNdviScene {
  const TalhaoNdviScene({
    required this.imageDateKey,
    required this.isColormap,
    this.localPath,
    this.imageUrl,
    this.caption,
    this.badge,
  });

  final String imageDateKey;
  final bool isColormap;
  final String? localPath;
  final String? imageUrl;
  final String? caption;
  final String? badge;
}

/// Dedo para a esquerda: data mais antiga. Dedo para a direita: data mais recente.
class _NdviScenePager extends StatefulWidget {
  const _NdviScenePager({
    super.key,
    required this.scenes,
    required this.pageBuilder,
    this.onChanged,
  });

  final List<TalhaoNdviScene> scenes;
  final Widget Function(TalhaoNdviScene scene) pageBuilder;
  final ValueChanged<TalhaoNdviScene>? onChanged;

  @override
  State<_NdviScenePager> createState() => _NdviScenePagerState();
}

class _NdviScenePagerState extends State<_NdviScenePager> {
  late final PageController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _notify(0));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _notify(int index) {
    if (!mounted || widget.scenes.isEmpty) return;
    final safe = index.clamp(0, widget.scenes.length - 1);
    widget.onChanged?.call(widget.scenes[safe]);
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      itemCount: widget.scenes.length,
      onPageChanged: _notify,
      itemBuilder: (context, index) => widget.pageBuilder(widget.scenes[index]),
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
