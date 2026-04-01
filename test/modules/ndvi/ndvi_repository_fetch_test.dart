import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/models/ndvi_image_model.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/ndvi_repository_impl.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';

class FakeLocalDataSource implements NdviLocalDatasource {
  NdviImageModel? lastSaved;
  NdviImageModel? nextReturn;

  @override
  Future<NdviImageModel?> getLatest(String fieldId) async => nextReturn;

  @override
  Future<List<NdviImageModel>> getAll(String fieldId) async => [];

  @override
  Future<void> save(NdviImage image) async {
    lastSaved = NdviImageModel.fromEntity(image);
  }

  @override
  Future<void> deleteAll(String fieldId) async {}
  
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRemoteDataSource implements NdviRemoteDatasource {
  NdviImageModel? nextReturn;
  bool called = false;

  @override
  Future<NdviImageModel?> fetchNdvi({
    required String fieldId,
    required List<double> bbox,
    String? date,
    String source = 'auto',
  }) async {
    called = true;
    return nextReturn;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFieldLookup implements IFieldLookup {
  FieldSummary? nextReturn;

  @override
  Future<FieldSummary?> findById(String fieldId) async => nextReturn;

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async => [];

  @override
  Future<List<FieldSummary>> listAll() async => [];
}

void main() {
  late NdviRepositoryImpl repository;
  late FakeLocalDataSource local;
  late FakeRemoteDataSource remote;
  late FakeFieldLookup lookup;

  setUp(() {
    local = FakeLocalDataSource();
    remote = FakeRemoteDataSource();
    lookup = FakeFieldLookup();
    repository = NdviRepositoryImpl(local, remote, lookup);
  });

  test('Cenário 1: cache vazio + bbox disponível → chama remote e salva', () async {
    const fieldId = 'F1';
    local.nextReturn = null;
    lookup.nextReturn = const FieldSummary(
      id: fieldId,
      name: 'Teste',
      farmId: 'FAZ1',
      bbox: [-50.0, -20.0, -49.0, -19.0],
    );
    remote.nextReturn = const NdviImageModel(
      id: 'IMG1',
      fieldId: fieldId,
      imageDate: '2026-01-01',
      ndviMin: 0.1,
      ndviMax: 0.8,
      ndviMean: 0.5,
      source: 'sentinel',
      fetchedAt: '2026-01-01',
      syncStatus: 0,
    );

    final result = await repository.getLatestByFieldId(fieldId);

    expect(result, isNotNull);
    expect(remote.called, isTrue);
    expect(local.lastSaved?.id, 'IMG1');
  });

  test('Cenário 2: cache vazio + bbox null → retorna null, não chama remote', () async {
    const fieldId = 'F1';
    local.nextReturn = null;
    lookup.nextReturn = const FieldSummary(
      id: fieldId,
      name: 'Teste',
      farmId: 'FAZ1',
      bbox: null,
    );

    final result = await repository.getLatestByFieldId(fieldId);

    expect(result, isNull);
    expect(remote.called, isFalse);
  });

  test('Cenário 4: cache presente → retorna cache, NÃO chama remote', () async {
    const fieldId = 'F1';
    local.nextReturn = const NdviImageModel(
      id: 'IMG_CACHE',
      fieldId: fieldId,
      imageDate: '2026-01-01',
      ndviMin: 0.1,
      ndviMax: 0.8,
      ndviMean: 0.5,
      source: 'sentinel',
      fetchedAt: '2026-01-01',
      syncStatus: 0,
    );

    final result = await repository.getLatestByFieldId(fieldId);

    expect(result?.id, 'IMG_CACHE');
    expect(remote.called, isFalse);
  });
}
