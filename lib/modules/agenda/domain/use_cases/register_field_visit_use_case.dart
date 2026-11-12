import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:uuid/uuid.dart';

import '../entities/event.dart';
import '../entities/visit_session.dart';
import '../enums/event_status.dart';
import '../enums/event_type.dart';
import '../field_visit_title.dart';
import '../repositories/i_agenda_repository.dart';

/// Cria o par evento + sessão da agenda para um check-in feito no mapa.
///
/// O id da sessão da agenda é o id da `visit_sessions` (ADR-060).
/// Não chama o espelho inverso: a linha em `visit_sessions` já existe.
class RegisterFieldVisitUseCase {
  RegisterFieldVisitUseCase(this._repository);

  final IAgendaRepository _repository;
  final _uuid = const Uuid();

  /// Retorna null quando a sessão já tem evento (inclusive soft delete).
  Future<({Event event, VisitSession session})?> execute(
    FieldVisitCheckIn input, {
    required bool finished,
  }) async {
    final existing = await _repository.getEventBySessionId(input.sessionId);
    if (existing != null) return null;

    final now = DateTime.now();
    final start = input.startTime;
    final end = finished
        ? fieldVisitPlannedEnd(start, input.endTime)
        : fieldVisitPlannedEnd(start, null);
    final eventId = _uuid.v4();
    final userId = LocalSessionIdentity.resolveUserId();
    final createdBy = userId.isEmpty ? 'local' : userId;

    final event = Event(
      id: eventId,
      tipo: EventType.visitaTecnica,
      clienteId: input.clientId,
      fazendaId: _nonEmpty(input.farmId),
      talhaoId: _nonEmpty(input.areaId),
      titulo: fieldVisitTitle(input.activityType),
      dataInicioPlanejada: start,
      dataFimPlanejada: end,
      status: finished ? EventStatus.concluido : EventStatus.emAndamento,
      visitSessionId: input.sessionId,
      createdAt: now,
      updatedAt: now,
      syncStatus: SyncStatusContract.pendingSync,
      latitude: input.latitude,
      longitude: input.longitude,
    );

    final sessionEnd = finished ? (input.endTime ?? end) : null;
    final session = VisitSession(
      id: input.sessionId,
      eventoId: eventId,
      startAtReal: start,
      endAtReal: sessionEnd,
      duracaoMin: sessionEnd
          ?.difference(start)
          .inMinutes
          .clamp(0, 1000000)
          .toInt(),
      createdBy: createdBy,
      createdAt: now,
      syncStatus: SyncStatusContract.pendingSync,
      clienteId: input.clientId,
    );

    await _repository.saveEvent(event);
    await _repository.saveSession(session);
    return (event: event, session: session);
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
