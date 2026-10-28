import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/services/persistent_offline_tile_provider.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../../../../core/config/map_config.dart';
import '../../../../core/config/cerrado_satellite_overlay.dart';
import '../../../../core/config/brazil_satellite_mosaic_overlay.dart';
import '../../../../core/config/inpe_satellite_overlay_mode.dart';
import '../../../../core/domain/map_models.dart';
import '../../../../core/utils/map_logger.dart';
import '../../../../core/providers/connectivity_provider.dart';

/// Overlay INPE Cerrado só online — offline usa cache local sem WMS bloqueando tiles.
bool shouldShowCerradoSatelliteOverlay({
  required LayerType activeLayer,
  required InpeSatelliteOverlayMode overlayMode,
  required bool isOnline,
  required double? cameraLat,
  required double? cameraLng,
}) {
  return activeLayer == LayerType.satellite &&
      overlayMode == InpeSatelliteOverlayMode.cerradoInpe &&
      isOnline &&
      cameraLat != null &&
      cameraLng != null &&
      CerradoSatelliteOverlay.isWithinBounds(cameraLat, cameraLng);
}

/// Mosaico Brasil 3M — cobre todo o território nacional no WMS INPE.
bool shouldShowBrazilSatelliteMosaicOverlay({
  required LayerType activeLayer,
  required InpeSatelliteOverlayMode overlayMode,
  required bool isOnline,
  required double? cameraLat,
  required double? cameraLng,
}) {
  return activeLayer == LayerType.satellite &&
      overlayMode == InpeSatelliteOverlayMode.brazilMosaic &&
      isOnline &&
      cameraLat != null &&
      cameraLng != null &&
      BrazilSatelliteMosaicOverlay.isWithinBounds(cameraLat, cameraLng);
}

/// Camada base do mapa. Tile já baixado vem do disco, online ou offline.
/// O que falta continua na rede. O arquivo só sai na exclusão manual.
class MapLayersWidget extends ConsumerStatefulWidget {
  const MapLayersWidget({super.key});

  @override
  ConsumerState<MapLayersWidget> createState() => _MapLayersWidgetState();
}

class _MapLayersWidgetState extends ConsumerState<MapLayersWidget> {
  PersistentOfflineTileProvider? _persistedTiles;
  String? _persistedTilesKey;

  @override
  void dispose() {
    // O TileLayer dono da instância anterior já chamou dispose no provider.
    _persistedTiles = null;
    super.dispose();
  }

  PersistentOfflineTileProvider? _tilesFor({
    required String? offlineRoot,
    required String layerKey,
  }) {
    if (offlineRoot == null) {
      _persistedTiles = null;
      _persistedTilesKey = null;
      return null;
    }
    final key = '$offlineRoot|$layerKey';
    if (_persistedTiles != null && _persistedTilesKey == key) {
      return _persistedTiles;
    }
    final headers = <String, String>{};
    _persistedTilesKey = key;
    _persistedTiles = PersistentOfflineTileProvider(
      offlineRoot: offlineRoot,
      layerKey: layerKey,
      headers: headers,
    );
    return _persistedTiles;
  }

  @override
  Widget build(BuildContext context) {
    final activeLayer = ref.watch(activeLayerProvider);
    final satelliteLabelsEnabled = ref.watch(mapSatelliteLabelsEnabledProvider);
    final overlayMode = ref.watch(inpeSatelliteOverlayModeCtrlProvider);
    final wms = ref.watch(externalWmsLayerProvider);
    final raster = ref.watch(externalRasterLayerProvider);
    final isOnline = ref.watch(isOnlineProvider).asData?.value;
    final offlineRoot = ref.watch(offlineTileCacheRootPathProvider).valueOrNull;
    final cacheService = ref.watch(offlineTileCacheServiceProvider);
    final tileConfig = MapConfig.tileConfigForVisibleLayer(
      activeLayer,
      satelliteLabelsEnabled: satelliteLabelsEnabled,
    );
    final layerKey = cacheService.layerKeyFromTemplate(tileConfig.urlTemplate);
    final camera = ref.watch(mapCameraSnapshotProvider);
    final rasterTemplate = _resolveRasterTemplate(raster);
    final persistedTiles = _tilesFor(
      offlineRoot: offlineRoot,
      layerKey: layerKey,
    );
    final showCerradoOverlay = shouldShowCerradoSatelliteOverlay(
      activeLayer: activeLayer,
      overlayMode: overlayMode,
      isOnline: isOnline == true,
      cameraLat: camera?.center.latitude,
      cameraLng: camera?.center.longitude,
    );
    final showBrazilMosaicOverlay = shouldShowBrazilSatelliteMosaicOverlay(
      activeLayer: activeLayer,
      overlayMode: overlayMode,
      isOnline: isOnline == true,
      cameraLat: camera?.center.latitude,
      cameraLng: camera?.center.longitude,
    );

    return Stack(
      children: [
        TileLayer(
          key: ValueKey('base-tiles-$offlineRoot-$layerKey'),
          urlTemplate: tileConfig.urlTemplate,
          fallbackUrl: tileConfig.fallbackUrl,
          subdomains: tileConfig.subdomains,
          tileProvider: persistedTiles,
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
        if (showCerradoOverlay)
          Opacity(
            opacity: CerradoSatelliteOverlay.defaultOpacity,
            child: TileLayer(
              wmsOptions: WMSTileLayerOptions(
                baseUrl: _normalizeWmsBaseUrl(
                  CerradoSatelliteOverlay.wmsBaseUrl,
                ),
                layers: const [CerradoSatelliteOverlay.layerName],
                format: CerradoSatelliteOverlay.wmsFormat,
                version: CerradoSatelliteOverlay.wmsVersion,
                transparent: CerradoSatelliteOverlay.wmsTransparent,
                crs: _resolveWmsCrs(CerradoSatelliteOverlay.wmsCrs),
              ),
              tileBounds: CerradoSatelliteOverlay.tileBounds,
              userAgentPackageName: MapConfig.userAgent,
              maxZoom: 22,
              maxNativeZoom: 22,
            ),
          ),
        if (showBrazilMosaicOverlay)
          Opacity(
            opacity: BrazilSatelliteMosaicOverlay.defaultOpacity,
            child: TileLayer(
              wmsOptions: WMSTileLayerOptions(
                baseUrl: _normalizeWmsBaseUrl(
                  BrazilSatelliteMosaicOverlay.wmsBaseUrl,
                ),
                layers: const [BrazilSatelliteMosaicOverlay.layerName],
                format: BrazilSatelliteMosaicOverlay.wmsFormat,
                version: BrazilSatelliteMosaicOverlay.wmsVersion,
                transparent: BrazilSatelliteMosaicOverlay.wmsTransparent,
                crs: _resolveWmsCrs(BrazilSatelliteMosaicOverlay.wmsCrs),
                otherParameters: const {
                  'TIME': BrazilSatelliteMosaicOverlay.wmsTimeIso,
                },
              ),
              tileBounds: BrazilSatelliteMosaicOverlay.tileBounds,
              userAgentPackageName: MapConfig.userAgent,
              maxZoom: 22,
              maxNativeZoom: 22,
            ),
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
