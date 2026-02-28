import '../entities/event.dart';
import '../entities/visit_session.dart';
import '../enums/event_status.dart';
import '../rules/event_rules.dart';
import '../repositories/i_agenda_repository.dart';

/// Caso de uso: conclui um evento (FINALIZANDO → CONCLUIDO)
///
/// Responsabilidades:
///   - Validar transição de status
///   - Fechar VisitSession ativa (se existir)
///   - Persistir evento e sessão
///
/// Retorna: tupla (updatedEvent, updatedSession?) — sem mutação de estado
class CompleteEventUseCase {
  final IAgendaRepository _repository;

  CompleteEventUseCase(this._repository);

  Future<({Event updatedEvent, VisitSession? updatedSession})> execute({
    required Event event,
    required List<VisitSession> sessions,
    String? notasFinais,
  }) async {
    if (!EventRules.canTransitionTo(event.status, EventStatus.concluido)) {
      throw StateError(
        'Evento não pode ser concluído no status ${event.status.label}',
      );
    }

    final now = DateTime.now();

    final updatedEvent = event.copyWith(
      status: EventStatus.concluido,
      updatedAt: now,
      syncStatus: 'pending',
    );

    // Fecha a sessão se existir
    VisitSession? updatedSession;
    if (event.visitSessionId != null) {
      final session = sessions.firstWhere(
        (s) => s.id == event.visitSessionId,
        orElse: () => throw ArgumentError('Sessão não encontrada'),
      );

      updatedSession = session.copyWith(
        endAtReal: now,
        duracaoMin: now.difference(session.startAtReal).inMinutes,
        notasFinais: notasFinais,
        syncStatus: 'pending',
      );

      await _repository.updateSession(updatedSession);
    }

    await _repository.updateEvent(updatedEvent);

    return (updatedEvent: updatedEvent, updatedSession: updatedSession);
  }
}
