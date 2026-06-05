import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup_provider.dart';
import '../../domain/occurrence.dart';
import '../../data/occurrence_repository.dart';
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
    String? clientId,
    String? photoPath,
    double? lat,
    double? long,
    String? category,
    String? status,
    // v14 — campos agronômicos
    String? cultivar,
    String? dataPlantio,
    String? estadioFenologico,
    String? tipoOcorrencia,
    bool amostraSolo = false,
    String? recomendacoes,
    String? metricasJson,
    String? nutrientesJson,
    String? categoriasJson,
    String? notasCategoriasJson,
    String? fotosCategoriasJson,
  }) async {
    final visitLookup = ref.read(visitSessionLookupProvider);
    final activeSession = await visitLookup.getActiveSession();
    final String? sessionId = activeSession?.isActive == true
        ? activeSession!.id
        : null;
    final resolvedClientId =
        clientId ??
        (activeSession?.isActive == true ? activeSession!.producerId : null);

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
      clientId: resolvedClientId,
      type: type,
      description: description,
      photoPath: photoPath,
      lat: lat,
      long: long,
      geometry: geometry,
      createdAt: DateTime.now(),
      category: category,
      status: status ?? 'draft',
      // v14 agronômico
      cultivar: cultivar,
      dataPlantio: dataPlantio,
      estadioFenologico: estadioFenologico,
      tipoOcorrencia: tipoOcorrencia,
      amostraSolo: amostraSolo,
      recomendacoes: recomendacoes,
      metricasJson: metricasJson,
      nutrientesJson: nutrientesJson,
      categoriasJson: categoriasJson,
      notasCategoriasJson: notasCategoriasJson,
      fotosCategoriasJson: fotosCategoriasJson,
    );

    await _repository.saveOccurrence(occurrence);

    ref.invalidate(occurrencesListProvider);
  }
}

final occurrenceControllerProvider = Provider<OccurrenceController>((ref) {
  return OccurrenceController(ref, ref.watch(occurrenceRepositoryProvider));
});
