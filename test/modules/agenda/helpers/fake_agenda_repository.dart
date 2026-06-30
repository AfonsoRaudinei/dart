import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/visit_session.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/domain/repositories/i_agenda_repository.dart';

/// Implementação em memória de [IAgendaRepository] para testes.
///
/// Mantém eventos e sessões em Maps. Permite:
/// - Verificar interações (quais eventos foram salvos/atualizados)
/// - Simular falha no próximo write
/// - Pré-popular estado inicial
class FakeAgendaRepository implements IAgendaRepository {
  final Map<String, Event> _events = {};
  final Map<String, VisitSession> _sessions = {};

  /// Se true, o próximo método de escrita lança [Exception].
  bool throwOnNextWrite = false;

  // ──────────────────────────────────────────────────────────────
  // Helpers de inspeção para uso nos testes
  // ──────────────────────────────────────────────────────────────

  /// Snapshot de todos os eventos em memória.
  List<Event> get events => _events.values.toList();

  /// Snapshot de todas as sessões em memória.
  List<VisitSession> get sessions => _sessions.values.toList();

  /// Acesso direto a um evento pelo ID.
  Event? eventById(String id) => _events[id];

  /// Acesso direto a uma sessão pelo ID.
  VisitSession? sessionById(String id) => _sessions[id];

  /// Pré-popula o repositório com uma lista de eventos.
  void seedEvents(List<Event> events) {
    for (final e in events) {
      _events[e.id] = e;
    }
  }

  // ──────────────────────────────────────────────────────────────
  // IAgendaRepository — Eventos
  // ──────────────────────────────────────────────────────────────

  @override
  Future<void> saveEvent(Event event) async {
    _checkThrow();
    _events[event.id] = event;
  }

  @override
  Future<void> updateEvent(Event event) async {
    _checkThrow();
    _events[event.id] = event;
  }

  @override
  Future<Event?> getEventById(String id) async => _events[id];

  @override
  Future<Event?> getEventBySessionId(String sessionId) async =>
      _events.values.where((e) => e.visitSessionId == sessionId).firstOrNull;

  @override
  Future<List<Event>> getAllEvents() async => _events.values.toList();

  @override
  Future<List<Event>> getEventsByDateRange(DateTime start, DateTime end) async {
    return _events.values
        .where(
          (e) =>
              !e.dataInicioPlanejada.isBefore(start) &&
              !e.dataInicioPlanejada.isAfter(end),
        )
        .toList();
  }

  @override
  Future<List<Event>> getEventsByDay(DateTime day) async {
    return _events.values.where((e) {
      final d = e.dataInicioPlanejada;
      return d.year == day.year && d.month == day.month && d.day == day.day;
    }).toList();
  }

  @override
  Future<List<Event>> getPendingSyncEvents() async {
    return _events.values.where((e) => e.syncStatus == 'pending').toList();
  }

  @override
  Future<void> markEventAsSynced(String id) async {
    final e = _events[id];
    if (e != null) _events[id] = e.copyWith(syncStatus: 'synced');
  }

  @override
  Future<void> deleteEvent(String id) async {
    _checkThrow();
    final e = _events[id];
    if (e != null) _events[id] = e.copyWith(syncStatus: 'deleted');
  }

  // ──────────────────────────────────────────────────────────────
  // IAgendaRepository — Sessões
  // ──────────────────────────────────────────────────────────────

  @override
  Future<void> saveSession(VisitSession session) async {
    _checkThrow();
    _sessions[session.id] = session;
  }

  @override
  Future<void> updateSession(VisitSession session) async {
    _checkThrow();
    _sessions[session.id] = session;
  }

  @override
  Future<VisitSession?> getSessionById(String id) async => _sessions[id];

  @override
  Future<List<VisitSession>> getAllSessions() async =>
      _sessions.values.toList();

  @override
  Future<List<VisitSession>> getSessionsByEventId(String eventId) async {
    return _sessions.values.where((s) => s.eventoId == eventId).toList();
  }

  @override
  Future<List<VisitSession>> getActiveSessions() async {
    return _sessions.values.where((s) => s.isActive).toList();
  }

  // ──────────────────────────────────────────────────────────────
  // Internals
  // ──────────────────────────────────────────────────────────────

  void _checkThrow() {
    if (throwOnNextWrite) {
      throwOnNextWrite = false;
      throw Exception('FakeAgendaRepository: erro simulado de escrita');
    }
  }
}

// ──────────────────────────────────────────────────────────────────────────
// Factory helpers — constroem objetos de domínio para uso nos testes
// ──────────────────────────────────────────────────────────────────────────

/// Data base fixtura: amanhã ao meio-dia.
DateTime get _tomorrow => DateTime.now().add(const Duration(days: 1)).copyWith(
      hour: 12,
      minute: 0,
      second: 0,
      millisecond: 0,
      microsecond: 0,
    );

/// Cria um [Event] com valores padrão razoáveis, aceita overrides.
Event makeEvent({
  String id = 'evt-1',
  EventType tipo = EventType.visitaTecnica,
  String clienteId = 'cli-1',
  String? fazendaId,
  String titulo = 'Visita Padrão',
  DateTime? dataInicio,
  DateTime? dataFim,
  EventStatus status = EventStatus.agendado,
  String? visitSessionId,
}) {
  final inicio = dataInicio ?? _tomorrow;
  final fim = dataFim ?? inicio.add(const Duration(hours: 2));
  final now = DateTime.now();

  return Event(
    id: id,
    tipo: tipo,
    clienteId: clienteId,
    fazendaId: fazendaId,
    titulo: titulo,
    dataInicioPlanejada: inicio,
    dataFimPlanejada: fim,
    status: status,
    visitSessionId: visitSessionId,
    createdAt: now,
    updatedAt: now,
    syncStatus: 'pending',
  );
}

/// Cria um [VisitSession] com valores padrão.
VisitSession makeSession({
  String id = 'sess-1',
  String eventoId = 'evt-1',
  DateTime? startAtReal,
  DateTime? endAtReal,
  String createdBy = 'user-1',
}) {
  final start = startAtReal ?? DateTime.now().subtract(const Duration(minutes: 30));
  final now = DateTime.now();

  return VisitSession(
    id: id,
    eventoId: eventoId,
    startAtReal: start,
    endAtReal: endAtReal,
    createdBy: createdBy,
    createdAt: now,
    syncStatus: 'pending',
  );
}
