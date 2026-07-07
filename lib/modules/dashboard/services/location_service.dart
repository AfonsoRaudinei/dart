import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/permissions/location_permission_gate.dart';
import 'package:soloforte_app/modules/dashboard/domain/user_location_fix.dart';

typedef PositionStreamFactory =
    Stream<Position> Function(LocationSettings locationSettings);

/// 🌍 SERVIÇO DE LOCALIZAÇÃO GPS - STREAM REAL
///
/// Responsabilidades:
/// - Criar stream do sistema via Geolocator.getPositionStream()
/// - Configurar precisão e filtros
/// - Gerenciar lifecycle do stream
/// - Não conter lógica de UI
///
/// Performance:
/// - distanceFilter: 5m (ideal para agro)
/// - accuracy: best (GNSS multi-constelação via OS)
/// - Stream único (singleton pattern)
class LocationService {
  static LocationService? _instance;
  static PositionStreamFactory _positionStreamFactory = (locationSettings) =>
      Geolocator.getPositionStream(locationSettings: locationSettings);

  StreamController<UserLocationFix>? _controller;
  StreamSubscription<Position>? _subscription;

  // Singleton pattern para evitar múltiplos streams
  factory LocationService() {
    _instance ??= LocationService._();
    return _instance!;
  }

  LocationService._();

  /// Stream de localização GPS (reativo)
  ///
  /// Configuração otimizada para campo:
  /// - Atualiza apenas quando movimento > 5m
  /// - Precisão alta para desenho de talhão
  /// - Não rebuilda se parado
  Stream<UserLocationFix> get locationStream {
    // Criar stream apenas uma vez
    if (_controller == null || _controller!.isClosed) {
      _controller = StreamController<UserLocationFix>.broadcast(onCancel: _onCancel);
      _startListening();
    }

    return _controller!.stream;
  }

  void _startListening() {
    // Configuração de stream do sistema
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.best,
      distanceFilter: 5, // 5 metros (campo parado = zero rebuild)
    );

    _subscription = _positionStreamFactory(locationSettings).listen(
      (Position position) {
        if (_controller != null && !_controller!.isClosed) {
          _controller!.add(
            UserLocationFix(
              position: LatLng(position.latitude, position.longitude),
              accuracyM: position.accuracy,
            ),
          );
        }
      },
      onError: (error) {
        // Emitir erro no stream (widget pode tratar)
        if (_controller != null && !_controller!.isClosed) {
          _controller!.addError(error);
        }
      },
      cancelOnError: false, // Continuar ouvindo mesmo após erro
    );
  }

  void _onCancel() {
    unawaited(_stopListening());
  }

  Future<void> _stopListening() async {
    final subscription = _subscription;
    _subscription = null;

    final controller = _controller;
    _controller = null;

    await subscription?.cancel();
    if (controller != null && !controller.isClosed) {
      await controller.close();
    }
  }

  /// Verificar se GPS está disponível (permissões + service enabled)
  Future<bool> checkAvailability() async {
    // 1. Verificar serviço
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return false;

    // 2. Verificar permissão
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await LocationPermissionGate.request();
      if (permission == LocationPermission.denied) return false;
    }

    if (permission == LocationPermission.deniedForever) return false;

    return true;
  }

  /// Obter posição atual uma vez (sem stream)
  /// Útil para centralizar mapa na primeira vez
  Future<UserLocationFix?> getCurrentPosition() async {
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      ).timeout(const Duration(seconds: 10));
      return UserLocationFix(
        position: LatLng(position.latitude, position.longitude),
        accuracyM: position.accuracy,
      );
    } catch (e) {
      return null;
    }
  }

  void dispose() {
    unawaited(_stopListening());
  }

  @visibleForTesting
  bool get hasActiveNativeStream => _subscription != null;

  @visibleForTesting
  static void debugSetPositionStreamFactory(PositionStreamFactory factory) {
    _positionStreamFactory = factory;
  }

  @visibleForTesting
  static void debugReset() {
    _positionStreamFactory = (locationSettings) =>
        Geolocator.getPositionStream(locationSettings: locationSettings);
    _instance?.dispose();
    _instance = null;
  }
}
