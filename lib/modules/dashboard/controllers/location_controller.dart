import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../domain/location_settings.dart';
import '../domain/location_state.dart';

/// Provider do estado de localização
final locationStateProvider = StateProvider<LocationState>(
  (ref) => LocationState.checking,
);

/// Precisão horizontal da última posição GNSS (metros), quando disponível.
final locationAccuracyProvider = StateProvider<double?>((ref) => null);

/// Controller responsável por gerenciar o estado GPS/Localização
/// Validação e dependência obrigatória do mapa
class LocationController {
  final WidgetRef ref;
  StreamSubscription<Position>? _positionSubscription;

  LocationController(this.ref);

  /// Inicializa verificação do GPS
  /// Deve ser chamado ao carregar o PrivateMapScreen
  Future<void> init() async {
    ref.read(locationStateProvider.notifier).state = LocationState.checking;
    ref.read(locationAccuracyProvider.notifier).state = null;

    // 1. Verificar se o serviço de localização está habilitado
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ref.read(locationStateProvider.notifier).state =
          LocationState.serviceDisabled;
      return;
    }

    // 2. Verificar permissão
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Tentar solicitar permissão
      permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        ref.read(locationStateProvider.notifier).state =
            LocationState.permissionDenied;
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      ref.read(locationStateProvider.notifier).state =
          LocationState.permissionDenied;
      return;
    }

    // 3. Tudo OK — iniciar stream GNSS e obter precisão inicial
    ref.read(locationStateProvider.notifier).state = LocationState.available;
    _startPositionStream();
    await _refreshAccuracy();
  }

  void _startPositionStream() {
    _positionSubscription?.cancel();
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: soloforteGnssLocationSettings,
    ).listen(
      (position) {
        ref.read(locationAccuracyProvider.notifier).state = position.accuracy;
      },
      onError: (_) {},
    );
  }

  Future<void> _refreshAccuracy() async {
    final position = await getCurrentPosition();
    if (position != null) {
      ref.read(locationAccuracyProvider.notifier).state = position.accuracy;
    }
  }

  /// Verifica se GPS está disponível
  /// Usado como guard clause nas funções sensíveis
  bool get isAvailable {
    return ref.read(locationStateProvider) == LocationState.available;
  }

  /// Retorna o estado atual
  LocationState get currentState {
    return ref.read(locationStateProvider);
  }

  /// Obtém posição atual (somente se GPS disponível)
  /// Retorna null se GPS indisponível
  Future<Position?> getCurrentPosition() async {
    if (!isAvailable) return null;

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: soloforteGnssLocationSettings,
      );
      ref.read(locationAccuracyProvider.notifier).state = position.accuracy;
      return position;
    } catch (e) {
      // Em caso de erro, retorna null
      return null;
    }
  }

  void dispose() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }
}
