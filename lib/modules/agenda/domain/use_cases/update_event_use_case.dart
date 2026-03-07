import 'package:flutter/material.dart';
import '../entities/event.dart';
import '../entities/visit.dart';
import '../enums/event_status.dart';
import '../rules/event_rules.dart';
import '../repositories/i_agenda_repository.dart';
import '../services/i_agenda_notification_service.dart';

/// Caso de uso: atualiza um evento existente
///
/// Responsabilidades:
///   - Validar se o evento pode ser editado (status)
///   - Validar datas e título
///   - Detectar conflitos de horário com outros eventos
///   - Persistir no repositório
///   - Atualizar notificações (cancela + reagenda)
///
/// Retorna: evento atualizado — sem mutação de estado
class UpdateEventUseCase {
  final IAgendaRepository _repository;
  final IAgendaNotificationService _notificationService;

  UpdateEventUseCase(this._repository, this._notificationService);

  Future<Event> execute({
    required Event currentEvent,
    String? titulo,
    DateTime? dataInicioPlanejada,
    DateTime? dataFimPlanejada,
    TimeOfDay? startTime,
    TimeOfDay? endTime,
    VisitPriority? priority,
    double? latitude,
    double? longitude,
    required List<Event> currentEvents,
  }) async {
    // Valida se pode editar
    if (currentEvent.status == EventStatus.emAndamento ||
        currentEvent.status == EventStatus.finalizando) {
      throw StateError('Não é possível editar visita em andamento');
    }

    if (currentEvent.status == EventStatus.concluido) {
      throw StateError('Não é possível editar visita concluída');
    }

    // Validações
    if (titulo != null) {
      final titleError = EventRules.validateTitulo(titulo);
      if (titleError != null) throw ArgumentError(titleError);
    }

    final newDataInicio =
        dataInicioPlanejada ?? currentEvent.dataInicioPlanejada;
    final newDataFim = dataFimPlanejada ?? currentEvent.dataFimPlanejada;

    final dateError = EventRules.validateEventDates(newDataInicio, newDataFim);
    if (dateError != null) throw ArgumentError(dateError);

    final newStartTime = startTime ?? currentEvent.startTime;
    final newEndTime = endTime ?? currentEvent.endTime;

    // Valida conflito de horário
    if (newStartTime != null && newEndTime != null) {
      // Cria evento temporário com os novos valores para verificação
      final tempEvent = currentEvent.copyWith(
        dataInicioPlanejada: newDataInicio,
        dataFimPlanejada: newDataFim,
        startTime: newStartTime,
        endTime: newEndTime,
        priority: priority ?? currentEvent.priority,
        latitude: latitude ?? currentEvent.latitude,
        longitude: longitude ?? currentEvent.longitude,
      );

      // Verifica conflito com outros eventos (excluindo o próprio)
      for (final existing in currentEvents) {
        if (existing.id == currentEvent.id) continue;
        if (existing.status.isFinished) continue;
        if (tempEvent.hasTimeConflictWith(existing)) {
          throw StateError(
            'Conflito de horário detectado com a visita "${existing.titulo}"',
          );
        }
      }
    }

    final updatedEvent = currentEvent.copyWith(
      titulo: titulo,
      dataInicioPlanejada: dataInicioPlanejada,
      dataFimPlanejada: dataFimPlanejada,
      startTime: startTime,
      endTime: endTime,
      priority: priority,
      latitude: latitude,
      longitude: longitude,
      updatedAt: DateTime.now(),
      syncStatus: 'pending',
    );

    // Persiste
    await _repository.updateEvent(updatedEvent);

    // Atualiza notificações
    await _notificationService.cancelEventNotifications(currentEvent.id);
    await _notificationService.scheduleEventNotifications(updatedEvent);

    return updatedEvent;
  }
}
