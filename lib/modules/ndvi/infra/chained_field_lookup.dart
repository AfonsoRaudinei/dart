import 'package:soloforte_app/core/contracts/i_field_lookup.dart';

/// Resolve talhões tentando [primary] (drawing/) e depois [fallback] (consultoria/).
///
/// NDVI é aberto com IDs de visita e de detalhe de talhão — fontes que podem
/// existir apenas em `fields`, não em `drawings`.
class ChainedFieldLookup implements IFieldLookup {
  const ChainedFieldLookup({
    required IFieldLookup primary,
    required IFieldLookup fallback,
  }) : _primary = primary,
       _fallback = fallback;

  final IFieldLookup _primary;
  final IFieldLookup _fallback;

  @override
  Future<FieldSummary?> findById(String fieldId) async {
    final primary = await _primary.findById(fieldId);
    if (primary != null) return primary;
    return _fallback.findById(fieldId);
  }

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async {
    final primary = await _primary.listByFarmId(farmId);
    if (primary.isNotEmpty) return primary;
    return _fallback.listByFarmId(farmId);
  }

  @override
  Future<List<FieldSummary>> listAll() async {
    final primary = await _primary.listAll();
    if (primary.isNotEmpty) return primary;
    return _fallback.listAll();
  }
}
