import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/models/ndvi_image_model.dart';
import 'package:soloforte_app/modules/ndvi/data/ndvi_cache_policy.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/ndvi_repository_impl.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/domain/ndvi_image_utils.dart';

class FakeLocalDataSource implements NdviLocalDatasource {
  final Map<String, NdviImageModel> _saved = {};
  List<NdviImageModel> seeded = const [];

  @override
  Future<NdviImageModel?> getLatest(String fieldId) async {
    final all = await getAll(fieldId);
    return all.isEmpty ? null : all.first;
  }

  @override
  Future<NdviImageModel?> getByFieldIdAndDate(
    String fieldId,
    String imageDate,
  ) async {
    return _saved['$fieldId|$imageDate'];
  }

  @override
  Future<List<NdviImageModel>> getAll(String fieldId) async {
    if (seeded.isNotEmpty) return seeded;
    return _saved.values.where((model) => model.fieldId == fieldId).toList()
      ..sort((a, b) => b.imageDate.compareTo(a.imageDate));
  }

  @override
  Future<void> save(NdviImage image) async {
    final model = NdviImageModel.fromEntity(image);
    _saved['${model.fieldId}|${model.imageDate}'] = model;
  }

  @override
  Future<void> deleteAll(String fieldId) async {
    seeded = const [];
    _saved.removeWhere((_, model) => model.fieldId == fieldId);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRemoteDataSource implements NdviRemoteDatasource {
  NdviRemoteFetchResult? nextResult;
  int fetchCount = 0;
  String? lastDate;

  @override
  Future<NdviRemoteFetchResult?> fetchNdvi({
    required String fieldId,
    List<double>? bbox,
    String? geometry,
    String? date,
    String source = 'auto',
  }) async {
    fetchCount++;
    lastDate = date;
    return nextResult;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeFieldLookup implements IFieldLookup {
  FieldSummary? summary;

  @override
  Future<FieldSummary?> findById(String fieldId) async => summary;

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async => const [];

  @override
  Future<List<FieldSummary>> listAll() async => const [];
}

const _summary = FieldSummary(
  id: 'F1',
  name: 'Talhão',
  farmId: 'FAZ1',
  bbox: [-50.0, -20.0, -49.0, -19.0],
);

void main() {
  late FakeLocalDataSource local;
  late FakeRemoteDataSource remote;
  late FakeFieldLookup lookup;
  late InMemoryNdviCachePolicy cachePolicy;
  late NdviRepositoryImpl repository;

  setUp(() {
    local = FakeLocalDataSource();
    remote = FakeRemoteDataSource();
    lookup = FakeFieldLookup()..summary = _summary;
    cachePolicy = InMemoryNdviCachePolicy();
    repository = NdviRepositoryImpl(
      local,
      remote,
      lookup,
      cachePolicy: cachePolicy,
    );
  });

  test('refresh index salva imagem e stubs para available_dates', () async {
    remote.nextResult = NdviRemoteFetchResult(
      image: const NdviImageModel(
        id: 'IMG-2026-03-01',
        fieldId: 'F1',
        imageDate: '2026-03-01',
        ndviMin: 0.2,
        ndviMax: 0.8,
        ndviMean: 0.5,
        source: 'sentinel',
        fetchedAt: '2026-03-01T10:00:00',
        syncStatus: 0,
        localPath: '/tmp/ndvi.png',
      ),
      availableDates: const ['2026-03-01', '2026-02-15', '2026-01-20'],
    );

    final result = await repository.getByFieldId('F1');

    expect(result, hasLength(3));
    expect(result.first.imageDate, DateTime(2026, 3, 1));
    expect(ndviImageHasRenderableData(result.first), isTrue);
    expect(
      result.where((image) => !ndviImageHasRenderableData(image)),
      hasLength(2),
    );
  });

  test('cache TTL expirado dispara novo fetch remoto', () async {
    cachePolicy.markSynced('F1', ndviOriginFingerprint(_summary));
    cachePolicy.syncedAt['F1'] = DateTime(2026, 1, 1);
    cachePolicy.clock = () => DateTime(2026, 1, 3);

    local.seeded = const [
      NdviImageModel(
        id: 'OLD',
        fieldId: 'F1',
        imageDate: '2026-01-01',
        ndviMin: 0.1,
        ndviMax: 0.2,
        ndviMean: 0.15,
        source: 'sentinel',
        fetchedAt: '2026-01-01T00:00:00',
        syncStatus: 0,
      ),
    ];

    remote.nextResult = NdviRemoteFetchResult(
      image: const NdviImageModel(
        id: 'NEW',
        fieldId: 'F1',
        imageDate: '2026-03-01',
        ndviMin: 0.3,
        ndviMax: 0.9,
        ndviMean: 0.6,
        source: 'sentinel',
        fetchedAt: '2026-03-01T10:00:00',
        syncStatus: 0,
        localPath: '/tmp/new.png',
      ),
      availableDates: const ['2026-03-01'],
    );

    final result = await repository.getByFieldId('F1');

    expect(remote.fetchCount, 1);
    expect(result.single.id, 'NEW');
  });

  test('ensureImageForDate busca remoto com date quando stub não tem imagem', () async {
    await local.save(
      NdviImage(
        id: 'F1_2026-02-15',
        fieldId: 'F1',
        imageDate: DateTime(2026, 2, 15),
        ndviMin: 0,
        ndviMax: 0,
        ndviMean: 0,
        source: 'sentinel',
        fetchedAt: DateTime(2026, 2, 15),
        syncStatus: 0,
      ),
    );

    remote.nextResult = NdviRemoteFetchResult(
      image: const NdviImageModel(
        id: 'IMG-2026-02-15',
        fieldId: 'F1',
        imageDate: '2026-02-15',
        ndviMin: 0.25,
        ndviMax: 0.75,
        ndviMean: 0.5,
        source: 'sentinel',
        fetchedAt: '2026-02-15T10:00:00',
        syncStatus: 0,
        localPath: '/tmp/fev.png',
      ),
    );

    final image = await repository.ensureImageForDate('F1', '2026-02-15');

    expect(remote.lastDate, '2026-02-15');
    expect(image, isNotNull);
    expect(ndviImageHasRenderableData(image!), isTrue);
    expect(image.ndviMean, 0.5);
  });

  test('mudança de geometry invalida cache e refaz fetch', () async {
    cachePolicy.markSynced('F1', ndviOriginFingerprint(_summary));
    local.seeded = const [
      NdviImageModel(
        id: 'OLD',
        fieldId: 'F1',
        imageDate: '2026-01-01',
        ndviMin: 0.1,
        ndviMax: 0.2,
        ndviMean: 0.15,
        source: 'sentinel',
        fetchedAt: '2026-01-01T00:00:00',
        syncStatus: 0,
      ),
    ];

    lookup.summary = const FieldSummary(
      id: 'F1',
      name: 'Talhão',
      farmId: 'FAZ1',
      bbox: [-51.0, -21.0, -48.0, -18.0],
    );

    remote.nextResult = NdviRemoteFetchResult(
      image: const NdviImageModel(
        id: 'NEW',
        fieldId: 'F1',
        imageDate: '2026-03-01',
        ndviMin: 0.3,
        ndviMax: 0.9,
        ndviMean: 0.6,
        source: 'sentinel',
        fetchedAt: '2026-03-01T10:00:00',
        syncStatus: 0,
        localPath: '/tmp/new.png',
      ),
      availableDates: const ['2026-03-01'],
    );

    final result = await repository.getByFieldId('F1');

    expect(remote.fetchCount, 1);
    expect(result.single.id, 'NEW');
  });
}
