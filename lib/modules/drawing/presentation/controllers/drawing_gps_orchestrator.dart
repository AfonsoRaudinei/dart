import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import 'package:soloforte_app/core/permissions/location_permission_gate.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/drawing_state.dart';
import '../../domain/models/drawing_models.dart';
import '../../domain/services/gps_tracking_service.dart';

/// Orquestra ciclo de vida do GPS tracking no módulo drawing.
///
/// Extraído de [DrawingController] para reduzir acoplamento de estado.
class DrawingGpsOrchestrator extends ChangeNotifier {
  DrawingGpsOrchestrator({
    required GpsTrackingService gpsTrackingService,
    required bool Function() isDisposed,
    required DrawingState Function() currentState,
    required bool Function() startGpsTrackingState,
    required bool Function() finalizeGpsTrackingState,
    required void Function(String message) setErrorMessage,
    required void Function(DrawingGeometry? geometry) setPreviewGeometry,
    required void Function(DrawingOrigin? origin) setImportOrigin,
    required void Function() notifyHost,
  }) : _gpsTrackingService = gpsTrackingService,
       _isDisposed = isDisposed,
       _currentState = currentState,
       _startGpsTrackingState = startGpsTrackingState,
       _finalizeGpsTrackingState = finalizeGpsTrackingState,
       _setErrorMessage = setErrorMessage,
       _setPreviewGeometry = setPreviewGeometry,
       _setImportOrigin = setImportOrigin,
       _notifyHost = notifyHost;

  final GpsTrackingService _gpsTrackingService;
  final bool Function() _isDisposed;
  final DrawingState Function() _currentState;
  final bool Function() _startGpsTrackingState;
  final bool Function() _finalizeGpsTrackingState;
  final void Function(String message) _setErrorMessage;
  final void Function(DrawingGeometry? geometry) _setPreviewGeometry;
  final void Function(DrawingOrigin? origin) _setImportOrigin;
  final void Function() _notifyHost;

  List<LatLng> _gpsVertices = [];
  double _gpsLastAccuracyM = 0.0;
  bool _gpsIsPaused = false;
  bool _gpsOriginReview = false;
  StreamSubscription<Position>? _gpsSub;

  List<LatLng> get gpsVertices => List.unmodifiable(_gpsVertices);
  double get gpsLastAccuracyM => _gpsLastAccuracyM;
  bool get gpsIsPaused => _gpsIsPaused;
  bool get gpsOriginReview => _gpsOriginReview;

  GpsQuality get gpsAccuracyQuality =>
      _gpsTrackingService.classifyAccuracy(_gpsLastAccuracyM);

  Future<void> startGpsTracking() async {
    if (_isDisposed()) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await LocationPermissionGate.request();
    }
    if (permission == LocationPermission.deniedForever ||
        permission == LocationPermission.denied) {
      _setErrorMessage('Permissão de localização negada');
      _notifyHost();
      return;
    }

    await _gpsSub?.cancel();
    _gpsSub = null;

    _gpsVertices = [];
    _gpsLastAccuracyM = 0.0;
    _gpsIsPaused = false;

    final ok = _startGpsTrackingState();
    if (!ok) {
      AppLogger.debug(
        'GPS: falha ao transicionar para gpsTracking',
        tag: 'DrawingGpsOrchestrator',
      );
      return;
    }

    const settings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 2,
    );

    _gpsSub = Geolocator.getPositionStream(locationSettings: settings).listen(
      (Position pos) {
        if (_isDisposed()) return;
        if (_gpsIsPaused) return;
        if (_currentState() != DrawingState.gpsTracking) {
          _gpsSub?.cancel();
          return;
        }

        final result = _gpsTrackingService.processPosition(
          vertices: _gpsVertices,
          newPoint: LatLng(pos.latitude, pos.longitude),
          accuracyM: pos.accuracy,
        );

        _gpsLastAccuracyM = result.lastAccuracyM ?? _gpsLastAccuracyM;
        if (result.accepted) {
          _gpsVertices = result.vertices;
        }
        _notifyHost();
      },
      onError: (Object error) {
        AppLogger.warning(
          'GPS stream error: $error',
          tag: 'DrawingGpsOrchestrator',
        );
        _setErrorMessage('Erro no GPS: verifique o sinal');
        if (!_isDisposed()) {
          _notifyHost();
        }
      },
      cancelOnError: false,
    );

    _notifyHost();
  }

  void pauseGpsTracking() {
    if (_isDisposed()) return;
    _gpsIsPaused = true;
    _notifyHost();
  }

  void resumeGpsTracking() {
    if (_isDisposed()) return;
    _gpsIsPaused = false;
    _notifyHost();
  }

  void undoLastGpsVertex() {
    if (_isDisposed()) return;
    _gpsVertices = _gpsTrackingService.undoLastVertex(_gpsVertices);
    _notifyHost();
  }

  void finalizeGpsTracking() {
    if (_isDisposed()) return;

    final polygon = _gpsTrackingService.finalize(_gpsVertices);
    if (polygon == null) {
      _setErrorMessage(
        'Mínimo de $kGpsMinVertices pontos necessários para finalizar',
      );
      _notifyHost();
      return;
    }

    _gpsSub?.cancel();
    _gpsSub = null;

    _setPreviewGeometry(polygon);
    _setImportOrigin(null);
    _gpsOriginReview = true;

    final ok = _finalizeGpsTrackingState();
    if (!ok) {
      AppLogger.debug(
        'GPS: falha ao transicionar para reviewing',
        tag: 'DrawingGpsOrchestrator',
      );
    }

    _gpsVertices = [];
    _gpsIsPaused = false;
    _notifyHost();
  }

  void addManualGpsPoint(LatLng point) {
    if (_isDisposed()) return;
    if (_currentState() != DrawingState.gpsTracking) {
      AppLogger.debug(
        'addManualGpsPoint ignorado — estado não é gpsTracking',
        tag: 'DrawingGpsOrchestrator',
      );
      return;
    }

    final result = _gpsTrackingService.processPosition(
      vertices: _gpsVertices,
      newPoint: point,
      accuracyM: 0.0,
    );

    _gpsLastAccuracyM = result.lastAccuracyM ?? _gpsLastAccuracyM;
    if (result.accepted) {
      _gpsVertices = result.vertices;
    }
    _notifyHost();
  }

  void cancelTracking() {
    if (_currentState() != DrawingState.gpsTracking) return;
    _gpsSub?.cancel();
    _gpsSub = null;
    _gpsVertices = [];
    _gpsIsPaused = false;
  }

  void clearReviewOrigin() {
    _gpsOriginReview = false;
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    _gpsSub = null;
    super.dispose();
  }
}
