import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/config/map_config.dart';
import '../../../../core/design/sf_icons.dart';
import '../../../theme/premium/design_tokens.dart';

enum MapOverlayPreviewKind { pins, rain }

/// Miniatura de camada base (Satélite / Relevo).
class MapLayerPreviewTile extends StatelessWidget {
  const MapLayerPreviewTile({
    super.key,
    required this.width,
    required this.height,
    required this.tileConfig,
    required this.label,
    required this.isSelected,
    required this.renderTilePreview,
    required this.onTap,
  });

  final double width;
  final double height;
  final MapLayerTileConfig tileConfig;
  final String label;
  final bool isSelected;
  final bool renderTilePreview;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MapLayerGridTile(
      width: width,
      height: height,
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      child: MiniSatelliteMapPreview(
        tileConfig: tileConfig,
        renderTilePreview: renderTilePreview,
      ),
    );
  }
}

/// Tile de toggle para Pinos e Radar — preview alinhado às miniaturas de mapa.
class MapOverlayPreviewTile extends StatelessWidget {
  const MapOverlayPreviewTile({
    super.key,
    required this.width,
    required this.height,
    required this.label,
    required this.kind,
    required this.isSelected,
    required this.renderTilePreview,
    required this.tileConfig,
    required this.onTap,
  });

  final double width;
  final double height;
  final String label;
  final MapOverlayPreviewKind kind;
  final bool isSelected;
  final bool renderTilePreview;
  final MapLayerTileConfig tileConfig;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return MapLayerGridTile(
      width: width,
      height: height,
      label: label,
      isSelected: isSelected,
      onTap: onTap,
      child: Stack(
        fit: StackFit.expand,
        children: [
          MiniSatelliteMapPreview(
            tileConfig: tileConfig,
            renderTilePreview: renderTilePreview,
          ),
          switch (kind) {
            MapOverlayPreviewKind.pins =>
              PinsOverlayPreview(active: isSelected),
            MapOverlayPreviewKind.rain =>
              RainOverlayPreview(active: isSelected),
          },
        ],
      ),
    );
  }
}

class MiniSatelliteMapPreview extends StatelessWidget {
  static const _accent = PremiumTokens.brandGreenDark;

  const MiniSatelliteMapPreview({
    super.key,
    required this.tileConfig,
    required this.renderTilePreview,
  });

  final MapLayerTileConfig tileConfig;
  final bool renderTilePreview;

  @override
  Widget build(BuildContext context) {
    if (!renderTilePreview) {
      return DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.18),
              _accent.withValues(alpha: 0.16),
            ],
          ),
        ),
        child: const Center(
          child: Icon(
            Icons.map_outlined,
            color: Colors.white54,
            size: 22,
          ),
        ),
      );
    }

    return FlutterMap(
      options: const MapOptions(
        initialCenter: LatLng(-10.69, -48.39),
        initialZoom: 13.0,
        interactionOptions: InteractionOptions(
          flags: InteractiveFlag.none,
        ),
      ),
      children: [
        TileLayer(
          urlTemplate: tileConfig.urlTemplate,
          fallbackUrl: tileConfig.fallbackUrl,
          subdomains: tileConfig.subdomains,
          maxZoom: tileConfig.maxZoom,
          maxNativeZoom: tileConfig.maxNativeZoom,
          retinaMode:
              tileConfig.retinaMode && RetinaMode.isHighDensity(context),
        ),
      ],
    );
  }
}

class PinsOverlayPreview extends StatelessWidget {
  const PinsOverlayPreview({super.key, required this.active});

  final bool active;

  static const _pinColorActive = Color(0xFF34C759);
  static const _pinColorInactive = Color(0x99FFFFFF);

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (!active)
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.42),
            ),
          ),
        Positioned(
          left: 14,
          top: 12,
          child: _PreviewPin(active: active, size: 17),
        ),
        Positioned(
          right: 16,
          top: 22,
          child: _PreviewPin(active: active, size: 14),
        ),
        Positioned(
          left: 24,
          bottom: 10,
          child: _PreviewPin(active: active, size: 15),
        ),
      ],
    );
  }
}

class _PreviewPin extends StatelessWidget {
  const _PreviewPin({required this.active, required this.size});

  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        SFIcons.pinFill,
        size: size,
        color: active
            ? PinsOverlayPreview._pinColorActive
            : PinsOverlayPreview._pinColorInactive,
      ),
    );
  }
}

class RainOverlayPreview extends StatelessWidget {
  const RainOverlayPreview({super.key, required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        if (active)
          const CustomPaint(painter: _RadarBlobsPainter())
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.38),
            ),
            child: Center(
              child: Icon(
                Icons.wb_cloudy_outlined,
                size: 26,
                color: Colors.white.withValues(alpha: 0.28),
              ),
            ),
          ),
      ],
    );
  }
}

class _RadarBlobsPainter extends CustomPainter {
  const _RadarBlobsPainter();

  static void _blob(Canvas canvas, Offset center, double radius, Color color) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: 0.62),
          color.withValues(alpha: 0.18),
          color.withValues(alpha: 0.0),
        ],
        stops: const [0.0, 0.55, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    _blob(
      canvas,
      Offset(size.width * 0.34, size.height * 0.46),
      size.width * 0.34,
      const Color(0xFF007AFF),
    );
    _blob(
      canvas,
      Offset(size.width * 0.68, size.height * 0.52),
      size.width * 0.28,
      const Color(0xFF5AC8FA),
    );
    _blob(
      canvas,
      Offset(size.width * 0.5, size.height * 0.28),
      size.width * 0.2,
      const Color(0xFF64D2FF),
    );
  }

  @override
  bool shouldRepaint(covariant _RadarBlobsPainter oldDelegate) => false;
}

/// Moldura unificada dos quatro tiles da grade (satélite, relevo, pinos, chuva).
class MapLayerGridTile extends StatelessWidget {
  static const _accent = PremiumTokens.brandGreenDark;
  static const _radius = 12.0;
  static const _borderWidth = 2.0;

  const MapLayerGridTile({
    super.key,
    required this.width,
    required this.height,
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.child,
  });

  final double width;
  final double height;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        children: [
          SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(_radius),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(child: child),
                  if (isSelected)
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(_radius),
                          border: Border.all(
                            color: _accent,
                            width: _borderWidth,
                          ),
                        ),
                      ),
                    ),
                  if (isSelected)
                    const Positioned(
                      top: 4,
                      right: 4,
                      child: _LayerSelectedBadge(),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: width,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LayerSelectedBadge extends StatelessWidget {
  const _LayerSelectedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(
        color: PremiumTokens.brandGreenDark,
        shape: BoxShape.circle,
      ),
      child: const Icon(Icons.check, color: Colors.white, size: 12),
    );
  }
}
