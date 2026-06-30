import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart';

/// Provider do serviço de conectividade
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

/// Provider do estado de conectividade (stream)
///
/// Retorna true quando online, false quando offline
/// Usado para o indicador visual (círculo verde/vermelho) no mapa
final isOnlineProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});
