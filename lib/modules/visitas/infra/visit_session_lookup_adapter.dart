// lib/modules/visitas/infra/visit_session_lookup_adapter.dart
//
// Adapter autorizado: implementa IVisitSessionLookup usando repositório
// interno de visitas/. É a única ponte entre core/contracts/ e visitas/.
//
// ADR-020 (origem) + ADR-023 (expansão — DT-023-1, DT-023-2)
// NÃO importar este arquivo fora de visitas/ ou da injeção de dependência.

import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import '../data/repositories/visit_repository.dart';
import '../domain/models/visit_session.dart';

/// Implementação concreta de IVisitSessionLookup.
/// Vive em visitas/infra/ — dono dos dados de sessão de visita.
class VisitSessionLookupAdapter implements IVisitSessionLookup {
  const VisitSessionLookupAdapter(this._repository);

  final VisitRepository _repository;

  @override
  Future<VisitSessionSummary?> getActiveSession() async {
    final session = await _repository.getActiveSession();
    if (session == null) return null;
    return _toSummary(session);
  }

  @override
  Future<VisitSessionSummary?> findById(String sessionId) async {
    final session = await _repository.getById(sessionId);
    if (session == null) return null;
    return _toSummary(session);
  }

  VisitSessionSummary _toSummary(VisitSession session) {
    return VisitSessionSummary(
      id: session.id,
      producerId: session.producerId,
      status: session.status,
      startTime: session.startTime,
      areaId: session.areaId,
      activityType: session.activityType,
      endTime: session.endTime,
    );
  }
}
