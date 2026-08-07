import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

/// Anima movimentos intencionais da câmera (foco / busca / “ir para”).
/// Mantém [flutter_map] — sem pacote extra; GPS follow continua instantâneo.
class MapCameraAnimator {
  MapCameraAnimator({
    required TickerProvider vsync,
    this.duration = const Duration(milliseconds: 550),
    this.curve = Curves.easeInOutCubic,
  }) : _vsync = vsync;

  final TickerProvider _vsync;
  final Duration duration;
  final Curve curve;

  AnimationController? _controller;

  /// Interrompe animação em andamento (ex.: dispose da tela).
  void cancel() {
    _controller?.stop();
    _controller?.dispose();
    _controller = null;
  }

  void dispose() => cancel();

  /// Ease da câmera até [dest] / [zoom] (estilo Apple Maps).
  void animateTo({
    required MapController mapController,
    required LatLng dest,
    required double zoom,
  }) {
    cancel();

    final camera = mapController.camera;
    final latTween = Tween<double>(
      begin: camera.center.latitude,
      end: dest.latitude,
    );
    final lngTween = Tween<double>(
      begin: camera.center.longitude,
      end: dest.longitude,
    );
    final zoomTween = Tween<double>(begin: camera.zoom, end: zoom);

    final controller = AnimationController(vsync: _vsync, duration: duration);
    _controller = controller;

    final animation = CurvedAnimation(parent: controller, curve: curve);

    controller.addListener(() {
      mapController.move(
        LatLng(latTween.evaluate(animation), lngTween.evaluate(animation)),
        zoomTween.evaluate(animation),
      );
    });

    animation.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        controller.dispose();
        if (identical(_controller, controller)) {
          _controller = null;
        }
      }
    });

    controller.forward();
  }
}
