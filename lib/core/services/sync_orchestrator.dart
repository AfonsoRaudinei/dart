import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/services/sync_module_runner.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

enum SyncPriority {
  immediate, // User-triggered, high priority
  normal, // System event (connectivity back)
  background, // Low priority/periodic
}

abstract class SyncModule {
  String get name;
  Future<void> sync();

  /// Tier 0 executa antes dos demais (ex.: clientes/fazendas).
  /// Tiers > 0 rodam em paralelo dentro do mesmo tier (Fase 6).
  int get syncTier => 1;
}

class SyncOrchestrator extends ChangeNotifier {
  SyncOrchestrator(this._ref, {bool enableObservers = true}) {
    if (enableObservers) {
      _initObservers();
    }
  }

  final Ref _ref;
  final List<SyncModule> _modules = [];
  bool _isSyncing = false;
  bool _pendingImmediateSync = false;
  Timer? _periodicTimer;

  // 🛡 LIFECYCLE: Flag para evitar notifyListeners() após dispose().
  bool _isDisposed = false;

  // Monitoring
  double _progress = 0;
  String? _lastError;
  List<SyncModuleResult> _lastResults = const [];

  bool get isSyncing => _isSyncing;
  double get progress => _progress;
  String? get lastError => _lastError;
  List<SyncModuleResult> get lastResults => _lastResults;

  void registerModule(SyncModule module) {
    _modules.add(module);
  }

  void _initObservers() {
    _ref.listen<AsyncValue<bool>>(connectivityStateProvider, (previous, next) {
      next.whenData((isConnected) {
        if (isConnected) {
          triggerSync(SyncPriority.normal);
        }
      });
    });

    _periodicTimer = Timer.periodic(const Duration(minutes: 15), (_) {
      triggerSync(SyncPriority.background);
    });
  }

  void _notifyIfAlive() {
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  Future<void> triggerSync(SyncPriority priority) async {
    if (_isSyncing) {
      if (priority == SyncPriority.immediate) {
        _pendingImmediateSync = true;
      }
      return;
    }

    final connectivity = _ref.read(connectivityServiceProvider);
    final isConnected = await connectivity.isConnected;
    if (!isConnected || _isDisposed) return;

    _isSyncing = true;
    _progress = 0;
    _lastError = null;
    _lastResults = const [];
    _notifyIfAlive();

    try {
      if (_modules.isEmpty) return;

      _lastResults = await runSyncModulesByTier(
        List<SyncModule>.unmodifiable(_modules),
        onProgress: (completed, total) {
          if (_isDisposed) return;
          _progress = completed / total;
          _notifyIfAlive();
        },
      );

      if (_isDisposed) return;

      final failures = _lastResults.where((result) => !result.success);
      if (failures.isNotEmpty) {
        final first = failures.first;
        AppLogger.warning(
          'Sync Error in ${first.name}',
          tag: 'SyncOrchestrator',
          error: first.error,
        );
        _lastError = 'Erro em ${first.name}: ${first.error}';
      }
    } finally {
      // Sem `return` dentro de finally: engoliria exceções vindas do try.
      if (!_isDisposed) {
        _isSyncing = false;
        _progress = 1.0;
        _notifyIfAlive();

        Future.delayed(const Duration(seconds: 3), () {
          if (_isDisposed || _isSyncing) return;
          _progress = 0;
          _notifyIfAlive();
        });

        if (_pendingImmediateSync) {
          _pendingImmediateSync = false;
          scheduleMicrotask(() => triggerSync(SyncPriority.immediate));
        }
      }
    }
  }

  @override
  void dispose() {
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
