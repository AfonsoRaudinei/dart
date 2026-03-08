import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import '../data/repositories/visit_repository.dart';

/// Implementação concreta de IVisitSessionLookup.
/// Vive em visitas/infra/ — dono dos dados de sessão de visita.
class VisitSessionLookupAdapter implements IVisitSessionLookup {
  final VisitRepository _repository;

  VisitSessionLookupAdapter(this._repository);

  @override
  Future<VisitSessionSummary?> getActiveSession() async {
    final session = await _repository.getActiveSession();
    if (session == null) return null;

    return VisitSessionSummary(id: session.id, status: session.status);
  }
}
