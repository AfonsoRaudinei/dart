import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/sync_orchestrator.dart';
import '../modules/consultoria/services/agronomic_sync_service.dart';
import '../modules/drawing/data/data_sources/drawing_sync_service.dart';
import '../modules/consultoria/occurrences/data/occurrence_sync_service.dart';
import '../modules/agenda/data/services/agenda_sync_service.dart';
import '../modules/agenda/data/repositories/agenda_repository.dart';

/// Camada de composição: registra os módulos de sync no SyncOrchestrator.
///
/// Esta é a única camada com permissão de importar core/ e modules/
/// simultaneamente — responsabilidade explícita de wiring, sem lógica de negócio.
final syncOrchestratorProvider = ChangeNotifierProvider<SyncOrchestrator>((
  ref,
) {
  final orchestrator = SyncOrchestrator(ref);
  final supabase = Supabase.instance.client;

  orchestrator.registerModule(AgronomicSyncModule(supabase));
  orchestrator.registerModule(DrawingSyncModule());
  orchestrator.registerModule(OccurrenceSyncModule(supabase));
  orchestrator.registerModule(AgendaSyncModule(supabase));

  return orchestrator;
});

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

class AgendaSyncModule implements SyncModule {
  final SupabaseClient supabase;
  AgendaSyncModule(this.supabase);

  @override
  String get name => 'Agenda e Visitas';

  @override
  Future<void> sync() {
    final repository = AgendaRepository();
    return AgendaSyncService(supabase, repository).sync();
  }
}
