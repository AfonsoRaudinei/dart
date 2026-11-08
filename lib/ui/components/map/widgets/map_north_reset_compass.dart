import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/design/sf_icons.dart';
import '../../../../core/state/map_ui_providers.dart';
import '../../../../modules/map/presentation/providers/map_location_mode_provider.dart';

/// Botão discreto de reset norte (estilo Google Maps) quando o mapa está
/// rotacionado em modo explorar ([MapLocationMode.idle]).
class MapNorthResetCompass extends ConsumerWidget {
  const MapNorthResetCompass({
    super.key,
    required this.mapController,
  });

  final MapController mapController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rotationDeg = ref.watch(mapCameraRotationProvider);
    final locationMode = ref.watch(mapLocationModeProvider);

    if (locationMode != MapLocationMode.idle) {
      return const SizedBox.shrink();
    }
    if (rotationDeg.abs() <= kMapNorthCompassVisibleRotationDeg) {
      return const SizedBox.shrink();
    }

    final safeTop = MediaQuery.paddingOf(context).top;

    return Positioned(
      top: safeTop + kMapNorthCompassTopBelowSafeArea,
      right: kMapTopControlsRightInset,
      child: Semantics(
        button: true,
        label: 'Apontar mapa para o norte',
        child: GestureDetector(
          key: const Key('map_north_reset_compass_btn'),
          onTap: () {
            HapticFeedback.lightImpact();
            mapController.rotate(0);
            ref.read(mapCameraRotationProvider.notifier).state = 0;
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: kMapActionColumnButtonSize,
            height: kMapActionColumnButtonSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: -rotationDeg * math.pi / 180,
              child: const Icon(
                SFIcons.nearMe,
                size: 22,
                color: Color(0xFF1976D2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
