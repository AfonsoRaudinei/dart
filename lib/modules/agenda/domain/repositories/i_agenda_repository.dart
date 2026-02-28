import '../entities/event.dart';
import '../entities/visit_session.dart';

/// Contrato de persistência da Agenda.
///
/// Separa a intenção (domínio) da implementação (SQLite, Supabase, mock).
/// Qualquer camada que precise de dados de Agenda deve depender DESTA interface,
/// nunca da classe concreta [AgendaRepository].
abstract class IAgendaRepository {
  // ═══════════════════════════════════════════════════════════════════
  // EVENTOS
  // ═══════════════════════════════════════════════════════════════════

  Future<void> saveEvent(Event event);

  Future<void> updateEvent(Event event);

  Future<Event?> getEventById(String id);

  Future<List<Event>> getAllEvents();

  Future<List<Event>> getEventsByDateRange(DateTime start, DateTime end);

  Future<List<Event>> getEventsByDay(DateTime day);

  Future<List<Event>> getPendingSyncEvents();

  Future<void> markEventAsSynced(String id);

  /// Soft delete — marca syncStatus como 'deleted', não remove fisicamente.
  Future<void> deleteEvent(String id);

  // ═══════════════════════════════════════════════════════════════════
  // SESSÕES DE VISITA
  // ═══════════════════════════════════════════════════════════════════

  Future<void> saveSession(VisitSession session);

  Future<void> updateSession(VisitSession session);

  Future<VisitSession?> getSessionById(String id);

  Future<List<VisitSession>> getAllSessions();

  Future<List<VisitSession>> getSessionsByEventId(String eventId);

  Future<List<VisitSession>> getActiveSessions();
}
