import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/modules/ndvi/infra/chained_field_lookup.dart';

class _StubLookup implements IFieldLookup {
  _StubLookup({
    this.findByIdResult,
    this.listByFarmIdResult = const [],
    this.listAllResult = const [],
  });

  FieldSummary? findByIdResult;
  List<FieldSummary> listByFarmIdResult;
  List<FieldSummary> listAllResult;
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
  test('findById retorna primary quando disponível', () async {
    const summary = FieldSummary(
      id: 'F1',
      name: 'Drawing',
      farmId: 'FAZ1',
      bbox: [-50, -20, -49, -19],
    );
    final primary = _StubLookup(findByIdResult: summary);
    final fallback = _StubLookup(
      findByIdResult: const FieldSummary(
        id: 'F1',
        name: 'Consultoria',
        farmId: 'FAZ1',
      ),
    );

    final lookup = ChainedFieldLookup(primary: primary, fallback: fallback);
    final result = await lookup.findById('F1');

    expect(result?.name, 'Drawing');
    expect(fallback.findByIdCalled, isFalse);
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

  test('listByFarmId usa fallback quando primary retorna vazio', () async {
    const summary = FieldSummary(id: 'F1', name: 'Consultoria', farmId: 'FAZ1');
    final primary = _StubLookup(listByFarmIdResult: const []);
    final fallback = _StubLookup(listByFarmIdResult: [summary]);

    final lookup = ChainedFieldLookup(primary: primary, fallback: fallback);
    final result = await lookup.listByFarmId('FAZ1');

    expect(result, hasLength(1));
    expect(result.single.name, 'Consultoria');
  });
}
