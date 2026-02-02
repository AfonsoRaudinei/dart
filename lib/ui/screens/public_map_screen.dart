import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'package:soloforte_app/ui/theme/soloforte_theme.dart';

class PublicMapScreen extends StatelessWidget {
  const PublicMapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        FlutterMap(
          options: const MapOptions(
            initialCenter: LatLng(-23.5505, -46.6333), // SP Default
            initialZoom: 13.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.soloforte.app',
            ),
            // Pins content here if needed
          ],
        ),
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
                const Icon(Icons.public, color: SoloForteColors.greenIOS),
                const SizedBox(width: 8),
                Text(
                  'Mapa Público',
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
