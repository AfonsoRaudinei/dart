import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/config/map_config.dart';

/// Widget base do FlutterMap.
/// Não observa providers — recebe tudo por parâmetros.
class MapCanvas extends StatelessWidget {
  final MapController mapController;
  final VoidCallback onMapReady;
  final Function(TapPosition, LatLng) onTap;
  final Function(TapPosition, LatLng)? onLongPress;
  final Function(MapCamera, bool) onPositionChanged;
  final List<Widget> children;
  final InteractionOptions? interactionOptions;
  final double maxZoom;

  const MapCanvas({
    super.key,
    required this.mapController,
    required this.onMapReady,
    required this.onTap,
    this.onLongPress,
    required this.onPositionChanged,
    required this.children,
    this.interactionOptions,
    this.maxZoom = MapConfig.maxZoom,
  });

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: mapController,
      options: MapOptions(
        onMapReady: onMapReady,
        initialCenter: const LatLng(-23.5505, -46.6333),
        initialZoom: 14.0,
        minZoom: 4.0,
        maxZoom: maxZoom,
        onTap: onTap,
        onLongPress: onLongPress,
        onPositionChanged: onPositionChanged,
        interactionOptions:
            interactionOptions ??
            const InteractionOptions(
              flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
            ),
      ),
      children: children,
    );
  }
}
