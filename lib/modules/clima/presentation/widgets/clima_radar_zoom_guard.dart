import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/domain/map_models.dart';
import '../../../../core/state/map_state.dart';
import '../providers/radar_providers.dart';

/// Evita tiles "Zoom Level Not Supported" ao ativar chuva com camada satélite.
///
/// Quando o radar liga e a camada base é satélite (Google sem MapTiler),
/// limita o zoom ao máximo nativo confiável do provedor.
class ClimaRadarZoomGuard extends ConsumerWidget {
  final MapController mapController;

  const ClimaRadarZoomGuard({super.key, required this.mapController});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<bool>(climaRadarEnabledProvider, (previous, enabled) {
      if (previous == enabled || !enabled) return;
      _clampSatelliteZoomIfNeeded(ref);
    });

    ref.listen<LayerType>(activeLayerProvider, (previous, layer) {
      if (previous == layer) return;
      if (!ref.read(climaRadarEnabledProvider)) return;
      if (layer != LayerType.satellite) return;
      _clampSatelliteZoomIfNeeded(ref);
    });

    return const SizedBox.shrink();
  }

  void _clampSatelliteZoomIfNeeded(WidgetRef ref) {
    if (!ref.read(climaRadarEnabledProvider)) return;
    if (ref.read(activeLayerProvider) != LayerType.satellite) return;

    final tileConfig = MapConfig.tileConfigForLayer(
      LayerType.satellite,
      mapTilerApiKey: MapConfig.kMapTilerApiKey,
    );
    final nativeMax = tileConfig.maxNativeZoom.toDouble();
    final currentZoom = mapController.camera.zoom;
    if (currentZoom <= nativeMax) return;

    mapController.move(mapController.camera.center, nativeMax);
  }
}
