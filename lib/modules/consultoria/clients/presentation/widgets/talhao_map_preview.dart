import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
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
    this.ndviLocalPath,
    this.ndviImageUrl,
    this.ndviCaption,
    this.onNdviImageTap,
  });

  final List<LatLng> vertices;
  final String nome;
  final double areaHa;
  final String? subtitle;
  final VoidCallback? onTap;
  final List<Widget> actions;
  final bool showNdvi;
  final String? ndviLocalPath;
  final String? ndviImageUrl;
  final String? ndviCaption;
  final VoidCallback? onNdviImageTap;

  @override
  Widget build(BuildContext context) {
    final ndviImage = _ndviImageProvider;
    return Card(
      elevation: 1,
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMapSlot(ndviImage),
            Padding(
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
          ],
        ),
      ),
    );
  }

  /// Imagem NDVI renderizável: arquivo local existente ou URL não vazia.
  ImageProvider<Object>? get _ndviImageProvider {
    if (!showNdvi) return null;
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
    final showLegend = showNdvi && ndviImage == null && vertices.length >= 3;
    Widget body = vertices.length < 3
        ? _buildPlaceholder()
        : _buildMap(ndviImage);
    if (showLegend) {
      body = Stack(
        fit: StackFit.expand,
        children: [
          body,
          const Positioned(left: 8, bottom: 8, child: _SemNdviLabel()),
        ],
      );
    }

    Widget slot = SizedBox(height: 160, child: body);
    if (ndviImage != null && vertices.length >= 3 && onNdviImageTap != null) {
      slot = InkWell(onTap: onNdviImageTap, child: slot);
    }
    return slot;
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
          OverlayImageLayer(
            overlayImages: [
              OverlayImage(
                imageProvider: ndviImage,
                bounds: LatLngBounds.fromPoints(vertices),
              ),
            ],
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
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(140),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(
          'Sem NDVI',
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
