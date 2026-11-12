import 'package:soloforte_app/core/services/sync_status_contract.dart';

import '../entities/event.dart';
import '../repositories/i_agenda_repository.dart';

/// Atualiza fazenda e talhão do evento ligado à sessão de campo.
class UpdateFieldVisitPlaceUseCase {
  UpdateFieldVisitPlaceUseCase(this._repository);

  final IAgendaRepository _repository;

  Future<Event?> execute({
    required String sessionId,
    String? farmId,
    String? areaId,
    bool clearArea = false,
  }) async {
    final event = await _repository.getEventBySessionId(sessionId);
    if (event == null) return null;

    final updated = event.copyWith(
      fazendaId: _nonEmpty(farmId),
      talhaoId: _nonEmpty(areaId),
      clearTalhaoId: clearArea,
      syncStatus: SyncStatusContract.pendingSync,
      updatedAt: DateTime.now(),
    );
    await _repository.updateEvent(updated);
    return updated;
  }
}

String? _nonEmpty(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
