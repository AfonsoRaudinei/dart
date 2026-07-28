// lib/modules/visitas/infra/visit_session_writer_adapter.dart
//
// Adapter autorizado: implementa IVisitSessionWriter usando VisitRepository.
// ADR-048 — espelhamento agenda_visit_sessions → visit_sessions (mesmo UUID).

import 'package:soloforte_app/core/contracts/i_visit_session_writer.dart';
import 'package:soloforte_app/core/contracts/visit_session_mirror_input.dart';

import '../data/repositories/visit_repository.dart';
import '../domain/models/visit_session.dart';

/// Persiste sessões espelhadas da agenda em `visit_sessions`.
class VisitSessionWriterAdapter implements IVisitSessionWriter {
  const VisitSessionWriterAdapter(this._repository);

  final VisitRepository _repository;

  @override
  Future<void> createMirrorSession(VisitSessionMirrorInput input) async {
    if (input.producerId.trim().isEmpty) {
      throw ArgumentError.value(
        input.producerId,
        'producerId',
        'producer_id é obrigatório para espelhar sessão em visit_sessions',
      );
    }
    if (input.userId.trim().isEmpty) {
      throw ArgumentError.value(
        input.userId,
        'userId',
        'user_id é obrigatório para espelhar sessão em visit_sessions',
      );
    }

    final now = DateTime.now();
    final session = VisitSession(
      id: input.id,
      producerId: input.producerId,
      farmId: input.farmId,
      areaId: input.areaId,
      activityType: input.activityType,
      startTime: input.startTime,
      initialLat: input.initialLat,
      initialLong: input.initialLong,
      status: 'active',
      createdAt: now,
      updatedAt: now,
      syncStatus: 1,
    );

    await _repository.saveSession(session);
  }

  @override
  Future<void> finishMirrorSession(String sessionId, DateTime endTime) async {
    await _repository.endSession(sessionId, endTime);
  }
}
