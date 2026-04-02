// lib/core/contracts/i_agenda_observable.dart
//
// Contratos neutros para observação do estado de agenda.
// ADR-025 (origem — DT-025-2: visit_completion_observer importa agenda/ diretamente)
//
// PROIBIDO: importar lib/modules/ neste arquivo.
// PROIBIDO: expor Event, VisitSession ou qualquer tipo interno de agenda/.
//
// Expõe apenas os campos necessários ao visit_completion_observer:
//   • AgendaSessionData — sessão de visita (id, start, end, createdBy)
//   • AgendaEventData   — evento de agenda (visitSessionId, clienteId, fazendaId, talhaoId)
//   • AgendaObservableState — estado observável neutro

/// DTO mínimo de sessão de visita para consumo pelo observer de conclusão.
/// NÃO é espelho de VisitSession — apenas os campos necessários para detectar
/// transições e construir VisitReportInput.
/// ADR-025
class AgendaSessionData {
  const AgendaSessionData({
    required this.id,
    required this.startAtReal,
    required this.createdBy,
    this.endAtReal,
  });

  /// ID da sessão de visita.
  final String id;

  /// Data/hora real de início da sessão (UTC).
  final DateTime startAtReal;

  /// Data/hora real de encerramento (null = sessão ainda ativa).
  final DateTime? endAtReal;

  /// ID do agrônomo responsável pela sessão.
  final String createdBy;

  bool get isConcluded => endAtReal != null;
}

/// DTO mínimo de evento de agenda para consumo pelo observer de conclusão.
/// NÃO é espelho de Event — apenas campos necessários para construir
/// VisitReportInput (clienteId, fazendaId, talhaoId).
/// ADR-025
class AgendaEventData {
  const AgendaEventData({
    required this.id,
    required this.clienteId,
    this.visitSessionId,
    this.fazendaId,
    this.talhaoId,
  });

  final String id;

  /// ID do cliente/produtor associado ao evento.
  final String clienteId;

  /// ID da sessão de visita vinculada (null se não iniciada).
  final String? visitSessionId;

  /// ID da fazenda visitada (null se não informado).
  final String? fazendaId;

  /// ID do talhão visitado (null se não informado).
  final String? talhaoId;
}

/// Estado observável neutro da agenda — versão DTO de AgendaState.
/// Consumidores: map/ (via agendaObservableProvider)
/// ADR-025
class AgendaObservableState {
  const AgendaObservableState({
    this.sessions = const [],
    this.events = const [],
  });

  final List<AgendaSessionData> sessions;
  final List<AgendaEventData> events;
}
