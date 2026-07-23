import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/session/session_models.dart';
import '../../data/repositories/agenda_repository.dart';
import '../../data/services/agenda_notification_service.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/visit.dart';
import '../../domain/entities/visit_session.dart';
import '../../domain/enums/event_type.dart';
import '../../domain/use_cases/cancel_event_use_case.dart';
import '../../domain/use_cases/complete_event_use_case.dart';
import '../../domain/use_cases/create_event_use_case.dart';
import '../../domain/use_cases/delete_event_use_case.dart';
import '../../domain/use_cases/finalize_event_use_case.dart';
import '../../domain/use_cases/start_event_use_case.dart';
import '../../domain/use_cases/update_event_use_case.dart';
import '../../infra/agenda_domain_adapters.dart';
import '../widgets/distance_warning_dialog.dart';
import 'agenda_state.dart';

part 'agenda_provider.g.dart';

@Riverpod(keepAlive: true)
AgendaRepository agendaRepository(AgendaRepositoryRef ref) {
  return AgendaRepository();
}

@Riverpod(keepAlive: true)
AgendaNotificationService agendaNotificationService(
  AgendaNotificationServiceRef ref,
) {
  return AgendaNotificationService();
}

/// Provider global da agenda — ADR-008 (Fase 4: @riverpod, substitui StateNotifier).
@Riverpod(keepAlive: true)
class Agenda extends _$Agenda {
  AgendaRepository get _repository => ref.read(agendaRepositoryProvider);

  AgendaNotificationService get _notificationService =>
      ref.read(agendaNotificationServiceProvider);

  @override
  AgendaState build() {
    final session = ref.watch(sessionControllerProvider);
    SessionController.registerLogoutInvalidation(
      key: 'agendaProvider',
      invalidate: (ref) => ref.invalidate(agendaProvider),
    );
    if (session is! SessionPublic) {
      Future.microtask(_loadFromDatabase);
    }
    Future.microtask(() async {
      await _notificationService.initialize();
      AgendaNotificationService.onEventTap = (eventId) {
        ref.read(routerProvider).go(AppRoutes.agendaEvent(eventId));
      };
    });
    return const AgendaState();
  }

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

  Future<void> reload() async {
    await _loadFromDatabase();
  }

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
          AgendaRepositoryAdapter(_repository),
          AgendaNotificationServiceAdapter(_notificationService),
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

    state = state.copyWith(
      events: [...state.events, result.event],
      conflicts: result.conflicts,
    );

    return result.event;
  }

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
          AgendaRepositoryAdapter(_repository),
          AgendaNotificationServiceAdapter(_notificationService),
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

  Future<VisitSession> startEvent(String eventId, String currentUserId) async {
    final event = state.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw ArgumentError('Evento não encontrado'),
    );

    final result = await StartEventUseCase(
      AgendaRepositoryAdapter(_repository),
    ).execute(event: event, currentUserId: currentUserId);

    _updateEvent(result.updatedEvent);
    state = state.copyWith(sessions: [...state.sessions, result.session]);

    return result.session;
  }

  Future<Event> finalizeEvent(String eventId) async {
    final event = state.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw ArgumentError('Evento não encontrado'),
    );

    final updatedEvent = await FinalizeEventUseCase(
      AgendaRepositoryAdapter(_repository),
    ).execute(event);

    _updateEvent(updatedEvent);
    return updatedEvent;
  }

  Future<Event> completeEvent(String eventId, {String? notasFinais}) async {
    final event = state.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw ArgumentError('Evento não encontrado'),
    );

    final result = await CompleteEventUseCase(
      AgendaRepositoryAdapter(_repository),
    ).execute(event: event, sessions: state.sessions, notasFinais: notasFinais);

    if (result.updatedSession != null) {
      _updateSession(result.updatedSession!);
    }
    _updateEvent(result.updatedEvent);
    return result.updatedEvent;
  }

  Future<Event> cancelEvent(String eventId) async {
    final event = state.events.firstWhere(
      (e) => e.id == eventId,
      orElse: () => throw ArgumentError('Evento não encontrado'),
    );

    final result = await CancelEventUseCase(
      AgendaRepositoryAdapter(_repository),
      AgendaNotificationServiceAdapter(_notificationService),
    ).execute(event: event, sessions: state.sessions);

    if (result.updatedSession != null) {
      _updateSession(result.updatedSession!);
    }
    _updateEvent(result.updatedEvent);
    return result.updatedEvent;
  }

  Future<void> deleteEvent(String eventId) async {
    await DeleteEventUseCase(
      AgendaRepositoryAdapter(_repository),
    ).execute(eventId);

    state = state.copyWith(
      events: state.events.where((e) => e.id != eventId).toList(),
    );
  }

  List<Event> getEventsByDateRange(DateTime start, DateTime end) {
    return state.events.where((event) {
      return event.dataInicioPlanejada.isBefore(end) &&
          event.dataFimPlanejada.isAfter(start);
    }).toList();
  }

  List<Event> getEventsByDay(DateTime day) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return getEventsByDateRange(start, end);
  }

  Event? getEventById(String id) {
    try {
      return state.events.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  VisitSession? getSessionById(String id) {
    try {
      return state.sessions.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  List<VisitSession> getActiveSessions() {
    return state.sessions.where((s) => s.isActive).toList();
  }

  void clearConflicts() {
    state = state.copyWith(conflicts: []);
  }

  void _updateEvent(Event event) {
    final index = state.events.indexWhere((e) => e.id == event.id);
    if (index != -1) {
      final updatedEvents = [...state.events];
      updatedEvents[index] = event;
      state = state.copyWith(events: updatedEvents);
    }
  }

  void _updateSession(VisitSession session) {
    final index = state.sessions.indexWhere((s) => s.id == session.id);
    if (index != -1) {
      final updatedSessions = [...state.sessions];
      updatedSessions[index] = session;
      state = state.copyWith(sessions: updatedSessions);
    }
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
