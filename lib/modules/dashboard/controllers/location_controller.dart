import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../domain/location_state.dart';

/// Provider do estado de localização
final locationStateProvider = StateProvider<LocationState>(
  (ref) => LocationState.checking,
);

/// Provider da posição atual do usuário
final userPositionProvider = StateProvider<LatLng?>((ref) => null);

/// Controller responsável por gerenciar o estado GPS/Localização
/// Validação e dependência obrigatória do mapa
class LocationController {
  final WidgetRef ref;

  LocationController(this.ref);

  /// Inicializa verificação do GPS
  /// Deve ser chamado ao carregar o PrivateMapScreen
  Future<void> init() async {
    ref.read(locationStateProvider.notifier).state = LocationState.checking;

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

    // 3. Tudo OK
    ref.read(locationStateProvider.notifier).state = LocationState.available;
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
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      // Armazenar posição no provider para renderização no mapa
      ref.read(userPositionProvider.notifier).state = LatLng(
        position.latitude,
        position.longitude,
      );

      return position;
    } catch (e) {
      // Em caso de erro, retorna null
      return null;
    }
  }
}
