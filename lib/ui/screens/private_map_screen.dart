import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/ui/theme/soloforte_theme.dart';

class PrivateMapScreen extends StatelessWidget {
  const PrivateMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-23.5505, -46.6333),
            initialZoom: 15.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.soloforte.app',
            ),
            // User pins, private layers
          ],
        ),
        // Overlays
        Positioned(
          top: 60,
          left: 20,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: SoloForteColors.white.withValues(alpha: 0.9),
              borderRadius: SoloRadius.radiusMd,
              boxShadow: [SoloShadows.shadowSm],
            ),
            child: Row(
              children: [
                const Icon(Icons.shield, color: SoloForteColors.greenIOS),
                const SizedBox(width: 8),
                Text(
                  'SoloForte Privado',
                  style: SoloTextStyles.headingMedium.copyWith(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
