import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../domain/occurrence.dart';
import '../../data/occurrence_repository.dart';
import '../../../../../modules/visitas/presentation/controllers/visit_controller.dart';
import 'package:uuid/uuid.dart';

final occurrenceRepositoryProvider = Provider<OccurrenceRepository>((ref) {
  return OccurrenceRepository();
});

final occurrencesListProvider = FutureProvider.autoDispose<List<Occurrence>>((
  ref,
) async {
  final repo = ref.watch(occurrenceRepositoryProvider);
  return repo.getAllOccurrences();
});

class OccurrenceController {
  final Ref ref;
  final OccurrenceRepository _repository;

  OccurrenceController(this.ref, this._repository);

  Future<void> createOccurrence({
    required String type,
    required String description,
    String? photoPath,
    double? lat,
    double? long,
    String? category,
    String? status,
  }) async {
    final visitState = ref.read(visitControllerProvider);
    final String? sessionId = (visitState.value?.status == 'active')
        ? visitState.value!.id
        : null;

    String? geometry;
    if (lat != null && long != null) {
      geometry = jsonEncode({
        'type': 'Point',
        'coordinates': [long, lat],
      });
    }

    final occurrence = Occurrence(
      id: const Uuid().v4(),
      visitSessionId: sessionId,
      type: type,
      description: description,
      photoPath: photoPath,
      lat: lat,
      long: long,
      geometry: geometry,
      createdAt: DateTime.now(),
      category: category,
      status: status ?? 'draft',
    );

    await _repository.saveOccurrence(occurrence);

    ref.invalidate(occurrencesListProvider);
  }
}

final occurrenceControllerProvider = Provider<OccurrenceController>((ref) {
  return OccurrenceController(ref, ref.watch(occurrenceRepositoryProvider));
});
