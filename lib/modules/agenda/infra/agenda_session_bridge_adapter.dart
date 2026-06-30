// lib/modules/agenda/infra/agenda_session_bridge_adapter.dart
//
// Adapter autorizado: implementa IAgendaSessionBridge usando IAgendaRepository.
// É a única ponte entre core/contracts/IAgendaSessionBridge e agenda/.
//
// ADR-024 — DT-023-3
// NÃO importar este arquivo fora de agenda/ ou da injeção de dependência.
//
// Responsabilidades:
//   linkSessionToEvent → getEventById + saveEvent(copyWith visitSessionId + emAndamento)
//   markEventAsDone    → getEventBySessionId + saveEvent(copyWith concluido)

import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import '../data/repositories/agenda_repository.dart';
import '../domain/enums/event_status.dart';

/// Implementação concreta de IAgendaSessionBridge.
/// Vive em agenda/infra/ — dona dos dados de evento de agenda.
class AgendaSessionBridgeAdapter implements IAgendaSessionBridge {
  const AgendaSessionBridgeAdapter(this._repository);

  final AgendaRepository _repository;

  @override
  Future<void> linkSessionToEvent({
    required String agendaEventId,
    required String sessionId,
  }) async {
    final event = await _repository.getEventById(agendaEventId);
    if (event == null) return; // noop seguro — evento não encontrado
    await _repository.saveEvent(
      event.copyWith(
        visitSessionId: sessionId,
        status: EventStatus.emAndamento,
      ),
    );
  }

  @override
  Future<void> markEventAsDone(String sessionId) async {
    final event = await _repository.getEventBySessionId(sessionId);
    if (event == null) return; // noop seguro — nenhum evento vinculado
    await _repository.saveEvent(
      event.copyWith(status: EventStatus.concluido),
    );
  }
}
