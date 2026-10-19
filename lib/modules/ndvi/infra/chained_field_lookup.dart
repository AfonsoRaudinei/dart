import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/modules/ndvi/infra/field_summary_merge.dart';

/// Resolve talhões tentando [primary] (drawing/) e depois [fallback] (consultoria/).
///
/// NDVI é aberto com IDs de visita e de detalhe de talhão — fontes que podem
/// existir apenas em `fields`, não em `drawings`.
///
/// Quando o mesmo id existe nos dois lados, a geometria do cadastro consultoria
/// prevalece (mesma ordem da ficha Cliente → Fazenda).
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
    final drawing = await _primary.findById(fieldId);
    final consultoria = await _fallback.findById(fieldId);
    if (drawing == null) return consultoria;
    if (consultoria == null) return drawing;
    return mergeFieldSummariesForNdvi(
      drawing: drawing,
      consultoria: consultoria,
    );
  }

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async {
    final drawingFields = await _primary.listByFarmId(farmId);
    final consultoriaFields = await _fallback.listByFarmId(farmId);
    if (drawingFields.isEmpty) return consultoriaFields;
    if (consultoriaFields.isEmpty) return drawingFields;
    return mergeFieldSummariesByFarmId(
      drawingFields: drawingFields,
      consultoriaFields: consultoriaFields,
    );
  }

  @override
  Future<List<FieldSummary>> listAll() async {
    final drawingFields = await _primary.listAll();
    final consultoriaFields = await _fallback.listAll();
    if (drawingFields.isEmpty) return consultoriaFields;
    if (consultoriaFields.isEmpty) return drawingFields;
    return mergeFieldSummariesByFarmId(
      drawingFields: drawingFields,
      consultoriaFields: consultoriaFields,
    );
  }
}
