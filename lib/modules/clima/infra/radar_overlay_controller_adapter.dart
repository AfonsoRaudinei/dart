import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/contracts/i_radar_overlay_controller.dart';
import '../../../core/domain/map_models.dart';
import '../../../core/state/map_state.dart';
import '../presentation/providers/radar_providers.dart';

class RadarOverlayControllerAdapter implements IRadarOverlayController {
  RadarOverlayControllerAdapter(this._ref);

  final Ref _ref;

  @override
  bool readEnabled() => _ref.read(climaRadarEnabledProvider);

  @override
  void setEnabled(bool enabled, {bool preferSatelliteLayer = false}) {
    _ref.read(climaRadarEnabledProvider.notifier).setEnabled(enabled);

    if (!enabled || !preferSatelliteLayer) return;

    final currentLayer = _ref.read(activeLayerProvider);
    if (currentLayer == LayerType.satellite) return;

    _ref.read(activeLayerProvider.notifier).setLayer(LayerType.satellite);
  }
}
