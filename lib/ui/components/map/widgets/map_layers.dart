import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/config/map_config.dart';
import '../../../../core/utils/map_logger.dart';
import '../../../../core/providers/connectivity_provider.dart';

bool shouldUseOfflineTileLayer({
  required bool hasOfflineCoverageForLayer,
  required String? offlineTemplate,
  required bool? isOnline,
}) {
  return offlineTemplate != null &&
      hasOfflineCoverageForLayer &&
      isOnline != true;
}

/// Widget que observa apenas activeLayerProvider e renderiza o TileLayer.
/// Rebuild isolado quando a camada muda.
class MapLayersWidget extends ConsumerWidget {
  const MapLayersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLayer = ref.watch(activeLayerProvider);
    final wms = ref.watch(externalWmsLayerProvider);
    final raster = ref.watch(externalRasterLayerProvider);
    final isOnline = ref.watch(isOnlineProvider).asData?.value;
    final offlineRoot = ref.watch(offlineTileCacheRootPathProvider).valueOrNull;
    final cacheService = ref.watch(offlineTileCacheServiceProvider);
    final tileConfig = MapConfig.tileConfigForLayer(
      activeLayer,
      mapTilerApiKey: MapConfig.kMapTilerApiKey,
    );
    final layerKey = cacheService.layerKeyFromTemplate(tileConfig.urlTemplate);
    final hasOfflineCoverageForLayer = ref.watch(
      offlineMapAreasProvider.select(
        (areas) => areas.any((area) => area.layerKey == layerKey),
      ),
    );
    final offlineTemplate = offlineRoot == null
        ? null
        : '$offlineRoot/$layerKey/{z}/{x}/{y}.tile';
    final rasterTemplate = _resolveRasterTemplate(raster);
    final shouldUseOfflineTiles = shouldUseOfflineTileLayer(
      hasOfflineCoverageForLayer: hasOfflineCoverageForLayer,
      offlineTemplate: offlineTemplate,
      isOnline: isOnline,
    );

    return Stack(
      children: [
        if (shouldUseOfflineTiles)
          TileLayer(
            urlTemplate: offlineTemplate,
            tileProvider: FileTileProvider(),
            userAgentPackageName: MapConfig.userAgent,
            maxZoom: tileConfig.maxZoom,
            maxNativeZoom: tileConfig.maxNativeZoom,
            keepBuffer: 3,
            panBuffer: 1,
            errorTileCallback: (tile, error, stackTrace) {
              MapLogger.logError(
                'Offline tile error on $activeLayer: $error',
                stackTrace,
              );
            },
          )
        else
          TileLayer(
            urlTemplate: tileConfig.urlTemplate,
            fallbackUrl: tileConfig.fallbackUrl,
            subdomains: tileConfig.subdomains,
            userAgentPackageName: MapConfig.userAgent,
            maxZoom: tileConfig.maxZoom,
            maxNativeZoom: tileConfig.maxNativeZoom,
            retinaMode:
                tileConfig.retinaMode && RetinaMode.isHighDensity(context),
            keepBuffer: 3,
            panBuffer: 1,
            errorTileCallback: (tile, error, stackTrace) {
              MapLogger.logError(
                'Tile error on $activeLayer: $error',
                stackTrace,
              );
            },
          ),
        if (raster.enabled && raster.hasLocalGeoTiff)
          OverlayImageLayer(
            overlayImages: [
              OverlayImage(
                imageProvider: FileImage(File(raster.localPngPath!)),
                bounds: LatLngBounds(
                  LatLng(raster.localSouth!, raster.localWest!),
                  LatLng(raster.localNorth!, raster.localEast!),
                ),
                opacity: raster.opacity.clamp(0.05, 1.0),
              ),
            ],
          ),
        if (raster.enabled && rasterTemplate.isNotEmpty)
          Opacity(
            opacity: raster.opacity.clamp(0.05, 1.0),
            child: TileLayer(
              urlTemplate: rasterTemplate,
              userAgentPackageName: MapConfig.userAgent,
              maxZoom: 22,
              maxNativeZoom: 22,
            ),
          ),
        if (wms.enabled &&
            wms.baseUrl.trim().isNotEmpty &&
            wms.layers.trim().isNotEmpty)
          Opacity(
            opacity: 0.9,
            child: TileLayer(
              wmsOptions: WMSTileLayerOptions(
                baseUrl: _normalizeWmsBaseUrl(wms.baseUrl),
                layers: wms.layers
                    .split(',')
                    .map((layer) => layer.trim())
                    .where((layer) => layer.isNotEmpty)
                    .toList(growable: false),
                format: wms.format,
                version: wms.version,
                transparent: wms.transparent,
                crs: _resolveWmsCrs(wms.crs),
              ),
              userAgentPackageName: MapConfig.userAgent,
              maxZoom: 22,
              maxNativeZoom: 22,
            ),
          ),
      ],
    );
  }

  String _resolveRasterTemplate(ExternalRasterLayerConfig raster) {
    if (raster.hasLocalGeoTiff) return '';
    final raw = raster.urlTemplate.trim();
    if (raw.isEmpty) return '';
    final isGeoTiffExt =
        raw.toLowerCase().endsWith('.tif') ||
        raw.toLowerCase().endsWith('.tiff');
    if (raster.isGeoTiff || isGeoTiffExt) {
      final endpoint = raster.geoTiffTileEndpoint.trim().replaceAll(
        RegExp(r'/$'),
        '',
      );
      final encodedUrl = Uri.encodeComponent(raw);
      return '$endpoint/cog/tiles/WebMercatorQuad/{z}/{x}/{y}.png?url=$encodedUrl';
    }
    return raw;
  }

  String _normalizeWmsBaseUrl(String baseUrl) {
    final trimmed = baseUrl.trim();
    if (trimmed.endsWith('?') || trimmed.endsWith('&')) return trimmed;
    return trimmed.contains('?') ? '$trimmed&' : '$trimmed?';
  }

  Crs _resolveWmsCrs(String raw) {
    return raw.trim().toUpperCase() == 'EPSG:4326'
        ? const Epsg4326()
        : const Epsg3857();
  }
}
