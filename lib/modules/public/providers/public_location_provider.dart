import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'public_location_provider.g.dart';

/// Estado da localização pública
enum PublicLocationStatus {
  initial,
  loading,
  available,
  permissionDenied,
  serviceDisabled,
  error,
}

/// Modelo de dados de localização pública
class PublicLocationState {
  final PublicLocationStatus status;
  final LatLng? position;
  final String? errorMessage;

  const PublicLocationState({
    required this.status,
    this.position,
    this.errorMessage,
  });

  PublicLocationState copyWith({
    PublicLocationStatus? status,
    LatLng? position,
    String? errorMessage,
  }) {
    return PublicLocationState(
      status: status ?? this.status,
      position: position ?? this.position,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// Provider de localização pública (isolado do mapa privado)
@riverpod
class PublicLocationNotifier extends _$PublicLocationNotifier {
  @override
  PublicLocationState build() {
    return const PublicLocationState(status: PublicLocationStatus.initial);
  }

  /// Solicita permissão e obtém localização do usuário
  Future<void> requestLocation() async {
    state = state.copyWith(status: PublicLocationStatus.loading);

    try {
      // 1. Verificar se o serviço de localização está habilitado
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = state.copyWith(
          status: PublicLocationStatus.serviceDisabled,
          errorMessage: 'Serviço de localização desabilitado',
        );
        return;
      }

      // 2. Verificar permissão
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        // Solicitar permissão
        permission = await Geolocator.requestPermission();

        if (permission == LocationPermission.denied) {
          state = state.copyWith(
            status: PublicLocationStatus.permissionDenied,
            errorMessage: 'Permissão de localização negada',
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        state = state.copyWith(
          status: PublicLocationStatus.permissionDenied,
          errorMessage: 'Permissão de localização negada permanentemente',
        );
        return;
      }

      // 3. Obter posição atual
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );

      state = state.copyWith(
        status: PublicLocationStatus.available,
        position: LatLng(position.latitude, position.longitude),
      );
    } catch (e) {
      state = state.copyWith(
        status: PublicLocationStatus.error,
        errorMessage: e.toString(),
      );
    }
  }

  /// Limpa o estado de localização
  void clear() {
    state = const PublicLocationState(status: PublicLocationStatus.initial);
  }
}
