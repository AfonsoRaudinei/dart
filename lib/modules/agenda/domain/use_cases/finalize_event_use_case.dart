import '../entities/event.dart';
import '../enums/event_status.dart';
import '../rules/event_rules.dart';
import '../repositories/i_agenda_repository.dart';

/// Caso de uso: finaliza um evento (EM_ANDAMENTO → FINALIZANDO)
///
/// Responsabilidades:
///   - Validar transição de status
///   - Persistir evento atualizado
///
/// Retorna: evento atualizado — sem mutação de estado
class FinalizeEventUseCase {
  final IAgendaRepository _repository;

  FinalizeEventUseCase(this._repository);

  Future<Event> execute(Event event) async {
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

    return updatedEvent;
  }
}
