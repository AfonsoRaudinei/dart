import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/services/connectivity_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/consultoria/services/agronomic_sync_service.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_sync_service.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_sync_service.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_sync_service.dart';

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
          debugPrint('Sync Error in ${module.name}: $e');
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
        if (!_isSyncing) {
          _progress = 0;
          notifyListeners();
        }
      });
    }
  }

  @override
  void dispose() {
    _periodicTimer?.cancel();
    super.dispose();
  }
}

final syncOrchestratorProvider = ChangeNotifierProvider<SyncOrchestrator>((
  ref,
) {
  final orchestrator = SyncOrchestrator(ref);
  final supabase = Supabase.instance.client;

  // Registrar Módulos
  orchestrator.registerModule(AgronomicSyncModule(supabase));
  orchestrator.registerModule(DrawingSyncModule());
  orchestrator.registerModule(OccurrenceSyncModule(supabase));
  orchestrator.registerModule(VisitSyncModule(supabase));

  return orchestrator;
});

// Implementações concretas de módulos
class AgronomicSyncModule implements SyncModule {
  final SupabaseClient supabase;
  AgronomicSyncModule(this.supabase);
  @override
  String get name => 'Dados Agronômicos';
  @override
  Future<void> sync() => AgronomicSyncService(supabase).syncNow();
}

class DrawingSyncModule implements SyncModule {
  @override
  String get name => 'Desenhos e Mapas';
  @override
  Future<void> sync() => DrawingSyncService().synchronize();
}

class OccurrenceSyncModule implements SyncModule {
  final SupabaseClient supabase;
  OccurrenceSyncModule(this.supabase);
  @override
  String get name => 'Ocorrências';
  @override
  Future<void> sync() => OccurrenceSyncService(supabase).syncOccurrences();
}

class VisitSyncModule implements SyncModule {
  final SupabaseClient supabase;
  VisitSyncModule(this.supabase);
  @override
  String get name => 'Visitas Técnicas';
  @override
  Future<void> sync() => VisitSyncService(supabase).syncVisits();
}
