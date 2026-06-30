import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/config/app_config.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:soloforte_app/core/services/remote_sync_service.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/settings_providers.dart';

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
    if (!AppConfig.hasSupabaseConfig) return;

    final offlineForced = _ref.read(offlineModeProvider);
    if (offlineForced) return;

    _isSyncing = true;

    try {
      final client = Supabase.instance.client;
      if (client.auth.currentSession == null) return;

      final prefs = _ref.read(sharedPreferencesProvider);
      final remoteSync = RemoteSyncService(client, prefs);
      await remoteSync.syncAll();
      _ref.invalidate(pendingSyncCountProvider);
    } catch (e) {
      appLog('⚠️ Sync falhou (será retentado): $e');
    } finally {
      _isSyncing = false;
    }
  }

  void dispose() {
    _syncTimer?.cancel();
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden');
});

final syncServiceProvider = Provider<SyncService>((ref) {
  final service = SyncService(ref);
  ref.onDispose(service.dispose);
  return service;
});

final manualSyncProvider = FutureProvider<void>((ref) async {
  final syncService = ref.read(syncServiceProvider);
  await syncService.sync();
});

final pendingSyncCountProvider = FutureProvider<int>((ref) async {
  if (!AppConfig.hasSupabaseConfig) return 0;
  final client = Supabase.instance.client;
  if (client.auth.currentSession == null) return 0;
  final prefs = ref.watch(sharedPreferencesProvider);
  return RemoteSyncService(client, prefs).countPending();
});
