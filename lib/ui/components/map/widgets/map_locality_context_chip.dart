import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design/sf_icons.dart';
import '../../../../core/services/geocoding/reverse_geocoder.dart';
import '../../../../core/state/map_state.dart';
import '../../../../core/state/map_ui_providers.dart';

/// Chip discreto com o município próximo ao centro do mapa (divisas UF ativas).
class MapLocalityContextChip extends ConsumerStatefulWidget {
  const MapLocalityContextChip({super.key});

  @override
  ConsumerState<MapLocalityContextChip> createState() =>
      _MapLocalityContextChipState();
}

class _MapLocalityContextChipState extends ConsumerState<MapLocalityContextChip> {
  static const Duration _debounce = Duration(milliseconds: 400);
  static const double _minCenterDeltaDegrees = 0.002;

  Timer? _timer;
  String _label = '…';
  double? _lastScheduledLat;
  double? _lastScheduledLon;
  String? _resolvedKey;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _scheduleLookup(double latitude, double longitude) {
    if (_lastScheduledLat != null &&
        _lastScheduledLon != null &&
        (latitude - _lastScheduledLat!).abs() < _minCenterDeltaDegrees &&
        (longitude - _lastScheduledLon!).abs() < _minCenterDeltaDegrees) {
      return;
    }

    _lastScheduledLat = latitude;
    _lastScheduledLon = longitude;

    final key =
        '${latitude.toStringAsFixed(3)},${longitude.toStringAsFixed(3)}';
    if (key == _resolvedKey) return;

    _timer?.cancel();
    _timer = Timer(_debounce, () async {
      final label = await ReverseGeocoder.instance.resolveCityLabel(
        latitude: latitude,
        longitude: longitude,
      );
      if (!mounted) return;
      setState(() {
        _label = label;
        _resolvedKey = key;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(mapStateBoundariesEnabledProvider)) {
      return const SizedBox.shrink();
    }

    final camera = ref.watch(mapCameraSnapshotProvider);
    ref.listen(mapCameraSnapshotProvider, (previous, next) {
      if (next == null) return;
      _scheduleLookup(next.center.latitude, next.center.longitude);
    });

    if (camera != null) {
      _scheduleLookup(camera.center.latitude, camera.center.longitude);
    }

    final top = MediaQuery.paddingOf(context).top + 8;
    final semanticsLabel = 'Município próximo: $_label';

    return Positioned(
      top: top,
      left: 12,
      right: 168,
      child: Semantics(
        label: semanticsLabel,
        child: Material(
          type: MaterialType.transparency,
          child: Container(
            key: const Key('map_locality_context_chip'),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  SFIcons.pinFill,
                  size: 14,
                  color: Colors.white.withValues(alpha: 0.92),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    _label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.92),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
