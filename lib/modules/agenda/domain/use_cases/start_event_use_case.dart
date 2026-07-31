import 'package:flutter/foundation.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_writer.dart';
import 'package:soloforte_app/core/contracts/visit_session_mirror_input.dart';
import 'package:uuid/uuid.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';
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
///   - Espelhar sessão em visit_sessions (ADR-048 — mesmo UUID)
///
/// Pré-condição: verificação de visita ativa já realizada pelo caller (AgendaNotifier)
///
/// Retorna: tupla (updatedEvent, session) — sem mutação de estado
class StartEventUseCase {
  StartEventUseCase(this._repository, this._visitSessionWriter);

  final IAgendaRepository _repository;
  final IVisitSessionWriter _visitSessionWriter;
  final _uuid = const Uuid();

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
      syncStatus: SyncStatusContract.pendingSync,
    );

    // Atualiza o evento
    final updatedEvent = event.copyWith(
      status: EventStatus.emAndamento,
      visitSessionId: session.id,
      updatedAt: now,
      syncStatus: SyncStatusContract.pendingSync,
    );

    // Persiste
    await _repository.updateEvent(updatedEvent);
    await _repository.saveSession(session);

    try {
      await _visitSessionWriter.createMirrorSession(
        VisitSessionMirrorInput(
          id: session.id,
          producerId: event.clienteId,
          farmId: event.fazendaId,
          areaId: event.talhaoId,
          activityType: event.tipo.name,
          startTime: session.startAtReal,
          initialLat: event.latitude ?? 0.0,
          initialLong: event.longitude ?? 0.0,
          userId: currentUserId,
        ),
      );
    } catch (error, stackTrace) {
      debugPrint(
        'StartEventUseCase: falha ao espelhar sessão ${session.id} em '
        'visit_sessions — $error\n$stackTrace',
      );
    }

    return (updatedEvent: updatedEvent, session: session);
  }
}
