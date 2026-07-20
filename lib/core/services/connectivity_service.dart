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
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  ConnectivityService() {
    _init();
  }

  void _init() {
    unawaited(_emitInitialState());

    // Listener de mudanças de conectividade
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((
      List<ConnectivityResult> results,
    ) {
      _connectivityController.add(_hasNetwork(results));
    });
  }

  Future<void> _emitInitialState() async {
    final initialState = await isConnected;
    if (!_connectivityController.isClosed) {
      _connectivityController.add(initialState);
    }
  }

  bool _hasNetwork(List<ConnectivityResult> results) {
    return results.any(
      (result) =>
          result == ConnectivityResult.wifi ||
          result == ConnectivityResult.mobile ||
          result == ConnectivityResult.ethernet,
    );
  }

  /// Stream de conectividade (true = conectado, false = desconectado)
  Stream<bool> get connectivityStream => _connectivityController.stream;

  /// Verifica conectividade atual (NÃO bloqueia)
  Future<bool> get isConnected async {
    try {
      final results = await _connectivity.checkConnectivity();
      return _hasNetwork(results);
    } catch (e) {
      // Em caso de erro, assume desconectado (safe mode)
      return false;
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
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
