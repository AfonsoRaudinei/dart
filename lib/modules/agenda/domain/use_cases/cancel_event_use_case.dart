import '../entities/event.dart';
import '../entities/visit_session.dart';
import '../enums/event_status.dart';
import '../rules/event_rules.dart';
import '../repositories/i_agenda_repository.dart';
import '../services/i_agenda_notification_service.dart';

/// Caso de uso: cancela um evento
///
/// Responsabilidades:
///   - Validar se o evento pode ser cancelado
///   - Fechar VisitSession ativa (se existir)
///   - Cancelar notificações agendadas
///   - Persistir evento e sessão
///
/// Retorna: tupla (updatedEvent, updatedSession?) — sem mutação de estado
class CancelEventUseCase {
  final IAgendaRepository _repository;
  final IAgendaNotificationService _notificationService;

  CancelEventUseCase(this._repository, this._notificationService);

  Future<({Event updatedEvent, VisitSession? updatedSession})> execute({
    required Event event,
    required List<VisitSession> sessions,
  }) async {
    if (!EventRules.canCancel(event.status)) {
      throw StateError(
        'Evento não pode ser cancelado no status ${event.status.label}',
      );
    }

    final now = DateTime.now();

    // Cancela sessão se estiver ativa
    VisitSession? updatedSession;
    if (event.visitSessionId != null) {
      final session = sessions.firstWhere(
        (s) => s.id == event.visitSessionId,
        orElse: () => throw ArgumentError('Sessão não encontrada'),
      );

      if (session.isActive) {
        updatedSession = session.copyWith(
          endAtReal: now,
          duracaoMin: now.difference(session.startAtReal).inMinutes,
          notasFinais: 'Cancelado',
          syncStatus: 'pending',
        );

        await _repository.updateSession(updatedSession);
      }
    }

    final updatedEvent = event.copyWith(
      status: EventStatus.cancelado,
      updatedAt: now,
      syncStatus: 'pending',
    );

    // Cancela notificações
    await _notificationService.cancelEventNotifications(event.id);

    await _repository.updateEvent(updatedEvent);

    return (updatedEvent: updatedEvent, updatedSession: updatedSession);
  }
}
