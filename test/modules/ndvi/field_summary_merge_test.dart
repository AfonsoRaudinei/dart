import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/modules/ndvi/infra/field_summary_merge.dart';

void main() {
  test('merge prefere geometria consultoria quando drawing sem bbox', () {
    const drawing = FieldSummary(
      id: 'F1',
      name: 'No mapa',
      farmId: 'FAZ1',
    );
    const consultoria = FieldSummary(
      id: 'F1',
      name: 'Cadastro',
      farmId: 'FAZ1',
      bbox: [-50.1, -20.1, -50.0, -20.0],
      geometry:
          '{"type":"Polygon","coordinates":[[[-50.1,-20.1],[-50.0,-20.1],[-50.0,-20.0],[-50.1,-20.0],[-50.1,-20.1]]]}',
    );

    final merged = mergeFieldSummariesForNdvi(
      drawing: drawing,
      consultoria: consultoria,
    );

    expect(merged.bbox, consultoria.bbox);
    expect(merged.geometry, consultoria.geometry);
    expect(merged.name, 'No mapa');
  });

  test('merge prefere consultoria quando ambos tem origem NDVI', () {
    const drawing = FieldSummary(
      id: 'F1',
      name: 'Drawing',
      farmId: 'FAZ1',
      bbox: [-49.0, -19.0, -48.9, -18.9],
    );
    const consultoria = FieldSummary(
      id: 'F1',
      name: 'Consultoria',
      farmId: 'FAZ1',
      bbox: [-50.1, -20.1, -50.0, -20.0],
    );

    final merged = mergeFieldSummariesForNdvi(
      drawing: drawing,
      consultoria: consultoria,
    );

    expect(merged.bbox, consultoria.bbox);
  });
}
