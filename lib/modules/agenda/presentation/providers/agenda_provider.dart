import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/visit.dart';
import '../../domain/entities/visit_session.dart';
import '../../domain/enums/event_status.dart';
import '../../domain/enums/event_type.dart';
import '../../domain/repositories/i_agenda_repository.dart';
import '../../domain/services/i_agenda_notification_service.dart';
import '../../domain/use_cases/create_event_use_case.dart';
import '../../domain/use_cases/update_event_use_case.dart';
import '../../domain/rules/event_rules.dart';
import '../../data/repositories/agenda_repository.dart';
import '../../data/services/agenda_notification_service.dart';
import '../widgets/distance_warning_dialog.dart';

class _AgendaRepositoryAdapter implements IAgendaRepository {
  final AgendaRepository _repository;

  _AgendaRepositoryAdapter(this._repository);

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

class _AgendaNotificationServiceAdapter implements IAgendaNotificationService {
  final AgendaNotificationService _service;

  _AgendaNotificationServiceAdapter(this._service);

  @override
  Future<void> cancelEventNotifications(String eventId) =>
      _service.cancelEventNotifications(eventId);

  @override
  Future<void> scheduleEventNotifications(Event event) =>
      _service.scheduleEventNotifications(event);
}

/// Estado da Agenda
class AgendaState {
  final List<Event> events;
  final List<VisitSession> sessions;
  final List<Event> conflicts;
  final bool isLoading;
  final String? error;

  const AgendaState({
    this.events = const [],
    this.sessions = const [],
    this.conflicts = const [],
    this.isLoading = false,
    this.error,
  });

  AgendaState copyWith({
    List<Event>? events,
    List<VisitSession>? sessions,
    List<Event>? conflicts,
    bool? isLoading,
    String? error,
  }) {
    return AgendaState(
      events: events ?? this.events,
      sessions: sessions ?? this.sessions,
      conflicts: conflicts ?? this.conflicts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Provider da Agenda - gerencia eventos e sessões de visita
class AgendaNotifier extends StateNotifier<AgendaState> {
  final AgendaRepository _repository;
  final AgendaNotificationService _notificationService;
  final _uuid = const Uuid();

  AgendaNotifier(this._repository, this._notificationService)
    : super(const AgendaState()) {
    _loadFromDatabase();
    _initializeNotifications();
  }

  /// Inicializa serviço de notificações
  Future<void> _initializeNotifications() async {
    await _notificationService.initialize();
  }

  /// Carrega eventos e sessões do banco de dados
  Future<void> _loadFromDatabase() async {
    state = state.copyWith(isLoading: true);

    try {
      final events = await _repository.getAllEvents();
      final sessions = await _repository.getAllSessions();

      state = state.copyWith(
        events: events,
        sessions: sessions,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Erro ao carregar agenda: $e',
        isLoading: false,
      );
    }
  }

  /// Recarrega dados do banco
  Future<void> reload() async {
    await _loadFromDatabase();
  }

  /// Cria um novo evento
  Future<Event> createEvent({
    required EventType tipo,
    required String clienteId,
    String? fazendaId,
    String? talhaoId,
    required String titulo,
    required DateTime dataInicioPlanejada,
    required DateTime dataFimPlanejada,
    String? currentUserId,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    VisitPriority? priority,
    double? latitude,
    double? longitude,
  }) async {
    final result =
        await CreateEventUseCase(
          _AgendaRepositoryAdapter(_repository),
          _AgendaNotificationServiceAdapter(_notificationService),
        ).execute(
          tipo: tipo,
          clienteId: clienteId,
          fazendaId: fazendaId,
          talhaoId: talhaoId,
          titulo: titulo,
          dataInicioPlanejada: dataInicioPlanejada,
          dataFimPlanejada: dataFimPlanejada,
          currentUserId: currentUserId,
          startTime: startTime,
          endTime: endTime,
          priority: priority ?? VisitPriority.normal,
          latitude: latitude,
          longitude: longitude,
          currentEvents: state.events,
        );

    // Adiciona o evento
    state = state.copyWith(
      events: [...state.events, result.event],
      conflicts: result.conflicts,
    );

    return result.event;
  }

  /// Atualiza um evento existente
  Future<Event> updateEvent({
    required String eventId,
    String? titulo,
    DateTime? dataInicioPlanejada,
    DateTime? dataFimPlanejada,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    VisitPriority? priority,
    double? latitude,
    double? longitude,
  }) async {
    final currentEvent = state.events.firstWhere(
      (event) => event.id == eventId,
      orElse: () => throw ArgumentError('Evento não encontrado'),
    );

    final updatedEvent =
        await UpdateEventUseCase(
          _AgendaRepositoryAdapter(_repository),
          _AgendaNotificationServiceAdapter(_notificationService),
        ).execute(
          currentEvent: currentEvent,
          titulo: titulo,
          dataInicioPlanejada: dataInicioPlanejada,
          dataFimPlanejada: dataFimPlanejada,
          startTime: startTime,
          endTime: endTime,
          priority: priority,
          latitude: latitude,
          longitude: longitude,
          currentEvents: state.events,
        );

    _updateEvent(updatedEvent);
    return updatedEvent;
  }

  DistanceWarning? checkDistanceWarning({
    required DateTime dataInicioPlanejada,
    double? latitude,
    double? longitude,
    TimeOfDay? startTime,
    String? excludeEventId,
  }) {
    const double thresholdKm = 50.0;
    const int thresholdMinutes = 60;

    if (latitude == null || longitude == null || startTime == null) {
      return null;
    }

    final currentEvent = _resolveDistanceWarningEvent(
      dataInicioPlanejada: dataInicioPlanejada,
      latitude: latitude,
      longitude: longitude,
      startTime: startTime,
      eventId: excludeEventId,
    );

    final targetStart = DateTime(
      dataInicioPlanejada.year,
      dataInicioPlanejada.month,
      dataInicioPlanejada.day,
      startTime.hour,
      startTime.minute,
    );

    final sameDayEvents =
        state.events
            .where(
              (event) => DateUtils.isSameDay(
                event.dataInicioPlanejada,
                dataInicioPlanejada,
              ),
            )
            .where((event) => event.id != excludeEventId)
            .where((event) => event.id != currentEvent?.id)
            .toList()
          ..sort(
            (a, b) => a.dataInicioPlanejada.compareTo(b.dataInicioPlanejada),
          );

    final previousCandidates =
        sameDayEvents
            .where((event) => event.latitude != null && event.longitude != null)
            .where((event) => event.startTime != null)
            .where((event) => !event.dataFimPlanejada.isAfter(targetStart))
            .toList()
          ..sort((a, b) => b.dataFimPlanejada.compareTo(a.dataFimPlanejada));

    if (previousCandidates.isNotEmpty) {
      final previousEvent = previousCandidates.first;
      final gapMinutes = targetStart
          .difference(previousEvent.dataFimPlanejada)
          .inMinutes;
      final distanceKm = _haversineKm(
        previousEvent.latitude!,
        previousEvent.longitude!,
        latitude,
        longitude,
      );

      if (distanceKm > thresholdKm && gapMinutes < thresholdMinutes) {
        return DistanceWarning(
          message:
              'A visita anterior termina em pouco tempo para um deslocamento de ${distanceKm.toStringAsFixed(1)} km.',
          distanceKm: distanceKm,
          fromTitle: previousEvent.titulo,
          toTitle: currentEvent?.titulo ?? 'Visita atual',
          intervalMinutes: gapMinutes,
          conflictingEvent: previousEvent,
        );
      }
    }

    if (currentEvent?.latitude != null && currentEvent?.longitude != null) {
      final minutesUntilStart = targetStart
          .difference(DateTime.now())
          .inMinutes;
      final distanceKm = _haversineKm(
        latitude,
        longitude,
        currentEvent!.latitude!,
        currentEvent.longitude!,
      );

      if (distanceKm > thresholdKm &&
          minutesUntilStart >= 0 &&
          minutesUntilStart < thresholdMinutes) {
        return DistanceWarning(
          message:
              'O deslocamento estimado ate esta visita e alto para o tempo restante antes do inicio.',
          distanceKm: distanceKm,
          fromTitle: 'Posicao atual',
          toTitle: currentEvent.titulo,
          intervalMinutes: minutesUntilStart,
          conflictingEvent: currentEvent,
        );
      }
    }

    return null;
  }

  /// Inicia um evento (AGENDADO → EM_ANDAMENTO)
  Future<VisitSession> startEvent(String eventId, String currentUserId) async {
    final event = state.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw ArgumentError('Evento não encontrado'),
    );

    if (!EventRules.canTransitionTo(event.status, EventStatus.emAndamento)) {
      throw StateError(
        'Evento não pode ser iniciado no status ${event.status.label}',
      );
    }

    final now = DateTime.now();

    // Cria a VisitSession
    final session = VisitSession(
      id: _uuid.v4(),
      eventoId: eventId,
      startAtReal: now,
      createdBy: currentUserId,
      createdAt: now,
      syncStatus: 'pending',
    );

    // Atualiza o evento
    final updatedEvent = event.copyWith(
      status: EventStatus.emAndamento,
      visitSessionId: session.id,
      updatedAt: now,
      syncStatus: 'pending',
    );

    // Salva no banco
    await _repository.updateEvent(updatedEvent);
    await _repository.saveSession(session);

    // Atualiza estado
    _updateEvent(updatedEvent);
    state = state.copyWith(sessions: [...state.sessions, session]);

    return session;
  }

  /// Finaliza um evento (EM_ANDAMENTO → FINALIZANDO)
  Future<Event> finalizeEvent(String eventId) async {
    final event = state.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw ArgumentError('Evento não encontrado'),
    );

    if (!EventRules.canTransitionTo(event.status, EventStatus.finalizando)) {
      throw StateError(
        'Evento não pode ser finalizado no status ${event.status.label}',
      );
    }

    final updatedEvent = event.copyWith(
      status: EventStatus.finalizando,
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
    );

    await _repository.updateEvent(updatedEvent);
    _updateEvent(updatedEvent);

    return updatedEvent;
  }

  /// Completa um evento (FINALIZANDO → CONCLUIDO)
  Future<Event> completeEvent(String eventId, {String? notasFinais}) async {
    final event = state.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw ArgumentError('Evento não encontrado'),
    );

    if (!EventRules.canTransitionTo(event.status, EventStatus.concluido)) {
      throw StateError(
        'Evento não pode ser concluído no status ${event.status.label}',
      );
    }

    final now = DateTime.now();

    // Atualiza o evento
    final updatedEvent = event.copyWith(
      status: EventStatus.concluido,
      updatedAt: now,
      syncStatus: 'pending',
    );

    // Fecha a sessão se existir
    if (event.visitSessionId != null) {
      final session = state.sessions.firstWhere(
        (s) => s.id == event.visitSessionId,
        orElse: () => throw ArgumentError('Sessão não encontrada'),
      );

      final updatedSession = session.copyWith(
        endAtReal: now,
        duracaoMin: now.difference(session.startAtReal).inMinutes,
        notasFinais: notasFinais,
        syncStatus: 'pending',
      );

      await _repository.updateSession(updatedSession);
      _updateSession(updatedSession);
    }

    await _repository.updateEvent(updatedEvent);
    _updateEvent(updatedEvent);

    return updatedEvent;
  }

  /// Cancela um evento
  Future<Event> cancelEvent(String eventId) async {
    final event = state.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw ArgumentError('Evento não encontrado'),
    );

    if (!EventRules.canCancel(event.status)) {
      throw StateError(
        'Evento não pode ser cancelado no status ${event.status.label}',
      );
    }

    final now = DateTime.now();

    // Cancela sessão se estiver ativa
    if (event.visitSessionId != null) {
      final session = state.sessions.firstWhere(
        (s) => s.id == event.visitSessionId,
        orElse: () => throw ArgumentError('Sessão não encontrada'),
      );

      if (session.isActive) {
        final updatedSession = session.copyWith(
          endAtReal: now,
          duracaoMin: now.difference(session.startAtReal).inMinutes,
          notasFinais: 'Cancelado',
          syncStatus: 'pending',
        );

        await _repository.updateSession(updatedSession);
        _updateSession(updatedSession);
      }
    }

    final updatedEvent = event.copyWith(
      status: EventStatus.cancelado,
      updatedAt: now,
      syncStatus: 'pending',
    );

    // Cancela notificações
    await _notificationService.cancelEventNotifications(eventId);

    await _repository.updateEvent(updatedEvent);
    _updateEvent(updatedEvent);

    return updatedEvent;
  }

  /// Retorna eventos de um período específico
  List<Event> getEventsByDateRange(DateTime start, DateTime end) {
    return state.events.where((event) {
      return event.dataInicioPlanejada.isBefore(end) &&
          event.dataFimPlanejada.isAfter(start);
    }).toList();
  }

  /// Retorna eventos de um dia específico
  List<Event> getEventsByDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return getEventsByDateRange(start, end);
  }

  /// Retorna evento por ID
  Event? getEventById(String id) {
    try {
      return state.events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Retorna sessão por ID
  VisitSession? getSessionById(String id) {
    try {
      return state.sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Retorna sessões ativas
  List<VisitSession> getActiveSessions() {
    return state.sessions.where((s) => s.isActive).toList();
  }

  /// Atualiza um evento na lista
  void _updateEvent(Event event) {
    final index = state.events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      final updatedEvents = [...state.events];
      updatedEvents[index] = event;
      state = state.copyWith(events: updatedEvents);
    }
  }

  /// Atualiza uma sessão na lista
  void _updateSession(VisitSession session) {
    final index = state.sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      final updatedSessions = [...state.sessions];
      updatedSessions[index] = session;
      state = state.copyWith(sessions: updatedSessions);
    }
  }

  /// Limpa conflitos detectados
  void clearConflicts() {
    state = state.copyWith(conflicts: []);
  }

  Event? _resolveDistanceWarningEvent({
    required DateTime dataInicioPlanejada,
    required double latitude,
    required double longitude,
    required TimeOfDay startTime,
    String? eventId,
  }) {
    if (eventId != null) {
      return getEventById(eventId);
    }

    final matches =
        state.events
            .where(
              (event) => DateUtils.isSameDay(
                event.dataInicioPlanejada,
                dataInicioPlanejada,
              ),
            )
            .where((event) => event.startTime == startTime)
            .where(
              (event) =>
                  event.latitude == latitude && event.longitude == longitude,
            )
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    if (matches.isNotEmpty) {
      return matches.first;
    }

    final fallbackMatches =
        state.events
            .where(
              (event) => DateUtils.isSameDay(
                event.dataInicioPlanejada,
                dataInicioPlanejada,
              ),
            )
            .where((event) => event.startTime == startTime)
            .toList()
          ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return fallbackMatches.isNotEmpty ? fallbackMatches.first : null;
  }

  double _haversineKm(double lat1, double lon1, double lat2, double lon2) {
    const radiusKm = 6371.0;
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);
    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(_toRadians(lat1)) *
            math.cos(_toRadians(lat2)) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    return radiusKm * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;
}

/// Provider do repositório
final agendaRepositoryProvider = Provider<AgendaRepository>(
  (ref) => AgendaRepository(),
);

/// Provider do serviço de notificações
final agendaNotificationServiceProvider = Provider<AgendaNotificationService>(
  (ref) => AgendaNotificationService(),
);

/// Provider global da Agenda
final agendaProvider = StateNotifierProvider<AgendaNotifier, AgendaState>(
  (ref) => AgendaNotifier(
    ref.watch(agendaRepositoryProvider),
    ref.watch(agendaNotificationServiceProvider),
  ),
);
