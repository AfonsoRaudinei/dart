import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/design/sf_icons.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../../../screens/map/providers/pin_position_correction_provider.dart';
import '../../../theme/premium/design_tokens.dart';

/// Pin arrastável sobre o mapa durante sessão de correção de posição.
class DraggablePinLayer extends ConsumerStatefulWidget {
  final MapController mapController;

  const DraggablePinLayer({super.key, required this.mapController});

  @override
  ConsumerState<DraggablePinLayer> createState() => _DraggablePinLayerState();
}

class _DraggablePinLayerState extends ConsumerState<DraggablePinLayer> {
  bool _isDragging = false;

  void _handlePanUpdate(DragUpdateDetails details, LatLng basePoint) {
    final screenPoint = widget.mapController.camera.latLngToScreenPoint(
      basePoint,
    );
    final movedPoint = math.Point<double>(
      screenPoint.x + details.delta.dx,
      screenPoint.y + details.delta.dy,
    );
    final newLatLng = widget.mapController.camera.pointToLatLng(movedPoint);
    ref.updatePinCorrectionCurrent(newLatLng);
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(pinPositionCorrectionProvider);
    if (session == null) return const SizedBox.shrink();

    final current = ref.watch(
      pinPositionCorrectionProvider.select((s) => s?.current),
    );
    if (current == null) return const SizedBox.shrink();

    // Reposiciona o pin quando a câmera move (pan/zoom).
    ref.watch(mapCameraSnapshotProvider);

    final screenPoint = widget.mapController.camera.latLngToScreenPoint(
      current,
    );
    const hitWidth = 48.0;
    const hitHeight = 52.0;
    const pinIconSize = 36.0;

    return Positioned(
      left: screenPoint.x - (hitWidth / 2),
      top: screenPoint.y - hitHeight,
      width: hitWidth,
      height: hitHeight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: (_) {
            setState(() => _isDragging = true);
            HapticFeedback.selectionClick();
          },
          onPanUpdate: (details) {
            final base = ref.read(pinPositionCorrectionProvider)!.current;
            _handlePanUpdate(details, base);
          },
          onPanEnd: (_) => setState(() => _isDragging = false),
          onPanCancel: () => setState(() => _isDragging = false),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Icon(
              SFIcons.pinFill,
              size: pinIconSize,
              color: _isDragging
                  ? PremiumTokens.brandGreen.withValues(alpha: 0.85)
                  : PremiumTokens.brandGreen,
              shadows: const [
                Shadow(
                  color: Color(0x66000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
          ),
        ),
    );
  }
}
