import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/providers/connectivity_provider.dart';
import '../../domain/clima_cloud_extract.dart';
import '../providers/radar_providers.dart';

/// Camada de nuvens (infravermelho global) no mesmo toggle do radar.
///
/// Fica sob o radar de chuva: topos frios aparecem em branco e a superfície
/// quente fica transparente, então talhões e o mapa base continuam legíveis.
class ClimaCloudTileLayerWidget extends ConsumerWidget {
  final TileProvider? tileProvider;

  const ClimaCloudTileLayerWidget({super.key, this.tileProvider});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled = ref.watch(climaRadarEnabledProvider);
    final isOnline = ref.watch(isOnlineProvider).asData?.value ?? false;
    if (!enabled || !isOnline) return const SizedBox.shrink();

    final frameAsync = ref.watch(climaCloudFrameProvider);
    return frameAsync.when(
      data: (frame) {
        return ColorFiltered(
          colorFilter: ColorFilter.matrix(climaCloudExtractMatrix),
          child: TileLayer(
            urlTemplate: frame.urlTemplate,
            userAgentPackageName: MapConfig.userAgent,
            maxNativeZoom: MapConfig.realEarthCloudMaxNativeZoom,
            maxZoom: MapConfig.rainViewerMaxZoom,
            tileDisplay: const TileDisplay.instantaneous(),
            tileProvider: tileProvider,
            subdomains: const [],
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
