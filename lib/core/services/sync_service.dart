import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/presentation/controllers/occurrence_controller.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';

/// 🔄 Serviço de Sincronização Silenciosa
///
/// Princípios:
/// ✅ NUNCA bloqueia o usuário
/// ✅ NUNCA mostra UI (sem banners, sem alerts)
/// ✅ Best effort - falha silenciosamente, tenta depois
/// ✅ LOCAL SEMPRE GANHA (updated_at mais recente)
///
/// Ordem de Sync (FIXA):
/// 1. Visitas
/// 2. Ocorrências
/// 3. Relatórios
///
/// Disparo Automático:
/// - App em foreground
/// - App retomado do background
/// - Conectividade detectada
class SyncService {
  final Ref _ref;
  Timer? _syncTimer;
  bool _isSyncing = false;

  SyncService(this._ref) {
    _init();
  }

  void _init() {
    // Listener de conectividade
    _ref.listen<AsyncValue<bool>>(connectivityStateProvider, (previous, next) {
      next.whenData((isConnected) {
        if (isConnected && !_isSyncing) {
          // Conectividade restaurada → tentar sync
          scheduleMicrotask(() => _performSync());
        }
      });
    });

    // Sync periódico em background (a cada 5 minutos se conectado)
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (_) async {
      if (!_isSyncing) {
        final connectivityService = _ref.read(connectivityServiceProvider);
        final isConnected = await connectivityService.isConnected;
        if (isConnected) {
          await _performSync();
        }
      }
    });
  }

  /// Força sync manual (silencioso)
  Future<void> sync() async {
    await _performSync();
  }

  Future<void> _performSync() async {
    if (_isSyncing) return; // Evita sync concorrente

    _isSyncing = true;

    try {
      // 🔄 Ordem fixa: Visitas → Ocorrências → Relatórios

      // 1️⃣ Sync Visitas
      await _syncVisits();

      // 2️⃣ Sync Ocorrências
      await _syncOccurrences();

      // 3️⃣ Sync Relatórios (TODO: implementar quando Reports estiver pronto)
      // await _syncReports();

      print('🔄 Sync completo (silencioso)');
    } catch (e) {
      // Falha silenciosa - apenas log, sem UI
      print('⚠️ Sync falhou (será retentado): $e');
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncVisits() async {
    try {
      // TODO: Implementar quando VisitController tiver método de sync
      // final visitController = _ref.read(visitControllerProvider.notifier);
      // await visitController.syncPendingVisits();
      print('🔄 Sync Visitas: aguardando implementação');
    } catch (e) {
      print('⚠️ Sync Visitas falhou: $e');
    }
  }

  Future<void> _syncOccurrences() async {
    try {
      // TODO: Implementar quando OccurrenceController tiver método de sync
      // final occurrenceController = _ref.read(occurrenceControllerProvider);
      // await occurrenceController.syncPendingOccurrences();
      print('🔄 Sync Ocorrências: aguardando implementação');
    } catch (e) {
      print('⚠️ Sync Ocorrências falhou: $e');
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}

/// Provider do serviço de sync
final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Provider para trigger manual de sync (retorna Future<void>)
final manualSyncProvider = FutureProvider<void>((ref) async {
  final syncService = ref.read(syncServiceProvider);
  await syncService.sync();
});
