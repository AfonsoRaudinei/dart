import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

enum SyncPriority {
  immediate, // User-triggered, high priority
  normal, // System event (connectivity back)
  background, // Low priority/periodic
}

abstract class SyncModule {
  String get name;
  Future<void> sync();
}

class SyncOrchestrator extends ChangeNotifier {
  final Ref _ref;
  final List<SyncModule> _modules = [];
  bool _isSyncing = false;
  Timer? _periodicTimer;

  // 🛡 LIFECYCLE: Flag para evitar notifyListeners() após dispose().
  // Future.delayed(3s) no finally de triggerSync() pode executar
  // depois que o ChangeNotifier foi descartado, causando StateError.
  bool _isDisposed = false;

  // Monitoring
  double _progress = 0;
  String? _lastError;

  SyncOrchestrator(this._ref) {
    _initObservers();
  }

  bool get isSyncing => _isSyncing;
  double get progress => _progress;
  String? get lastError => _lastError;

  void registerModule(SyncModule module) {
    _modules.add(module);
  }

  void _initObservers() {
    // Listen to connectivity changes
    _ref.listen<AsyncValue<bool>>(connectivityStateProvider, (previous, next) {
      next.whenData((isConnected) {
        if (isConnected) {
          triggerSync(SyncPriority.normal);
        }
      });
    });

    // periodic background sync
    _periodicTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      triggerSync(SyncPriority.background);
    });
  }

  Future<void> triggerSync(SyncPriority priority) async {
    if (_isSyncing && priority != SyncPriority.immediate) return;

    // Connectivity check
    final connectivity = _ref.read(connectivityServiceProvider);
    final isConnected = await connectivity.isConnected;
    if (!isConnected) return;

    _isSyncing = true;
    _progress = 0;
    _lastError = null;
    notifyListeners();

    try {
      // Execute registered modules
      int completed = 0;
      if (_modules.isEmpty) return;

      for (final module in _modules) {
        try {
          await module.sync();
        } catch (e) {
          AppLogger.warning(
            'Sync Error in ${module.name}',
            tag: 'SyncOrchestrator',
            error: e,
          );
          _lastError = 'Erro em ${module.name}: $e';
        }
        completed++;
        _progress = completed / _modules.length;
        notifyListeners();
      }
    } finally {
      _isSyncing = false;
      _progress = 1.0;
      notifyListeners();

      // Reset progress after a delay
      Future.delayed(const Duration(seconds: 3), () {
        // 🛡 LIFECYCLE GUARD: ChangeNotifier pode ter sido descartado
        // antes do delay completar. Chamar notifyListeners() após
        // dispose() lanca StateError.
        if (_isDisposed || _isSyncing) return;
        _progress = 0;
        notifyListeners();
      });
    }
  }

  @override
  void dispose() {
    // 🛡 Marcar como disposed ANTES de cancelar o timer
    // para que qualquer callback pendente seja descartado.
    _isDisposed = true;
    _periodicTimer?.cancel();
    super.dispose();
  }
}

final syncOrchestratorProvider = ChangeNotifierProvider<SyncOrchestrator>((
  ref,
) {
  return SyncOrchestrator(ref);
});
