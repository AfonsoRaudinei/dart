import 'package:sqflite/sqflite.dart';
import '../../../../core/database/database_helper.dart';
import '../../../../core/session/local_session_identity.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/visit_session.dart';
import '../models/event_model.dart';
import '../models/visit_session_model.dart';

/// Repository para persistência de eventos e sessões da agenda
class AgendaRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // ═══════════════════════════════════════════════════════════════════
  // EVENTOS
  // ═══════════════════════════════════════════════════════════════════

  /// Salva um evento no banco de dados
  Future<void> saveEvent(Event event) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return;
    final db = await _dbHelper.database;
    final model = EventModel.fromEntity(event);

    await db.insert('agenda_events', {
      ..._eventToMap(model),
      'user_id': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Atualiza um evento existente
  Future<void> updateEvent(Event event) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return;
    final db = await _dbHelper.database;
    final model = EventModel.fromEntity(event);

    await db.update(
      'agenda_events',
      {..._eventToMap(model), 'user_id': userId},
      where: 'id = ? AND user_id = ?',
      whereArgs: [event.id, userId],
    );
  }

  /// Busca um evento por ID
  Future<Event?> getEventById(String id) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return null;
    final db = await _dbHelper.database;
    final results = await db.query(
      'agenda_events',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _eventFromMap(results.first);
  }

  /// Busca um evento pelo visit_session_id vinculado
  Future<Event?> getEventBySessionId(String sessionId) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return null;
    final db = await _dbHelper.database;
    final results = await db.query(
      'agenda_events',
      where: 'visit_session_id = ? AND user_id = ?',
      whereArgs: [sessionId, userId],
      limit: 1,
    );
    if (results.isEmpty) return null;
    return _eventFromMap(results.first);
  }

  /// Busca todos os eventos
  Future<List<Event>> getAllEvents() async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return [];
    final db = await _dbHelper.database;
    final results = await db.query(
      'agenda_events',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'data_inicio_planejada ASC',
    );

    return results.map(_eventFromMap).toList();
  }

  /// Busca eventos por range de datas
  Future<List<Event>> getEventsByDateRange(DateTime start, DateTime end) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return [];
    final db = await _dbHelper.database;
    final results = await db.query(
      'agenda_events',
      where:
          'user_id = ? AND data_inicio_planejada >= ? AND data_inicio_planejada < ?',
      whereArgs: [userId, start.toIso8601String(), end.toIso8601String()],
      orderBy: 'data_inicio_planejada ASC',
    );

    return results.map(_eventFromMap).toList();
  }

  /// Busca eventos de um dia específico
  Future<List<Event>> getEventsByDay(DateTime day) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return getEventsByDateRange(start, end);
  }

  /// Busca eventos pendentes de sincronização
  Future<List<Event>> getPendingSyncEvents() async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return [];
    final db = await _dbHelper.database;
    final results = await db.query(
      'agenda_events',
      where: 'user_id = ? AND sync_status = ?',
      whereArgs: [userId, 'pending'],
    );

    return results.map(_eventFromMap).toList();
  }

  /// Marca um evento como sincronizado
  Future<void> markEventAsSynced(String id) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return;
    final db = await _dbHelper.database;
    await db.update(
      'agenda_events',
      {'sync_status': 'synced'},
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  /// Deleta um evento (soft delete)
  Future<void> deleteEvent(String id) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return;
    final db = await _dbHelper.database;
    await db.update(
      'agenda_events',
      {
        'sync_status': 'deleted',
        'updated_at': DateTime.now().toIso8601String(),
      },
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  // SESSÕES DE VISITA
  // ═══════════════════════════════════════════════════════════════════

  /// Salva uma sessão de visita
  Future<void> saveSession(VisitSession session) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return;
    final db = await _dbHelper.database;
    final model = VisitSessionModel.fromEntity(session);

    await db.insert('agenda_visit_sessions', {
      ..._sessionToMap(model),
      'user_id': userId,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Atualiza uma sessão existente
  Future<void> updateSession(VisitSession session) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return;
    final db = await _dbHelper.database;
    final model = VisitSessionModel.fromEntity(session);

    await db.update(
      'agenda_visit_sessions',
      {..._sessionToMap(model), 'user_id': userId},
      where: 'id = ? AND user_id = ?',
      whereArgs: [session.id, userId],
    );
  }

  /// Busca uma sessão por ID
  Future<VisitSession?> getSessionById(String id) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return null;
    final db = await _dbHelper.database;
    final results = await db.query(
      'agenda_visit_sessions',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
      limit: 1,
    );

    if (results.isEmpty) return null;
    return _sessionFromMap(results.first);
  }

  /// Busca todas as sessões
  Future<List<VisitSession>> getAllSessions() async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return [];
    final db = await _dbHelper.database;
    final results = await db.query(
      'agenda_visit_sessions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'start_at_real DESC',
    );

    return results.map(_sessionFromMap).toList();
  }

  /// Busca sessões por evento
  Future<List<VisitSession>> getSessionsByEventId(String eventId) async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return [];
    final db = await _dbHelper.database;
    final results = await db.query(
      'agenda_visit_sessions',
      where: 'evento_id = ? AND user_id = ?',
      whereArgs: [eventId, userId],
      orderBy: 'start_at_real DESC',
    );

    return results.map(_sessionFromMap).toList();
  }

  /// Busca sessões ativas (não finalizadas)
  Future<List<VisitSession>> getActiveSessions() async {
    final userId = LocalSessionIdentity.resolveUserId();
    if (userId.isEmpty) return [];
    final db = await _dbHelper.database;
    final results = await db.query(
      'agenda_visit_sessions',
      where: 'user_id = ? AND end_at_real IS NULL',
      whereArgs: [userId],
      orderBy: 'start_at_real DESC',
    );

    return results.map(_sessionFromMap).toList();
  }

  // ═══════════════════════════════════════════════════════════════════
  // HELPERS DE CONVERSÃO
  // ═══════════════════════════════════════════════════════════════════

  Map<String, dynamic> _eventToMap(EventModel event) {
    return {
      'id': event.id,
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
      'sync_status': event.syncStatus,
      'start_time': event.startTime == null
          ? null
          : '${event.startTime!.hour.toString().padLeft(2, '0')}:${event.startTime!.minute.toString().padLeft(2, '0')}',
      'end_time': event.endTime == null
          ? null
          : '${event.endTime!.hour.toString().padLeft(2, '0')}:${event.endTime!.minute.toString().padLeft(2, '0')}',
      'priority': event.priority.name,
      'latitude': event.latitude,
      'longitude': event.longitude,
    };
  }

  Event _eventFromMap(Map<String, dynamic> map) {
    return EventModel.fromJson({
      'id': map['id'],
      'tipo': map['tipo'],
      'clienteId': map['cliente_id'],
      'fazendaId': map['fazenda_id'],
      'talhaoId': map['talhao_id'],
      'titulo': map['titulo'],
      'dataInicioPlanejada': map['data_inicio_planejada'],
      'dataFimPlanejada': map['data_fim_planejada'],
      'status': map['status'],
      'visitSessionId': map['visit_session_id'],
      'serieId': map['serie_id'],
      'createdAt': map['created_at'],
      'updatedAt': map['updated_at'],
      'syncStatus': map['sync_status'],
      'startTime': map['start_time'],
      'endTime': map['end_time'],
      'priority': map['priority'] ?? 'normal',
      'latitude': map['latitude'],
      'longitude': map['longitude'],
    }).toEntity();
  }

  Map<String, dynamic> _sessionToMap(VisitSessionModel session) {
    return {
      'id': session.id,
      'evento_id': session.eventoId,
      'start_at_real': session.startAtReal.toIso8601String(),
      'end_at_real': session.endAtReal?.toIso8601String(),
      'duracao_min': session.duracaoMin,
      'notas_finais': session.notasFinais,
      'checklist_snapshot': session.checklistSnapshot,
      'created_by': session.createdBy,
      'created_at': session.createdAt.toIso8601String(),
      'sync_status': session.syncStatus,
      'producer_id': session.clienteId,
    };
  }

  VisitSession _sessionFromMap(Map<String, dynamic> map) {
    return VisitSessionModel.fromJson({
      'id': map['id'],
      'eventoId': map['evento_id'],
      'startAtReal': map['start_at_real'],
      'endAtReal': map['end_at_real'],
      'duracaoMin': map['duracao_min'],
      'notasFinais': map['notas_finais'],
      'checklistSnapshot': map['checklist_snapshot'],
      'createdBy': map['created_by'],
      'createdAt': map['created_at'],
      'syncStatus': map['sync_status'],
      'producer_id': map['producer_id'],
    }).toEntity();
  }
}
