import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'i_radar_overlay_controller.dart';

final radarOverlayControllerProvider = Provider<IRadarOverlayController>((ref) {
  return const _NoRadarOverlayController();
});

class _NoRadarOverlayController implements IRadarOverlayController {
  const _NoRadarOverlayController();

  @override
  bool readEnabled() => false;

  @override
  void setEnabled(bool enabled, {bool preferSatelliteLayer = false}) {}
}
