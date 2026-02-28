import 'package:uuid/uuid.dart';
import '../entities/event.dart';
import '../entities/visit_session.dart';
import '../enums/event_status.dart';
import '../rules/event_rules.dart';
import '../repositories/i_agenda_repository.dart';

/// Caso de uso: inicia um evento (AGENDADO → EM_ANDAMENTO)
///
/// Responsabilidades:
///   - Validar transição de status do evento
///   - Criar VisitSession
///   - Persistir evento atualizado e sessão criada
///
/// Pré-condição: verificação de visita ativa já realizada pelo caller (AgendaNotifier)
///
/// Retorna: tupla (updatedEvent, session) — sem mutação de estado
class StartEventUseCase {
  final IAgendaRepository _repository;
  final _uuid = const Uuid();

  StartEventUseCase(this._repository);

  Future<({Event updatedEvent, VisitSession session})> execute({
    required Event event,
    required String currentUserId,
  }) async {
    if (!EventRules.canTransitionTo(event.status, EventStatus.emAndamento)) {
      throw StateError(
        'Evento não pode ser iniciado no status ${event.status.label}',
      );
    }

    final now = DateTime.now();

    // Cria a VisitSession
    final session = VisitSession(
      id: _uuid.v4(),
      eventoId: event.id,
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

    // Persiste
    await _repository.updateEvent(updatedEvent);
    await _repository.saveSession(session);

    return (updatedEvent: updatedEvent, session: session);
  }
}
