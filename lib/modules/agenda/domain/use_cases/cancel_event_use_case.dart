import 'package:flutter/foundation.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_writer.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
import '../entities/event.dart';
import '../entities/visit_session.dart';
import '../enums/event_status.dart';
import '../rules/event_rules.dart';
import '../repositories/i_agenda_repository.dart';
import '../services/i_agenda_notification_service.dart';

/// Caso de uso: cancela um evento
///
/// Responsabilidades:
///   - Validar se o evento pode ser cancelado
///   - Fechar VisitSession ativa (se existir)
///   - Encerrar espelho em visit_sessions (ADR-048)
///   - Cancelar notificações agendadas
///   - Persistir evento e sessão
///
/// Retorna: tupla (updatedEvent, updatedSession?) — sem mutação de estado
class CancelEventUseCase {
  CancelEventUseCase(
    this._repository,
    this._notificationService,
    this._visitSessionWriter,
  );

  final IAgendaRepository _repository;
  final IAgendaNotificationService _notificationService;
  final IVisitSessionWriter _visitSessionWriter;

  Future<({Event updatedEvent, VisitSession? updatedSession})> execute({
    required Event event,
    required List<VisitSession> sessions,
  }) async {
    if (!EventRules.canCancel(event.status)) {
      throw StateError(
        'Evento não pode ser cancelado no status ${event.status.label}',
      );
    }

    final now = DateTime.now();

    // Cancela sessão se estiver ativa
    VisitSession? updatedSession;
    if (event.visitSessionId != null) {
      final session = sessions.firstWhere(
        (s) => s.id == event.visitSessionId,
        orElse: () => throw ArgumentError('Sessão não encontrada'),
      );

      if (session.isActive) {
        updatedSession = session.copyWith(
          endAtReal: now,
          duracaoMin: now.difference(session.startAtReal).inMinutes,
          notasFinais: 'Cancelado',
          syncStatus: SyncStatusContract.pendingSync,
        );

        await _repository.updateSession(updatedSession);
        await _finishMirrorSession(updatedSession.id, now);
      }
    }

    final updatedEvent = event.copyWith(
      status: EventStatus.cancelado,
      updatedAt: now,
      syncStatus: SyncStatusContract.pendingSync,
    );

    // Cancela notificações
    await _notificationService.cancelEventNotifications(event.id);

    await _repository.updateEvent(updatedEvent);

    return (updatedEvent: updatedEvent, updatedSession: updatedSession);
  }

  Future<void> _finishMirrorSession(String sessionId, DateTime endTime) async {
    try {
      await _visitSessionWriter.finishMirrorSession(sessionId, endTime);
    } catch (error, stackTrace) {
      debugPrint(
        'CancelEventUseCase: falha ao encerrar espelho $sessionId — '
        '$error\n$stackTrace',
      );
    }
  }
}
