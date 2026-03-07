import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:soloforte_app/core/services/sync_orchestrator.dart';

class SyncService {
  final Ref _ref;
  Timer? _syncTimer;
  bool _isSyncing = false;

  // 🛡 LIFECYCLE: Flag para evitar _ref.read() após invalidação do Ref.
  // Timer.periodic de 5min pode disparar depois que o provider
  // foi descartado, causando BadState no _ref.read().
  bool _isDisposed = false;

  SyncService(this._ref) {
    _init();
  }

  void _init() {
    _ref.listen<AsyncValue<bool>>(connectivityStateProvider, (previous, next) {
      next.whenData((isConnected) {
        if (isConnected && !_isSyncing) {
          scheduleMicrotask(() => _performSync());
        }
      });
    });

    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      // 🛡 LIFECYCLE GUARD: Ref pode estar invalidado se o provider
      // foi descartado antes do timer disparar.
      if (_isDisposed || _isSyncing) return;
      try {
        final connectivityService = _ref.read(connectivityServiceProvider);
        final isConnected = await connectivityService.isConnected;
        if (!_isDisposed && isConnected) {
          await _performSync();
        }
      } catch (_) {
        // Ref inválido ou provider descartado — ignorar silenciosamente.
      }
    });
  }

  Future<void> sync() async {
    await _performSync();
  }

  Future<void> _performSync() async {
    if (_isSyncing) return;

    _isSyncing = true;

    try {
      await _ref
          .read(syncOrchestratorProvider)
          .triggerSync(SyncPriority.immediate);

      AppLogger.debug('Sync completo', tag: 'SyncService');
    } catch (e) {
      AppLogger.warning(
        'Sync falhou (será retentado)',
        tag: 'SyncService',
        error: e,
      );
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    // 🛡 Marcar como disposed ANTES de cancelar o timer.
    _isDisposed = true;
    _syncTimer?.cancel();
  }
}

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(ref);
  ref.onDispose(service.dispose);
  return service;
});

final manualSyncProvider = FutureProvider<void>((ref) async {
  final syncService = ref.read(syncServiceProvider);
  await syncService.sync();
});
