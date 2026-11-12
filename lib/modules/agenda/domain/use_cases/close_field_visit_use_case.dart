import 'package:soloforte_app/core/contracts/i_visit_session_writer.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';

import '../entities/event.dart';
import '../entities/visit_session.dart';
import '../enums/event_status.dart';
import '../field_visit_title.dart';
import '../repositories/i_agenda_repository.dart';
import 'complete_event_use_case.dart';
import 'finalize_event_use_case.dart';

/// Encerra a visita de campo: em andamento → finalizando → concluído.
///
/// Fecha a sessão da agenda para o observer gerar o relatório.
/// O espelho em `visit_sessions` segue o [CompleteEventUseCase].
class CloseFieldVisitUseCase {
  CloseFieldVisitUseCase(this._repository, this._visitSessionWriter);

  final IAgendaRepository _repository;
  final IVisitSessionWriter _visitSessionWriter;

  /// Null quando não há evento para a sessão.
  Future<({Event event, VisitSession session})?> execute({
    required String sessionId,
    DateTime? endTime,
  }) async {
    final event = await _repository.getEventBySessionId(sessionId);
    if (event == null || event.status == EventStatus.cancelado) return null;

    final existingSession = await _ensureSession(event, sessionId);
    if (event.status == EventStatus.concluido) {
      return (event: event, session: existingSession);
    }

    final end = endTime ?? DateTime.now();
    var current = event.copyWith(
      dataFimPlanejada: fieldVisitPlannedEnd(event.dataInicioPlanejada, end),
      syncStatus: SyncStatusContract.pendingSync,
      updatedAt: end,
    );
    await _repository.updateEvent(current);

    if (current.status == EventStatus.emAndamento) {
      current = await FinalizeEventUseCase(_repository).execute(current);
    }
    if (current.status != EventStatus.finalizando) {
      return (event: current, session: existingSession);
    }

    final sessions = await _repository.getAllSessions();
    final result = await CompleteEventUseCase(
      _repository,
      _visitSessionWriter,
    ).execute(event: current, sessions: sessions);

    return (
      event: result.updatedEvent,
      session: result.updatedSession ?? existingSession,
    );
  }

  Future<VisitSession> _ensureSession(Event event, String sessionId) async {
    final found = await _repository.getSessionById(sessionId);
    if (found != null) return found;

    final userId = LocalSessionIdentity.resolveUserId();
    final session = VisitSession(
      id: sessionId,
      eventoId: event.id,
      startAtReal: event.dataInicioPlanejada,
      createdBy: userId.isEmpty ? 'local' : userId,
      createdAt: event.createdAt,
      syncStatus: SyncStatusContract.pendingSync,
      clienteId: event.clienteId,
    );
    await _repository.saveSession(session);
    return session;
  }
}
