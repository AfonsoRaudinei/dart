import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Ease-in câmera no `flutter_map` sem trocar de engine.
///
/// Usa [Ticker] + interpolação LatLng/zoom (Apple Maps-like).
/// Cancela ease anterior se um novo [move] for chamado.
class MapCameraEase {
  MapCameraEase._();

  static Ticker? _activeTicker;
  static Completer<void>? _activeCompleter;

  static void cancel() {
    _activeTicker?.dispose();
    _activeTicker = null;
    if (_activeCompleter != null && !_activeCompleter!.isCompleted) {
      _activeCompleter!.complete();
    }
    _activeCompleter = null;
  }

  static Future<void> move(
    MapController controller, {
    required LatLng to,
    double? zoom,
    Duration duration = const Duration(milliseconds: 480),
    Curve curve = Curves.easeInOutCubic,
  }) {
    cancel();

    final from = controller.camera.center;
    final fromZoom = controller.camera.zoom;
    final toZoom = zoom ?? fromZoom;

    // Já no destino — evita tick desnecessário.
    if ((from.latitude - to.latitude).abs() < 1e-9 &&
        (from.longitude - to.longitude).abs() < 1e-9 &&
        (fromZoom - toZoom).abs() < 1e-6) {
      return Future<void>.value();
    }

    final completer = Completer<void>();
    _activeCompleter = completer;

    late final Ticker ticker;
    ticker = Ticker((elapsed) {
      final t = (elapsed.inMilliseconds / duration.inMilliseconds).clamp(
        0.0,
        1.0,
      );
      final c = curve.transform(t);
      final lat = from.latitude + (to.latitude - from.latitude) * c;
      final lng = from.longitude + (to.longitude - from.longitude) * c;
      final z = fromZoom + (toZoom - fromZoom) * c;
      controller.move(LatLng(lat, lng), z);

      if (t >= 1.0) {
        ticker.dispose();
        if (identical(_activeTicker, ticker)) {
          _activeTicker = null;
        }
        if (!completer.isCompleted) completer.complete();
        if (identical(_activeCompleter, completer)) {
          _activeCompleter = null;
        }
      }
    });

    _activeTicker = ticker;
    ticker.start();
    return completer.future;
  }
}
