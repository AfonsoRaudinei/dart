import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_sync_service.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_sync_service.dart';

class SyncService {
  final Ref _ref;
  Timer? _syncTimer;
  bool _isSyncing = false;

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
      if (!_isSyncing) {
        final connectivityService = _ref.read(connectivityServiceProvider);
        final isConnected = await connectivityService.isConnected;
        if (isConnected) {
          await _performSync();
        }
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
      await _syncVisits();
      await _syncOccurrences();

      AppLogger.debug('Sync completo', tag: 'SyncService');
    } catch (e) {
      AppLogger.warning('Sync falhou (será retentado)', tag: 'SyncService', error: e);
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncVisits() async {
    try {
      final supabase = Supabase.instance.client;
      final visitSync = VisitSyncService(supabase);
      await visitSync.syncVisits();
    } catch (e) {
      AppLogger.warning('Sync Visitas falhou', tag: 'SyncService', error: e);
    }
  }

  Future<void> _syncOccurrences() async {
    try {
      final supabase = Supabase.instance.client;
      final occurrenceSync = OccurrenceSyncService(supabase);
      await occurrenceSync.syncOccurrences();
    } catch (e) {
      AppLogger.warning('Sync Ocorrências falhou', tag: 'SyncService', error: e);
    }
  }

  void dispose() {
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
