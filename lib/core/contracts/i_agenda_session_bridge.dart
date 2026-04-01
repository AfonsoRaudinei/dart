// lib/core/contracts/i_agenda_session_bridge.dart
//
// Contrato neutro — acessível por todos os bounded contexts.
// ADR-024 (origem — DT-023-3: visit_controller importa agenda/ diretamente)
//
// PROIBIDO: importar lib/modules/ neste arquivo.
// PROIBIDO: expor Event, EventStatus ou qualquer tipo interno de agenda/.
//
// Encapsula as 2 operações de agenda usadas pelo visit_controller:
//   • startSession → linkSessionToEvent + markEventAsInProgress
//   • endSession   → markEventAsDone

/// Contrato de integração agenda ↔ visitas.
/// Permite que visitas/ notifique eventos de agenda sem importar agenda/.
/// Implementado em agenda/infra/agenda_session_bridge_adapter.dart.
/// Consumidores autorizados: visitas/ (via visit_controller)
/// ADR-024
abstract interface class IAgendaSessionBridge {
  /// Vincula a sessão de visita a um evento de agenda e marca o evento
  /// como "em andamento". Deve ser chamado no início da sessão.
  ///
  /// [agendaEventId] — ID do evento de agenda. Operação ignorada silenciosamente
  /// se o evento não for encontrado (noop seguro).
  Future<void> linkSessionToEvent({
    required String agendaEventId,
    required String sessionId,
  });

  /// Marca o evento de agenda vinculado à sessão como "concluído".
  /// Deve ser chamado ao encerrar a sessão.
  ///
  /// [sessionId] — ID da sessão de visita. Operação ignorada silenciosamente
  /// se nenhum evento vinculado for encontrado (noop seguro).
  Future<void> markEventAsDone(String sessionId);
}
