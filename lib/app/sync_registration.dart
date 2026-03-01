import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/services/sync_orchestrator.dart';
import '../modules/consultoria/services/agronomic_sync_service.dart';
import '../modules/drawing/data/data_sources/drawing_sync_service.dart';
import '../modules/consultoria/occurrences/data/occurrence_sync_service.dart';
import '../modules/visitas/data/repositories/visit_sync_service.dart';
import '../modules/agenda/data/services/agenda_sync_service.dart';
import '../modules/agenda/data/repositories/agenda_repository.dart';

void registerSyncModules(SyncOrchestrator orchestrator) {
  final supabase = Supabase.instance.client;
  orchestrator.registerModule(AgronomicSyncModule(supabase));
  orchestrator.registerModule(DrawingSyncModule());
  orchestrator.registerModule(OccurrenceSyncModule(supabase));
  orchestrator.registerModule(VisitSyncModule(supabase));
  orchestrator.registerModule(AgendaSyncModule(supabase));
}

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
