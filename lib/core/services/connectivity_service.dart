import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 🌐 Serviço de monitoramento de conectividade (silencioso)
///
/// Responsabilidades:
/// - Detectar mudanças de conectividade
/// - Notificar quando conectividade está disponível
/// - **SEM UI** - apenas notifica via provider/callback
class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _connectivityController = StreamController<bool>.broadcast();

  ConnectivityService() {
    _init();
  }

  void _init() {
    // Listener de mudanças de conectividade
    _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      final isConnected = results.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet,
      );

      _connectivityController.add(isConnected);
    });
  }

  /// Stream de conectividade (true = conectado, false = desconectado)
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Verifica conectividade atual (NÃO bloqueia)
  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      return results.any(
        (result) =>
            result == ConnectivityResult.wifi ||
            result == ConnectivityResult.mobile ||
            result == ConnectivityResult.ethernet,
      );
    } catch (e) {
      // Em caso de erro, assume desconectado (safe mode)
      return false;
    }
  }

  void dispose() {
    _connectivityController.close();
  }
}

/// Provider do serviço de conectividade
final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  final service = ConnectivityService();
  ref.onDispose(service.dispose);
  return service;
});

/// Provider do estado de conectividade (true/false)
final connectivityStateProvider = StreamProvider<bool>((ref) {
  final service = ref.watch(connectivityServiceProvider);
  return service.connectivityStream;
});
