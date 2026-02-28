import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../entities/event.dart';
import '../entities/visit.dart';
import '../enums/event_status.dart';
import '../enums/event_type.dart';
import '../rules/event_rules.dart';
import '../repositories/i_agenda_repository.dart';
import '../services/i_agenda_notification_service.dart';

/// Caso de uso: cria um novo evento de agenda
///
/// Responsabilidades:
///   - Validar datas e título
///   - Detectar conflitos de horário com eventos existentes
///   - Persistir no repositório
///   - Agendar notificações
///   - Detectar conflitos para exibição na UI
///
/// Retorna: tupla (event, conflicts) — sem mutação de estado
class CreateEventUseCase {
  final IAgendaRepository _repository;
  final IAgendaNotificationService _notificationService;
  final _uuid = const Uuid();

  CreateEventUseCase(this._repository, this._notificationService);

  Future<({Event event, List<Event> conflicts})> execute({
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
    VisitPriority priority = VisitPriority.normal,
    double? latitude,
    double? longitude,
    required List<Event> currentEvents,
  }) async {
    // Validações
    final dateError = EventRules.validateEventDates(
      dataInicioPlanejada,
      dataFimPlanejada,
    );
    if (dateError != null) throw ArgumentError(dateError);

    final titleError = EventRules.validateTitulo(titulo);
    if (titleError != null) throw ArgumentError(titleError);

    // Valida conflito de horário se startTime e endTime forem fornecidos
    if (startTime != null && endTime != null) {
      final conflicting = EventRules.findTimeConflict(
        currentEvents: currentEvents,
        date: dataInicioPlanejada,
        startTime: startTime,
        endTime: endTime,
      );
      if (conflicting != null) {
        throw StateError(
          'Conflito de horário detectado com a visita "${conflicting.titulo}" '
          'agendada para ${conflicting.formattedTimeRange}',
        );
      }
    }

    final now = DateTime.now();
    final newEvent = Event(
      id: _uuid.v4(),
      tipo: tipo,
      clienteId: clienteId,
      fazendaId: fazendaId,
      talhaoId: talhaoId,
      titulo: titulo,
      dataInicioPlanejada: dataInicioPlanejada,
      dataFimPlanejada: dataFimPlanejada,
      status: EventStatus.agendado,
      createdAt: now,
      updatedAt: now,
      syncStatus: 'pending',
      startTime: startTime,
      endTime: endTime,
      priority: priority,
      latitude: latitude,
      longitude: longitude,
    );

    // Detecta conflitos para exibição
    final conflicts = EventRules.detectConflicts(newEvent, currentEvents);

    // Persiste
    await _repository.saveEvent(newEvent);

    // Agenda notificações
    await _notificationService.scheduleEventNotifications(newEvent);

    return (event: newEvent, conflicts: conflicts);
  }
}
