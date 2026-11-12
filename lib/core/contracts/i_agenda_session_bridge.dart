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

/// Check-in de campo que a agenda deve espelhar.
///
/// [sessionId] é o id já gravado em `visit_sessions`. A agenda reutiliza
/// esse UUID na sessão própria (ADR-060).
class FieldVisitCheckIn {
  const FieldVisitCheckIn({
    required this.sessionId,
    required this.clientId,
    required this.startTime,
    this.farmId,
    this.areaId,
    this.activityType,
    this.latitude = 0,
    this.longitude = 0,
    this.endTime,
  });

  final String sessionId;
  final String clientId;
  final DateTime startTime;
  final String? farmId;
  final String? areaId;
  final String? activityType;
  final double latitude;
  final double longitude;

  /// Preenchido só no acerto de visita já encerrada.
  final DateTime? endTime;
}

/// Contrato de integração agenda ↔ visitas.
/// Permite que visitas/ notifique eventos de agenda sem importar agenda/.
/// Implementado em agenda/infra/agenda_session_bridge_adapter.dart.
/// Consumidores autorizados: visitas/ (via visit_controller), map/ (acerto)
/// ADR-024 · ADR-060
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

  /// Cria evento em andamento e sessão da agenda com o id da visita.
  /// Não faz nada se já existir evento para [FieldVisitCheckIn.sessionId].
  /// ADR-060
  Future<void> registerFieldCheckIn(FieldVisitCheckIn input);

  /// Atualiza fazenda e talhão do evento ligado à sessão. No-op sem evento.
  Future<void> updateFieldVisitPlace({
    required String sessionId,
    String? farmId,
    String? areaId,
    bool clearArea = false,
  });

  /// Conclui o evento ligado à sessão e fecha a sessão da agenda.
  /// No-op se não houver evento.
  Future<void> closeFieldVisit(String sessionId);

  /// Registra visita já encerrada, sem passar por em andamento.
  /// Não recria evento excluído que ainda guarda o mesmo `visit_session_id`.
  Future<void> registerFinishedFieldVisit(FieldVisitCheckIn input);
}
