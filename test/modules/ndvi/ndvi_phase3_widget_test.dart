import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/fields/data/repositories/field_repository.dart';
import 'package:soloforte_app/modules/consultoria/fields/infra/field_lookup_geofence_adapter.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/models/ndvi_image_model.dart';
import 'package:soloforte_app/modules/ndvi/data/ndvi_cache_policy.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/i_ndvi_repository.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/ndvi_repository_impl.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/infra/chained_field_lookup.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_providers.dart';
import 'package:soloforte_app/modules/ndvi/presentation/widgets/ndvi_talhao_sheet.dart';

class _FakeFieldRepository extends FieldRepository {
  _FakeFieldRepository(this.talhao);

  final Talhao talhao;

  @override
  Future<Talhao?> getFieldById(String fieldId) async => talhao;
}

class _EmptyDrawingLookup implements IFieldLookup {
  @override
  Future<FieldSummary?> findById(String fieldId) async => null;

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async => const [];

  @override
  Future<List<FieldSummary>> listAll() async => const [];
}

class _RecordingRepository implements INdviRepository {
  _RecordingRepository(this.images);

  final List<NdviImage> images;
  String? lastEnsureDate;

  @override
  Future<void> deleteByFieldId(String fieldId) async {}

  @override
  Future<NdviImage?> ensureImageForDate(
    String fieldId,
    String imageDate,
  ) async {
    lastEnsureDate = imageDate;
    return images.firstWhere(
      (image) =>
          '${image.imageDate.year.toString().padLeft(4, '0')}-'
              '${image.imageDate.month.toString().padLeft(2, '0')}-'
              '${image.imageDate.day.toString().padLeft(2, '0')}' ==
          imageDate,
      orElse: () => images.first,
    );
  }

  @override
  Future<List<NdviImage>> getByFieldId(String fieldId) async => images;

  @override
  Future<NdviImage?> getLatestByFieldId(String fieldId) async =>
      images.isEmpty ? null : images.first;

  @override
  Future<void> save(NdviImage image) async {}
}

void main() {
  const fieldId = 'FIELD-CONSULT';
  const fieldName = 'Talhao consultoria';

  test(
    'ChainedFieldLookup + repositorio carregam NDVI para talhao consultoria',
    () async {
      final repo = _FakeFieldRepository(
        Talhao(
          id: fieldId,
          name: fieldName,
          areaHa: 10,
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
        ),
      );
      final lookup = ChainedFieldLookup(
        primary: _EmptyDrawingLookup(),
        fallback: FieldLookupGeofenceAdapter(repo),
      );
      final local = _InMemoryLocal();
      final remote = _RecordingRemote();
      final cache = InMemoryNdviCachePolicy();
      final repository = NdviRepositoryImpl(
        local,
        remote,
        lookup,
        cachePolicy: cache,
      );

      final images = await repository.getByFieldId(fieldId);

      expect(remote.called, isTrue);
      expect(images, hasLength(2));
      expect(images.first.ndviMean, 0.62);
      expect(images.first.source, 'sentinel');
    },
  );

  testWidgets('sheet exibe stats, multi-date e preview Planet sem mascara', (
    tester,
  ) async {
    final images = [
      NdviImage(
        id: '1',
        fieldId: fieldId,
        imageDate: DateTime(2026, 3, 1),
        ndviMin: 0.2,
        ndviMax: 0.8,
        ndviMean: 0.55,
        source: 'sentinel',
        fetchedAt: DateTime.now(),
        syncStatus: 0,
        localPath: '/tmp/a.png',
      ),
      NdviImage(
        id: '2',
        fieldId: fieldId,
        imageDate: DateTime(2026, 2, 1),
        ndviMin: 0,
        ndviMax: 0,
        ndviMean: 0,
        source: 'planet_preview',
        fetchedAt: DateTime.now(),
        syncStatus: 0,
        imageUrl: 'https://example.com/preview.png',
      ),
    ];
    final recordingRepo = _RecordingRepository(images);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ndviRepositoryProvider.overrideWithValue(recordingRepo),
          ndviImagesProvider(fieldId).overrideWith((ref) => images),
          ndviEnsureCurrentDateProvider(fieldId).overrideWith((ref) async {}),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: NdviTalhaoSheet(fieldId: fieldId, fieldName: fieldName),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('NDVI médio: 0.55'), findsOneWidget);
    expect(find.text('1 de 2 imagens'), findsOneWidget);
    expect(find.text('Sentinel NDVI'), findsOneWidget);
    expect(find.text('Máscara verde'), findsOneWidget);

    await tester.tap(find.text('01/02'));
    await tester.pump();

    expect(find.text('Preview RGB (Planet)'), findsOneWidget);
    expect(
      find.text('Imagem RGB de referencia — nao representa indice NDVI.'),
      findsOneWidget,
    );
    expect(find.text('Máscara verde'), findsNothing);
  });
}

class _InMemoryLocal implements NdviLocalDatasource {
  final Map<String, NdviImageModel> _saved = {};

  @override
  Future<void> deleteAll(String fieldId) async {
    _saved.removeWhere((_, model) => model.fieldId == fieldId);
  }

  @override
  Future<List<NdviImageModel>> getAll(String fieldId) async {
    return _saved.values.where((m) => m.fieldId == fieldId).toList()
      ..sort((a, b) => b.imageDate.compareTo(a.imageDate));
  }

  @override
  Future<NdviImageModel?> getByFieldIdAndDate(
    String fieldId,
    String imageDate,
  ) async {
    return _saved['$fieldId|$imageDate'];
  }

  @override
  Future<NdviImageModel?> getLatest(String fieldId) async {
    final all = await getAll(fieldId);
    return all.isEmpty ? null : all.first;
  }

  @override
  Future<void> save(NdviImage image) async {
    final model = NdviImageModel.fromEntity(image);
    _saved['${model.fieldId}|${model.imageDate}'] = model;
  }
}

class _RecordingRemote implements NdviRemoteDatasource {
  bool called = false;

  @override
  Future<NdviRemoteFetchResult?> fetchNdvi({
    required String fieldId,
    List<double>? bbox,
    String? geometry,
    String? date,
    String source = 'auto',
  }) async {
    called = true;
    return NdviRemoteFetchResult(
      image: NdviImageModel(
        id: 'IMG-2026-03-01',
        fieldId: fieldId,
        imageDate: '2026-03-01',
        ndviMin: 0.2,
        ndviMax: 0.85,
        ndviMean: 0.62,
        source: 'sentinel',
        fetchedAt: DateTime.now().toIso8601String(),
        syncStatus: 0,
        localPath: '/tmp/ndvi.png',
      ),
      availableDates: const ['2026-03-01', '2026-02-01'],
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
