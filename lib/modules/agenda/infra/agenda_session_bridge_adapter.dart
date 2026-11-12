// lib/modules/agenda/infra/agenda_session_bridge_adapter.dart
//
// Adapter autorizado: implementa IAgendaSessionBridge usando IAgendaRepository.
// É a única ponte entre core/contracts/IAgendaSessionBridge e agenda/.
//
// ADR-024 — DT-023-3
// ADR-060 — check-in de campo cria e conclui evento na agenda.
// NÃO importar este arquivo fora de agenda/ ou da injeção de dependência.
//
// Responsabilidades:
//   linkSessionToEvent → getEventById + saveEvent(copyWith visitSessionId + emAndamento)
//   markEventAsDone    → getEventBySessionId + saveEvent(copyWith concluido)
//   register/close     → use cases + AgendaFieldVisitSink (estado em memória)

import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_writer.dart';
import 'package:soloforte_app/core/contracts/visit_session_mirror_input.dart';
import 'package:soloforte_app/core/services/sync_status_contract.dart';

import '../domain/agenda_field_visit_sink.dart';
import '../domain/enums/event_status.dart';
import '../domain/repositories/i_agenda_repository.dart';
import '../domain/use_cases/close_field_visit_use_case.dart';
import '../domain/use_cases/register_field_visit_use_case.dart';
import '../domain/use_cases/update_field_visit_place_use_case.dart';

/// Implementação concreta de IAgendaSessionBridge.
/// Vive em agenda/infra/ — dona dos dados de evento de agenda.
class AgendaSessionBridgeAdapter implements IAgendaSessionBridge {
  AgendaSessionBridgeAdapter(
    this._repository, {
    IVisitSessionWriter? visitSessionWriter,
    AgendaFieldVisitSink? sink,
  }) : _visitSessionWriter = visitSessionWriter ?? const _NoopVisitWriter(),
       _sink = sink;

  final IAgendaRepository _repository;
  final IVisitSessionWriter _visitSessionWriter;
  final AgendaFieldVisitSink? _sink;

  @override
  Future<void> linkSessionToEvent({
    required String agendaEventId,
    required String sessionId,
  }) async {
    final event = await _repository.getEventById(agendaEventId);
    if (event == null) return;
    await _repository.saveEvent(
      event.copyWith(
        visitSessionId: sessionId,
        status: EventStatus.emAndamento,
        syncStatus: SyncStatusContract.pendingSync,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> markEventAsDone(String sessionId) async {
    final event = await _repository.getEventBySessionId(sessionId);
    if (event == null) return;
    await _repository.saveEvent(
      event.copyWith(
        status: EventStatus.concluido,
        syncStatus: SyncStatusContract.pendingSync,
        updatedAt: DateTime.now(),
      ),
    );
  }

  @override
  Future<void> registerFieldCheckIn(FieldVisitCheckIn input) async {
    final created = await RegisterFieldVisitUseCase(
      _repository,
    ).execute(input, finished: false);
    if (created == null) return;
    _sink?.upsertFieldVisit(event: created.event, session: created.session);
  }

  @override
  Future<void> updateFieldVisitPlace({
    required String sessionId,
    String? farmId,
    String? areaId,
    bool clearArea = false,
  }) async {
    final updated = await UpdateFieldVisitPlaceUseCase(_repository).execute(
      sessionId: sessionId,
      farmId: farmId,
      areaId: areaId,
      clearArea: clearArea,
    );
    if (updated == null) return;
    final session = await _repository.getSessionById(sessionId);
    if (session == null) return;
    _sink?.upsertFieldVisit(event: updated, session: session);
  }

  @override
  Future<void> closeFieldVisit(String sessionId) async {
    final closed = await CloseFieldVisitUseCase(
      _repository,
      _visitSessionWriter,
    ).execute(sessionId: sessionId);
    if (closed == null) return;
    _sink?.upsertFieldVisit(event: closed.event, session: closed.session);
  }

  @override
  Future<void> registerFinishedFieldVisit(FieldVisitCheckIn input) async {
    final created = await RegisterFieldVisitUseCase(
      _repository,
    ).execute(input, finished: true);
    if (created == null) return;
    _sink?.upsertFieldVisit(event: created.event, session: created.session);
  }
}

class _NoopVisitWriter implements IVisitSessionWriter {
  const _NoopVisitWriter();

  @override
  Future<void> createMirrorSession(VisitSessionMirrorInput input) async {}

  @override
  Future<void> finishMirrorSession(String sessionId, DateTime endTime) async {}
}
