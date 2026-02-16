import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../services/location_service.dart';
import '../domain/location_state.dart';

/// 🎯 PROVIDER DE STREAM DE LOCALIZAÇÃO (REATIVO)
/// 
/// Arquitetura:
/// LocationService → locationStreamProvider → MapUserLocationLayer
/// 
/// Otimizações:
/// - Stream real do sistema (não polling)
/// - autoDispose quando mapa não ativo
/// - distinct para evitar updates duplicados
/// - Apenas MapUserLocationLayer observa
/// 
/// Performance:
/// - Campo parado: 0 rebuilds
/// - Movimento <5m: 0 rebuilds
/// - Movimento >5m: 1 rebuild (somente pin do usuário)
final locationStreamProvider = StreamProvider.autoDispose<LatLng>((ref) {
  final locationService = LocationService();
  
  // Retornar stream do serviço
  // Stream é broadcast, então múltiplos listeners podem observar
  return locationService.locationStream;
});

/// 🔒 PROVIDER DE ESTADO DE LOCALIZAÇÃO
/// 
/// Gerencia estado do GPS (checking, available, denied, disabled)
/// Não é stream - apenas estado
final locationStateProvider = StateNotifierProvider<LocationStateNotifier, LocationState>(
  (ref) => LocationStateNotifier(),
);

class LocationStateNotifier extends StateNotifier<LocationState> {
  LocationStateNotifier() : super(LocationState.checking);

  /// Inicializar GPS (verificar permissões)
  Future<void> init() async {
    state = LocationState.checking;
    
    final locationService = LocationService();
    final isAvailable = await locationService.checkAvailability();
    
    if (isAvailable) {
      state = LocationState.available;
    } else {
      // Verificar qual erro específico
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        state = LocationState.serviceDisabled;
      } else {
        state = LocationState.permissionDenied;
      }
    }
  }

  void setUnavailable() {
    state = LocationState.permissionDenied;
  }

  void setDisabled() {
    state = LocationState.serviceDisabled;
  }
}

/// 🎯 PROVIDER DE POSIÇÃO INICIAL (CACHE)
/// 
/// Usado para centralizar mapa na primeira vez
/// Não é stream - apenas valor único
final initialLocationProvider = FutureProvider.autoDispose<LatLng?>((ref) async {
  final locationService = LocationService();
  return locationService.getCurrentPosition();
});
