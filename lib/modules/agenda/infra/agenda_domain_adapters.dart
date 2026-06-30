import '../data/repositories/agenda_repository.dart';
import '../data/services/agenda_notification_service.dart';
import '../domain/entities/event.dart';
import '../domain/entities/visit_session.dart';
import '../domain/repositories/i_agenda_repository.dart';
import '../domain/services/i_agenda_notification_service.dart';

/// Ponte pública AgendaRepository → IAgendaRepository (ADR-046).
class AgendaRepositoryAdapter implements IAgendaRepository {
  AgendaRepositoryAdapter(this._repository);

  final AgendaRepository _repository;

  @override
  Future<void> deleteEvent(String id) => _repository.deleteEvent(id);

  @override
  Future<List<Event>> getAllEvents() => _repository.getAllEvents();

  @override
  Future<List<VisitSession>> getAllSessions() => _repository.getAllSessions();

  @override
  Future<List<Event>> getEventsByDateRange(DateTime start, DateTime end) =>
      _repository.getEventsByDateRange(start, end);

  @override
  Future<List<Event>> getEventsByDay(DateTime day) =>
      _repository.getEventsByDay(day);

  @override
  Future<Event?> getEventById(String id) => _repository.getEventById(id);

  @override
  Future<Event?> getEventBySessionId(String sessionId) =>
      _repository.getEventBySessionId(sessionId);

  @override
  Future<List<VisitSession>> getActiveSessions() =>
      _repository.getActiveSessions();

  @override
  Future<List<Event>> getPendingSyncEvents() =>
      _repository.getPendingSyncEvents();

  @override
  Future<VisitSession?> getSessionById(String id) =>
      _repository.getSessionById(id);

  @override
  Future<List<VisitSession>> getSessionsByEventId(String eventId) =>
      _repository.getSessionsByEventId(eventId);

  @override
  Future<void> markEventAsSynced(String id) =>
      _repository.markEventAsSynced(id);

  @override
  Future<void> saveEvent(Event event) => _repository.saveEvent(event);

  @override
  Future<void> saveSession(VisitSession session) =>
      _repository.saveSession(session);

  @override
  Future<void> updateEvent(Event event) => _repository.updateEvent(event);

  @override
  Future<void> updateSession(VisitSession session) =>
      _repository.updateSession(session);
}

class AgendaNotificationServiceAdapter implements IAgendaNotificationService {
  AgendaNotificationServiceAdapter(this._service);

  final AgendaNotificationService _service;

  @override
  Future<void> cancelEventNotifications(String eventId) =>
      _service.cancelEventNotifications(eventId);

  @override
  Future<void> scheduleEventNotifications(Event event) =>
      _service.scheduleEventNotifications(event);
}
