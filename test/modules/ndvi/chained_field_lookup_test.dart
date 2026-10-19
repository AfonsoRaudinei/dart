import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/modules/ndvi/infra/chained_field_lookup.dart';

class _StubLookup implements IFieldLookup {
  _StubLookup({
    this.findByIdResult,
    this.listByFarmIdResult = const [],
  });

  FieldSummary? findByIdResult;
  List<FieldSummary> listByFarmIdResult;
  List<FieldSummary> listAllResult = const [];
  bool findByIdCalled = false;

  @override
  Future<FieldSummary?> findById(String fieldId) async {
    findByIdCalled = true;
    return findByIdResult;
  }

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async =>
      listByFarmIdResult;

  @override
  Future<List<FieldSummary>> listAll() async => listAllResult;
}

void main() {
  test('findById mescla e prioriza geometria consultoria', () async {
    const drawing = FieldSummary(
      id: 'F1',
      name: 'Drawing',
      farmId: 'FAZ1',
      bbox: [-49, -19, -48.9, -18.9],
    );
    const consultoria = FieldSummary(
      id: 'F1',
      name: 'Consultoria',
      farmId: 'FAZ1',
      bbox: [-50, -20, -49, -19],
      geometry:
          '{"type":"Polygon","coordinates":[[[-50,-20],[-49,-20],[-49,-19],[-50,-19],[-50,-20]]]}',
    );
    final primary = _StubLookup(findByIdResult: drawing);
    final fallback = _StubLookup(findByIdResult: consultoria);

    final lookup = ChainedFieldLookup(primary: primary, fallback: fallback);
    final result = await lookup.findById('F1');

    expect(result?.name, 'Drawing');
    expect(result?.bbox, consultoria.bbox);
    expect(result?.geometry, consultoria.geometry);
    expect(fallback.findByIdCalled, isTrue);
  });

  test('findById usa fallback quando primary retorna null', () async {
    const summary = FieldSummary(
      id: 'F1',
      name: 'Consultoria',
      farmId: 'FAZ1',
      geometry:
          '{"type":"Polygon","coordinates":[[[-50,-20],[-49,-20],[-49,-19],[-50,-19],[-50,-20]]]}',
    );
    final primary = _StubLookup(findByIdResult: null);
    final fallback = _StubLookup(findByIdResult: summary);

    final lookup = ChainedFieldLookup(primary: primary, fallback: fallback);
    final result = await lookup.findById('F1');

    expect(result?.name, 'Consultoria');
    expect(fallback.findByIdCalled, isTrue);
  });

  test('listByFarmId mescla ids como na ficha da fazenda', () async {
    const consultoria = FieldSummary(
      id: 'F1',
      name: 'Consultoria',
      farmId: 'FAZ1',
      bbox: [-50, -20, -49, -19],
    );
    const drawingOnly = FieldSummary(
      id: 'D1',
      name: 'Só mapa',
      farmId: 'FAZ1',
      bbox: [-51, -21, -50.5, -20.5],
    );
    final primary = _StubLookup(
      listByFarmIdResult: [
        FieldSummary(
          id: 'F1',
          name: 'Drawing',
          farmId: 'FAZ1',
          bbox: [-48, -18, -47.9, -17.9],
        ),
        drawingOnly,
      ],
    );
    final fallback = _StubLookup(listByFarmIdResult: [consultoria]);

    final lookup = ChainedFieldLookup(primary: primary, fallback: fallback);
    final result = await lookup.listByFarmId('FAZ1');

    expect(result, hasLength(2));
    final merged = result.firstWhere((s) => s.id == 'F1');
    expect(merged.bbox, consultoria.bbox);
    expect(result.any((s) => s.id == 'D1'), isTrue);
  });
}
