import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/fields/data/repositories/field_repository.dart';
import 'package:soloforte_app/modules/consultoria/fields/infra/field_lookup_geofence_adapter.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/models/ndvi_image_model.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/ndvi_repository_impl.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/infra/chained_field_lookup.dart';

class FakeFieldRepository implements FieldRepository {
  Talhao? nextReturn;

  @override
  Future<Talhao?> getFieldById(String fieldId) async => nextReturn;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalDataSource implements NdviLocalDatasource {
  NdviImageModel? lastSaved;
  NdviImageModel? nextReturn;
  List<NdviImageModel> nextList = const [];
  final Map<String, NdviImageModel> _byDate = {};

  @override
  Future<NdviImageModel?> getLatest(String fieldId) async => nextReturn;

  @override
  Future<NdviImageModel?> getByFieldIdAndDate(
    String fieldId,
    String imageDate,
  ) async {
    return _byDate['$fieldId|$imageDate'];
  }

  @override
  Future<List<NdviImageModel>> getAll(String fieldId) async {
    if (nextList.isNotEmpty) return nextList;
    return _byDate.values.where((m) => m.fieldId == fieldId).toList()
      ..sort((a, b) => b.imageDate.compareTo(a.imageDate));
  }

  @override
  Future<void> save(NdviImage image) async {
    final model = NdviImageModel.fromEntity(image);
    lastSaved = model;
    _byDate['${model.fieldId}|${model.imageDate}'] = model;
  }

  @override
  Future<void> deleteAll(String fieldId) async {
    _byDate.removeWhere((_, model) => model.fieldId == fieldId);
    nextList = const [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeRemoteDataSource implements NdviRemoteDatasource {
  NdviImageModel? nextReturn;
  NdviRemoteFetchResult? nextResult;
  bool called = false;
  bool throwOnFetch = false;
  List<double>? lastBbox;
  String? lastGeometry;
  String? lastDate;

  @override
  Future<NdviRemoteFetchResult?> fetchNdvi({
    required String fieldId,
    List<double>? bbox,
    String? geometry,
    String? date,
    String source = 'auto',
  }) async {
    called = true;
    lastBbox = bbox;
    lastGeometry = geometry;
    lastDate = date;
    if (throwOnFetch) throw Exception('remote unavailable');
    if (nextResult != null) return nextResult;
    if (nextReturn != null) {
      return NdviRemoteFetchResult(image: nextReturn);
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class EmptyDrawingLookup implements IFieldLookup {
  @override
  Future<FieldSummary?> findById(String fieldId) async => null;

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async => const [];

  @override
  Future<List<FieldSummary>> listAll() async => const [];
}

void main() {
  test(
    'FieldLookupGeofenceAdapter expõe bbox derivado da geometry',
    () async {
      final repo = FakeFieldRepository()
        ..nextReturn = Talhao(
          id: 'FIELD-CONSULT',
          name: 'Talhão consultoria',
          areaHa: 12.5,
          crop: '',
          harvest: '',
          geometry: {
            'type': 'Polygon',
            'coordinates': [
              [
                [-50.0, -20.0],
                [-49.0, -20.0],
                [-49.0, -19.0],
                [-50.0, -19.0],
                [-50.0, -20.0],
              ],
            ],
          },
        );
      final adapter = FieldLookupGeofenceAdapter(repo);

      final summary = await adapter.findById('FIELD-CONSULT');

      expect(summary, isNotNull);
      expect(summary!.bbox, [-50.0, -20.0, -49.0, -19.0]);
      expect(summary.geometry, isNotNull);
    },
  );

  test(
    'talhão só em consultoria via ChainedFieldLookup dispara fetch remoto',
    () async {
      const fieldId = 'FIELD-CONSULT';
      final repo = FakeFieldRepository()
        ..nextReturn = Talhao(
          id: fieldId,
          name: 'Talhão consultoria',
          areaHa: 12.5,
          crop: '',
          harvest: '',
          geometry: {
            'type': 'Polygon',
            'coordinates': [
              [
                [-50.0, -20.0],
                [-49.0, -20.0],
                [-49.0, -19.0],
                [-50.0, -19.0],
                [-50.0, -20.0],
              ],
            ],
          },
        );
      final lookup = ChainedFieldLookup(
        primary: EmptyDrawingLookup(),
        fallback: FieldLookupGeofenceAdapter(repo),
      );
      final local = FakeLocalDataSource();
      final remote = FakeRemoteDataSource()
        ..nextReturn = const NdviImageModel(
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
      final repository = NdviRepositoryImpl(local, remote, lookup);

      final result = await repository.getByFieldId(fieldId);

      expect(result, hasLength(1));
      expect(remote.called, isTrue);
      expect(remote.lastBbox, [-50.0, -20.0, -49.0, -19.0]);
      expect(remote.lastGeometry, isNotNull);
      expect(local.lastSaved?.id, 'IMG1');
    },
  );
}
