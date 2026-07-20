import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/connectivity_service.dart' as connectivity;

export '../services/connectivity_service.dart'
    show connectivityServiceProvider, connectivityStateProvider;

/// Provider do estado de conectividade (stream)
///
/// Retorna true quando online, false quando offline
/// Usado para o indicador visual (círculo verde/vermelho) no mapa
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final service = ref.watch(connectivity.connectivityServiceProvider);
  yield await service.isConnected;
  yield* service.connectivityStream;
});
