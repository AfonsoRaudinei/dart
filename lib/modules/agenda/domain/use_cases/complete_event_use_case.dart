import 'package:flutter/foundation.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_writer.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
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
///   - Encerrar espelho em visit_sessions (ADR-048)
///   - Persistir evento e sessão
///
/// Retorna: tupla (updatedEvent, updatedSession?) — sem mutação de estado
class CompleteEventUseCase {
  CompleteEventUseCase(this._repository, this._visitSessionWriter);

  final IAgendaRepository _repository;
  final IVisitSessionWriter _visitSessionWriter;

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
      syncStatus: SyncStatusContract.pendingSync,
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
        syncStatus: SyncStatusContract.pendingSync,
      );

      await _repository.updateSession(updatedSession);
      await _finishMirrorSession(updatedSession.id, now);
    }

    await _repository.updateEvent(updatedEvent);

    return (updatedEvent: updatedEvent, updatedSession: updatedSession);
  }

  Future<void> _finishMirrorSession(String sessionId, DateTime endTime) async {
    try {
      await _visitSessionWriter.finishMirrorSession(sessionId, endTime);
    } catch (error, stackTrace) {
      debugPrint(
        'CompleteEventUseCase: falha ao encerrar espelho $sessionId — '
        '$error\n$stackTrace',
      );
    }
  }
}
