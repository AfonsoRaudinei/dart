import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show TimeOfDay;
import '../../../../core/session/local_session_identity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/network_policy.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import '../../../../core/utils/app_logger.dart';
import '../repositories/agenda_repository.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/visit.dart';
import '../../domain/entities/visit_session.dart';
import '../../domain/enums/event_type.dart';
import '../../domain/enums/event_status.dart';

/// Callback de teste para simular delete remoto sem Supabase real.
typedef AgendaRemoteEventDelete = Future<void> Function(
  String eventId,
  String userId,
);

/// Serviço de sincronização da agenda com Supabase
class AgendaSyncService {
  final SupabaseClient _supabase;
  final AgendaRepository _repository;
  final AgendaRemoteEventDelete? _remoteEventDeleteForTest;

  AgendaSyncService(
    this._supabase,
    this._repository, {
    @visibleForTesting AgendaRemoteEventDelete? remoteEventDeleteForTest,
  }) : _remoteEventDeleteForTest = remoteEventDeleteForTest;

  /// Expõe push de eventos para testes de integração (tombstone remoto).
  @visibleForTesting
  Future<void> pushEventsForTesting() => _pushEvents();

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
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) {
      AppLogger.warning('Skipping agenda event push: userId is null', tag: 'AgendaSync');
      return;
    }

    final pendingEvents = await _repository.getPendingSyncEvents();

    for (final event in pendingEvents) {
      try {
        if (SyncStatusContract.normalize(event.syncStatus) ==
            SyncStatusContract.deletedLocal) {
          final remoteDelete = _remoteEventDeleteForTest;
          if (remoteDelete != null) {
            await remoteDelete(event.id, userId);
          } else {
            await NetworkPolicy.withTimeout(
              () => _supabase
                  .from('agenda_events')
                  .delete()
                  .eq('id', event.id)
                  .eq('user_id', userId),
            );
          }
          await _repository.purgeDeletedEvent(event.id);
          continue;
        }

        await NetworkPolicy.withTimeout(
          () => _supabase.from('agenda_events').upsert(
            AgendaEventRemoteMapper.eventLocalToRemote(event, userId),
          ),
        );

        await _repository.markEventAsSynced(event.id);
      } catch (e) {
        AppLogger.warning(
          'Falha ao sincronizar evento ${event.id}',
          tag: 'AgendaSync',
          error: e,
        );
        continue; // Best effort - continua para o próximo
      }
    }
  }

  Future<void> _pushSessions() async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) {
      AppLogger.warning('Skipping agenda session push: userId is null', tag: 'AgendaSync');
      return;
    }

    final sessions = await _repository.getAllSessions();
    final pendingSessions =
        sessions.where((s) => SyncStatusContract.isPending(s.syncStatus));

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
        AppLogger.warning(
          'Falha ao sincronizar sessão ${session.id}',
          tag: 'AgendaSync',
          error: e,
        );
        continue;
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════
  // PULL (Supabase → Local)
  // ═══════════════════════════════════════════════════════════════════

  Future<void> _pullEvents() async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) {
      AppLogger.warning('Skipping agenda event pull: userId is null', tag: 'AgendaSync');
      return;
    }

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

        // Local pending/deleted vence até confirmação explícita.
        if (SyncStatusContract.isPending(localEvent.syncStatus) ||
            SyncStatusContract.normalize(localEvent.syncStatus) ==
                SyncStatusContract.deletedLocal) {
          AppLogger.debug(
            'Agenda pull skip pending/deleted local [id=${localEvent.id}]',
            tag: 'AgendaSync',
          );
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
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) {
      AppLogger.warning('Skipping agenda session pull: userId is null', tag: 'AgendaSync');
      return;
    }

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
    final local = AgendaEventRemoteMapper.eventRemoteToLocal(map);

    return Event(
      id: local['id'],
      tipo: EventType.values.byName(local['tipo'] as String),
      clienteId: local['cliente_id'] as String,
      fazendaId: local['fazenda_id'] as String?,
      talhaoId: local['talhao_id'] as String?,
      titulo: local['titulo'] as String,
      dataInicioPlanejada: DateTime.parse(
        local['data_inicio_planejada'] as String,
      ),
      dataFimPlanejada: DateTime.parse(local['data_fim_planejada'] as String),
      status: EventStatus.values.byName(local['status'] as String),
      visitSessionId: local['visit_session_id'] as String?,
      serieId: local['serie_id'] as String?,
      createdAt: DateTime.parse(local['created_at'] as String),
      updatedAt: DateTime.parse(local['updated_at'] as String),
      syncStatus: 'synced',
      startTime: AgendaEventRemoteMapper.parseTime(local['start_time']),
      endTime: AgendaEventRemoteMapper.parseTime(local['end_time']),
      priority: VisitPriority.fromString(
        local['priority']?.toString() ?? 'normal',
      ),
      latitude: (local['latitude'] as num?)?.toDouble(),
      longitude: (local['longitude'] as num?)?.toDouble(),
    );
  }

  VisitSession _mapToSession(Map<String, dynamic> map) {
    return VisitSession(
      id: map['id'],
      eventoId: map['evento_id'],
      startAtReal: DateTime.parse(map['start_at_real']),
      endAtReal: map['end_at_real'] != null
          ? DateTime.parse(map['end_at_real'])
          : null,
      duracaoMin: map['duracao_min'],
      notasFinais: map['notas_finais'],
      checklistSnapshot: map['checklist_snapshot'],
      createdBy: map['created_by'],
      createdAt: DateTime.parse(map['created_at']),
      syncStatus: 'synced',
    );
  }
}

/// Mapper dual PT + EN legado para `agenda_events` remoto.
class AgendaEventRemoteMapper {
  const AgendaEventRemoteMapper._();

  @visibleForTesting
  static Map<String, dynamic> eventLocalToRemote(Event event, String userId) {
    final dataInicio = event.dataInicioPlanejada.toIso8601String();
    final dataFim = event.dataFimPlanejada.toIso8601String();
    final areaId = event.talhaoId ?? event.fazendaId;
    final realizedAt = event.status.isFinished ? dataFim : null;

    return {
      'id': event.id,
      'user_id': userId,
      'tipo': event.tipo.name,
      'cliente_id': event.clienteId,
      'fazenda_id': event.fazendaId,
      'talhao_id': event.talhaoId,
      'titulo': event.titulo,
      'data_inicio_planejada': dataInicio,
      'data_fim_planejada': dataFim,
      'status': event.status.name,
      'visit_session_id': event.visitSessionId,
      'serie_id': event.serieId,
      'created_at': event.createdAt.toIso8601String(),
      'updated_at': event.updatedAt.toIso8601String(),
      'start_time': formatTime(event.startTime),
      'end_time': formatTime(event.endTime),
      'priority': event.priority.name,
      'latitude': event.latitude,
      'longitude': event.longitude,
      'producer_id': event.clienteId.isEmpty ? null : event.clienteId,
      'area_id': areaId,
      'activity_type': event.tipo.name,
      'scheduled_date': dataInicio,
      'description': event.titulo,
      'realized_at': realizedAt,
    };
  }

  @visibleForTesting
  static Map<String, dynamic> eventRemoteToLocal(Map<String, dynamic> remote) {
    final dataInicioRaw = _first(remote, [
      'data_inicio_planejada',
      'scheduled_date',
    ]);
    final dataInicio = dataInicioRaw != null
        ? DateTime.parse(dataInicioRaw.toString())
        : DateTime.now();

    final dataFimRaw = _first(remote, ['data_fim_planejada', 'realized_at']);
    final dataFim = dataFimRaw != null
        ? DateTime.parse(dataFimRaw.toString())
        : dataInicio.add(const Duration(hours: 1));

    return {
      'id': remote['id'],
      'tipo': _parseTipoName(_first(remote, ['tipo', 'activity_type'])),
      'cliente_id': _first(remote, ['cliente_id', 'producer_id'])?.toString() ??
          '',
      'fazenda_id': remote['fazenda_id']?.toString(),
      'talhao_id':
          _first(remote, ['talhao_id', 'area_id'])?.toString(),
      'titulo': _first(remote, ['titulo', 'description'])?.toString() ?? '',
      'data_inicio_planejada':
          dataInicioRaw?.toString() ?? dataInicio.toIso8601String(),
      'data_fim_planejada':
          dataFimRaw?.toString() ?? dataFim.toIso8601String(),
      'status': _parseStatusName(remote['status']),
      'visit_session_id': remote['visit_session_id']?.toString(),
      'serie_id': remote['serie_id']?.toString(),
      'created_at':
          remote['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      'updated_at':
          remote['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
      'start_time': remote['start_time'],
      'end_time': remote['end_time'],
      'priority': remote['priority']?.toString() ?? 'normal',
      'latitude': remote['latitude'],
      'longitude': remote['longitude'],
    };
  }

  @visibleForTesting
  static TimeOfDay? parseTime(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    if (text.isEmpty) return null;
    final parts = text.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  @visibleForTesting
  static String? formatTime(TimeOfDay? time) {
    if (time == null) return null;
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  static dynamic _first(Map<String, dynamic> map, List<String> keys) {
    for (final key in keys) {
      final value = map[key];
      if (value == null) continue;
      if (value is String && value.trim().isEmpty) continue;
      return value;
    }
    return null;
  }

  static String _parseTipoName(dynamic raw) {
    if (raw == null) return EventType.personalizado.name;
    final text = raw.toString().trim();
    if (text.isEmpty) return EventType.personalizado.name;
    for (final type in EventType.values) {
      if (type.name == text) return type.name;
    }
    return EventType.personalizado.name;
  }

  static String _parseStatusName(dynamic raw) {
    if (raw == null) return EventStatus.agendado.name;
    final text = raw.toString().trim();
    if (text.isEmpty) return EventStatus.agendado.name;
    for (final status in EventStatus.values) {
      if (status.name == text) return status.name;
    }
    return EventStatus.agendado.name;
  }
}
