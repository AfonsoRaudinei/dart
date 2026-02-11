import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import '../../theme/soloforte_theme.dart';

/// Controles de zoom manual (+/-) para o mapa público.
///
/// Posicionados verticalmente no canto inferior direito,
/// permite ao usuário aumentar ou diminuir o zoom do mapa.
///
/// **Características:**
/// - Botão "+" para zoom in
/// - Botão "-" para zoom out
/// - Respeita limites min/max do mapa
/// - Feedback visual ao tocar
/// - Design consistente com tema SoloForte
class ZoomControls extends StatelessWidget {
  final MapController mapController;
  final double minZoom;
  final double maxZoom;

  const ZoomControls({
    super.key,
    required this.mapController,
    this.minZoom = 3.0,
    this.maxZoom = 18.0,
  });

  void _zoomIn() {
    final currentZoom = mapController.camera.zoom;
    if (currentZoom < maxZoom) {
      final newZoom = (currentZoom + 1).clamp(minZoom, maxZoom);
      mapController.move(mapController.camera.center, newZoom);
    }
  }

  void _zoomOut() {
    final currentZoom = mapController.camera.zoom;
    if (currentZoom > minZoom) {
      final newZoom = (currentZoom - 1).clamp(minZoom, maxZoom);
      mapController.move(mapController.camera.center, newZoom);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Controles de zoom do mapa',
      child: Container(
        decoration: BoxDecoration(
        color: SoloForteColors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão Zoom In (+)
          Semantics(
            label: 'Aumentar zoom',
            button: true,
            child: _ZoomButton(icon: Icons.add, onTap: _zoomIn, isTop: true),
          ),
          // Divider
          Container(height: 1, color: SoloForteColors.borderLight),
          // Botão Zoom Out (-)
          Semantics(
            label: 'Diminuir zoom',
            button: true,
            child: _ZoomButton(icon: Icons.remove, onTap: _zoomOut, isTop: false),
          ),
        ],
      ),
      ),
    );
  }
}

/// Botão individual de zoom (interno)
class _ZoomButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isTop;

  const _ZoomButton({
    required this.icon,
    required this.onTap,
    required this.isTop,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.vertical(
            top: isTop ? const Radius.circular(8) : Radius.zero,
            bottom: !isTop ? const Radius.circular(8) : Radius.zero,
          ),
          child: Icon(icon, color: SoloForteColors.textPrimary, size: 24),
        ),
      ),
    );
  }
}
