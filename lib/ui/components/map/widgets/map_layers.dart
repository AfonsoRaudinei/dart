import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/config/map_config.dart';
import '../../../../core/config/map_secrets.dart';
import '../../../../core/utils/map_logger.dart';

/// Widget que observa apenas activeLayerProvider e renderiza o TileLayer.
/// Rebuild isolado quando a camada muda.
class MapLayersWidget extends ConsumerWidget {
  const MapLayersWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLayer = ref.watch(activeLayerProvider);
    final tileConfig = MapConfig.tileConfigForLayer(
      activeLayer,
      mapTilerApiKey: kMapTilerApiKey,
    );

    return TileLayer(
      urlTemplate: tileConfig.urlTemplate,
      fallbackUrl: tileConfig.fallbackUrl,
      subdomains: tileConfig.subdomains,
      userAgentPackageName: MapConfig.userAgent,
      maxZoom: tileConfig.maxZoom,
      maxNativeZoom: tileConfig.maxNativeZoom,
      retinaMode: tileConfig.retinaMode && RetinaMode.isHighDensity(context),
      keepBuffer: 3,
      panBuffer: 1,
      errorTileCallback: (tile, error, stackTrace) {
        MapLogger.logError('Tile error on $activeLayer: $error', stackTrace);
      },
    );
  }
}
