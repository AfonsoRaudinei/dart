import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Widget base do FlutterMap.
/// Não observa providers — recebe tudo por parâmetros.
class MapCanvas extends StatelessWidget {
  final MapController mapController;
  final VoidCallback onMapReady;
  final Function(TapPosition, LatLng) onTap;
  final Function(MapCamera, bool) onPositionChanged;
  final List<Widget> children;

  const MapCanvas({
    super.key,
    required this.mapController,
    required this.onMapReady,
    required this.onTap,
    required this.onPositionChanged,
    required this.children,
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
        maxZoom: 19.0,
        onTap: onTap,
        onPositionChanged: onPositionChanged,
        interactionOptions: const InteractionOptions(
          flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
        ),
      ),
      children: children,
    );
  }
}
