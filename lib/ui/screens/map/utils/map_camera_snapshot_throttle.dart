import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/state/map_ui_providers.dart';

/// Throttle de [mapCameraSnapshotProvider] para evitar rebuild de tiles/offline
/// a cada frame de pan.
///
/// Usa [ProviderContainer] (não [WidgetRef]) para o timer atrasado sobreviver
/// ao dispose do widget do mapa sem crash.
class MapCameraSnapshotThrottle {
  MapCameraSnapshotThrottle._();

  static DateTime? _lastWrite;
  static Timer? _timer;
  static MapCameraSnapshot? _pending;

  static const _interval = Duration(milliseconds: 160);

  static void cancel() {
    _timer?.cancel();
    _timer = null;
    _pending = null;
  }

  static void publish(ProviderContainer container, MapCameraSnapshot snapshot) {
    final current = container.read(mapCameraSnapshotProvider);
    final zoomBucketChanged =
        current == null || current.zoom.floor() != snapshot.zoom.floor();

    // Zoom bucket mudou → publica imediatamente (culling/tiers dependem disso).
    if (zoomBucketChanged) {
      _timer?.cancel();
      _pending = null;
      _lastWrite = DateTime.now();
      container.read(mapCameraSnapshotProvider.notifier).state = snapshot;
      return;
    }

    final now = DateTime.now();
    final elapsed = _lastWrite == null
        ? _interval
        : now.difference(_lastWrite!);

    if (elapsed >= _interval) {
      _lastWrite = now;
      container.read(mapCameraSnapshotProvider.notifier).state = snapshot;
      return;
    }

    _pending = snapshot;
    _timer?.cancel();
    _timer = Timer(_interval - elapsed, () {
      final pending = _pending;
      if (pending == null) return;
      _pending = null;
      _lastWrite = DateTime.now();
      container.read(mapCameraSnapshotProvider.notifier).state = pending;
    });
  }
}
