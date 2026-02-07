import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/agenda_event.dart';
import '../../data/repositories/agenda_repository.dart';
import 'package:uuid/uuid.dart';

final agendaRepositoryProvider = Provider<AgendaRepository>((ref) {
  return AgendaRepository();
});

// List of planned events for today or specific date
final plannedEventsProvider = FutureProvider.family
    .autoDispose<List<AgendaEvent>, ({String producerId, String areaId})>((
      ref,
      filter,
    ) async {
      final repo = ref.watch(agendaRepositoryProvider);
      return repo.getPlannedEvents(
        producerId: filter.producerId,
        areaId: filter.areaId,
        date: DateTime.now(),
      );
    });

class AgendaController {
  final AgendaRepository _repository;

  AgendaController(this._repository);

  Future<void> createFollowUpEvent({
    required String producerId,
    required String areaId,
    required String activityType,
    required DateTime date,
    String? description,
  }) async {
    final event = AgendaEvent(
      id: const Uuid().v4(),
      producerId: producerId,
      areaId: areaId,
      activityType: activityType,
      scheduledDate: date,
      description: description,
      status: AgendaStatus.planned,
      createdAt: DateTime.now(),
    );
    await _repository.saveEvent(event);
  }
}

final agendaControllerProvider = Provider<AgendaController>((ref) {
  return AgendaController(ref.watch(agendaRepositoryProvider));
});
