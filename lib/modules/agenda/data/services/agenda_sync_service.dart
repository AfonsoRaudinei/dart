import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/network_policy.dart';
import '../../../../core/utils/app_logger.dart';
import '../repositories/agenda_repository.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/visit_session.dart';
import '../../domain/enums/event_type.dart';
import '../../domain/enums/event_status.dart';

/// Serviço de sincronização da agenda com Supabase
class AgendaSyncService {
  final SupabaseClient _supabase;
  final AgendaRepository _repository;

  AgendaSyncService(this._supabase, this._repository);

  /// Sincroniza eventos e sessões (push + pull)
  Future<void> sync() async {
    try {
      await _pushEvents();
      await _pushSessions();
      await _pullEvents();
      await _pullSessions();

      AppLogger.debug('Agenda: Sync completo', tag: 'AgendaSync');
    } catch (e) {
      AppLogger.warning('Agenda: Erro no sync', tag: 'AgendaSync', error: e);
      rethrow;
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PUSH (Local → Supabase)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _pushEvents() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final pendingEvents = await _repository.getPendingSyncEvents();

    for (final event in pendingEvents) {
      try {
        // Não enviar eventos deletados (apenas marcar localmente)
        if (event.syncStatus == 'deleted') {
          continue;
        }

        await NetworkPolicy.withTimeout(
          () => _supabase.from('agenda_events').upsert({
            'id': event.id,
            'user_id': userId,
            'tipo': event.tipo.name,
            'cliente_id': event.clienteId,
            'fazenda_id': event.fazendaId,
            'talhao_id': event.talhaoId,
            'titulo': event.titulo,
            'data_inicio_planejada': event.dataInicioPlanejada.toIso8601String(),
            'data_fim_planejada': event.dataFimPlanejada.toIso8601String(),
            'status': event.status.name,
            'visit_session_id': event.visitSessionId,
            'serie_id': event.serieId,
            'created_at': event.createdAt.toIso8601String(),
            'updated_at': event.updatedAt.toIso8601String(),
          }),
        );

        await _repository.markEventAsSynced(event.id);
      } catch (e) {
        AppLogger.warning('Falha ao sincronizar evento ${event.id}', tag: 'AgendaSync', error: e);
        continue; // Best effort - continua para o próximo
      }
    }
  }

  Future<void> _pushSessions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    final sessions = await _repository.getAllSessions();
    final pendingSessions = sessions.where((s) => s.syncStatus == 'pending');

    for (final session in pendingSessions) {
      try {
        await NetworkPolicy.withTimeout(
          () => _supabase.from('agenda_visit_sessions').upsert({
            'id': session.id,
            'user_id': userId,
            'evento_id': session.eventoId,
            'start_at_real': session.startAtReal.toIso8601String(),
            'end_at_real': session.endAtReal?.toIso8601String(),
            'duracao_min': session.duracaoMin,
            'notas_finais': session.notasFinais,
            'checklist_snapshot': session.checklistSnapshot,
            'created_by': session.createdBy,
            'created_at': session.createdAt.toIso8601String(),
          }),
        );

        // Marcar como synced via update
        final updatedSession = session.copyWith(syncStatus: 'synced');
        await _repository.updateSession(updatedSession);
      } catch (e) {
        AppLogger.warning('Falha ao sincronizar sessão ${session.id}', tag: 'AgendaSync', error: e);
        continue;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PULL (Supabase → Local)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _pullEvents() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final remoteEvents = await NetworkPolicy.withTimeout(
        () => _supabase
            .from('agenda_events')
            .select()
            .eq('user_id', userId)
            .order('updated_at', ascending: false),
      );

      for (final remote in remoteEvents) {
        final localEvent = await _repository.getEventById(remote['id']);

        // Se não existe localmente, inserir
        if (localEvent == null) {
          await _repository.saveEvent(_mapToEvent(remote));
          continue;
        }

        // Se remoto é mais recente, atualizar
        final remoteUpdatedAt = DateTime.parse(remote['updated_at']);
        if (remoteUpdatedAt.isAfter(localEvent.updatedAt)) {
          await _repository.updateEvent(_mapToEvent(remote));
        }
      }
    } catch (e) {
      AppLogger.warning('Falha ao baixar eventos', tag: 'AgendaSync', error: e);
    }
  }

  Future<void> _pullSessions() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final remoteSessions = await NetworkPolicy.withTimeout(
        () => _supabase
            .from('agenda_visit_sessions')
            .select()
            .eq('user_id', userId)
            .order('created_at', ascending: false),
      );

      for (final remote in remoteSessions) {
        final localSession = await _repository.getSessionById(remote['id']);

        if (localSession == null) {
          await _repository.saveSession(_mapToSession(remote));
        }
        // Sessões geralmente não são editadas, apenas criadas/finalizadas
      }
    } catch (e) {
      AppLogger.warning('Falha ao baixar sessões', tag: 'AgendaSync', error: e);
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS DE CONVERSÃO
  // ═══════════════════════════════════════════════════════════════════

  Event _mapToEvent(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      tipo: EventType.values.byName(map['tipo']),
      clienteId: map['cliente_id'],
      fazendaId: map['fazenda_id'],
      talhaoId: map['talhao_id'],
      titulo: map['titulo'],
      dataInicioPlanejada: DateTime.parse(map['data_inicio_planejada']),
      dataFimPlanejada: DateTime.parse(map['data_fim_planejada']),
      status: EventStatus.values.byName(map['status']),
      visitSessionId: map['visit_session_id'],
      serieId: map['serie_id'],
      createdAt: DateTime.parse(map['created_at']),
      updatedAt: DateTime.parse(map['updated_at']),
      syncStatus: 'synced',
    );
  }

  VisitSession _mapToSession(Map<String, dynamic> map) {
    return VisitSession(
      id: map['id'],
      eventoId: map['evento_id'],
      startAtReal: DateTime.parse(map['start_at_real']),
      endAtReal:
          map['end_at_real'] != null ? DateTime.parse(map['end_at_real']) : null,
      duracaoMin: map['duracao_min'],
      notasFinais: map['notas_finais'],
      checklistSnapshot: map['checklist_snapshot'],
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
      syncStatus: 'synced',
    );
  }
}
