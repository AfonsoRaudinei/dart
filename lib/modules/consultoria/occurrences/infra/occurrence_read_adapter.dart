// lib/modules/consultoria/occurrences/infra/occurrence_read_adapter.dart
//
// Adapter autorizado: implementa IOccurrenceRead usando OccurrenceRepository.
// É a única ponte entre core/contracts/IOccurrenceRead e consultoria/.
//
// ADR-024 — DT-023-3
// NÃO importar este arquivo fora de consultoria/ ou da injeção de dependência.

import 'package:soloforte_app/core/contracts/i_occurrence_read.dart';
import '../data/occurrence_repository.dart';

/// Implementação concreta de IOccurrenceRead.
/// Vive em consultoria/occurrences/infra/ — dona dos dados de ocorrência.
class OccurrenceReadAdapter implements IOccurrenceRead {
  const OccurrenceReadAdapter(this._repository);

  final OccurrenceRepository _repository;

  @override
  Future<List<OccurrenceSummary>> getBySessionId(String sessionId) async {
    final occurrences = await _repository.getOccurrencesBySession(sessionId);
    return occurrences
        .map(
          (o) => OccurrenceSummary(
            id: o.id,
            type: o.category ?? o.type,
            description: o.description,
            lat: o.lat,
            lng: o.long,
            fotoPath: o.photoPath,
            registradaEm: o.createdAt,
          ),
        )
        .toList();
  }
}
