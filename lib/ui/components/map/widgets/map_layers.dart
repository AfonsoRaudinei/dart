import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/domain/map_models.dart';

/// Widget que observa apenas activeLayerProvider e renderiza o TileLayer.
/// Rebuild isolado quando a camada muda.
class MapLayersWidget extends ConsumerWidget {
  const MapLayersWidget({super.key});

  String _getLayerUrl(LayerType type) {
    switch (type) {
      case LayerType.satellite:
        return 'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
      case LayerType.terrain:
        return 'https://b.tile.opentopomap.org/{z}/{x}/{y}.png';
      case LayerType.standard:
        return 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeLayer = ref.watch(activeLayerProvider);

    return TileLayer(
      urlTemplate: _getLayerUrl(activeLayer),
      userAgentPackageName: 'com.soloforte.app',
    );
  }
}
