import 'package:soloforte_app/core/contracts/i_active_visit_context_lookup.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/modules/consultoria/clients/data/clients_repository.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/fields/data/repositories/field_repository.dart';

/// Resolve dados de cadastro para pré-preencher ações abertas durante a visita.
class ActiveVisitContextLookupAdapter implements IActiveVisitContextLookup {
  const ActiveVisitContextLookupAdapter(
    this._visitLookup,
    this._clientsRepository,
    this._fieldRepository,
  );

  final IVisitSessionLookup _visitLookup;
  final ClientsRepository _clientsRepository;
  final FieldRepository _fieldRepository;

  @override
  Future<ActiveVisitContext?> getActiveContext() async {
    final session = await _visitLookup.getActiveSession();
    if (session?.isActive != true) return null;

    final activeSession = session!;
    final client = await _clientsRepository.getClientById(
      activeSession.producerId,
    );
    final farms = client?.farms ?? const <Farm>[];

    Farm? farm = _findFarm(farms, activeSession.farmId);
    final field = activeSession.areaId == null
        ? null
        : await _fieldRepository.getFieldById(activeSession.areaId!);

    // Compatibilidade com sessões anteriores à persistência de farm_id.
    if (farm == null && activeSession.areaId != null) {
      farm = await _findFarmByField(farms, activeSession.areaId!);
    }

    return ActiveVisitContext(
      sessionId: activeSession.id,
      clientId: activeSession.producerId,
      clientName: client?.name,
      farmId: farm?.id ?? activeSession.farmId,
      farmName: farm?.name,
      fieldId: activeSession.areaId,
      fieldName: field?.name,
      fieldAreaHa: field?.areaHa,
      city: _firstNonEmpty(farm?.city, client?.city),
      state: _firstNonEmpty(farm?.state, client?.state),
    );
  }

  Farm? _findFarm(List<Farm> farms, String? farmId) {
    if (farmId == null) return null;
    for (final farm in farms) {
      if (farm.id == farmId) return farm;
    }
    return null;
  }

  Future<Farm?> _findFarmByField(List<Farm> farms, String fieldId) async {
    for (final farm in farms) {
      final fields = await _fieldRepository.getFieldsByFarmId(farm.id);
      if (fields.any((field) => field.id == fieldId)) return farm;
    }
    return null;
  }

  String? _firstNonEmpty(String? preferred, String? fallback) {
    if (preferred != null && preferred.trim().isNotEmpty) return preferred;
    if (fallback != null && fallback.trim().isNotEmpty) return fallback;
    return null;
  }
}
