import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/ndvi_cache_policy.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/i_ndvi_repository.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/domain/ndvi_image_utils.dart';

class NdviRepositoryImpl implements INdviRepository {
  final NdviLocalDatasource _local;
  final NdviRemoteDatasource _remote;
  final IFieldLookup _fieldLookup;
  final NdviCachePolicy _cachePolicy;

  NdviRepositoryImpl(
    this._local,
    this._remote,
    this._fieldLookup, {
    NdviCachePolicy? cachePolicy,
  }) : _cachePolicy = cachePolicy ?? _NoOpNdviCachePolicy();

  @override
  Future<NdviImage?> getLatestByFieldId(String fieldId) async {
    final images = await getByFieldId(fieldId);
    if (images.isEmpty) return null;

    for (final image in images) {
      if (ndviImageHasRenderableData(image)) return image;
    }
    return images.first;
  }

  @override
  Future<List<NdviImage>> getByFieldId(String fieldId) async {
    final summary = await _fieldLookup.findById(fieldId);
    final fingerprint = summary != null ? ndviOriginFingerprint(summary) : '';

    final cached = await _local.getAll(fieldId);
    if (cached.isNotEmpty &&
        !await _cachePolicy.shouldInvalidate(fieldId, fingerprint)) {
      AppLogger.debug(
        'NDVI cache hit fieldId=$fieldId count=${cached.length}',
        tag: 'NDVI.Repository',
      );
      return cached.map((model) => model.toEntity()).toList();
    }

    if (cached.isNotEmpty) {
      AppLogger.debug(
        'NDVI cache invalidado fieldId=$fieldId',
        tag: 'NDVI.Repository',
      );
      await _local.deleteAll(fieldId);
      await _cachePolicy.clear(fieldId);
    }

    return _refreshIndex(fieldId, summary);
  }

  @override
  Future<NdviImage?> ensureImageForDate(
    String fieldId,
    String imageDate,
  ) async {
    final cached = await _local.getByFieldIdAndDate(fieldId, imageDate);
    if (cached != null && ndviModelHasRenderableData(cached)) {
      return cached.toEntity();
    }

    final summary = await _fieldLookup.findById(fieldId);
    if (summary == null ||
        (summary.bbox == null && summary.geometry == null)) {
      AppLogger.warning(
        'NDVI indisponivel: talhao sem bbox/geometry fieldId=$fieldId',
        tag: 'NDVI.Repository',
      );
      return cached?.toEntity();
    }

    AppLogger.debug(
      'NDVI lazy fetch fieldId=$fieldId date=$imageDate',
      tag: 'NDVI.Repository',
    );

    final result = await _remote.fetchNdvi(
      fieldId: fieldId,
      bbox: summary.bbox,
      geometry: summary.geometry,
      date: imageDate,
    );
    if (result?.image == null) return cached?.toEntity();

    final image = result!.image!.toEntity();
    await _local.save(image);
    return image;
  }

  Future<List<NdviImage>> _refreshIndex(
    String fieldId,
    FieldSummary? summary,
  ) async {
    if (summary == null ||
        (summary.bbox == null && summary.geometry == null)) {
      AppLogger.warning(
        'NDVI indisponivel: talhao sem bbox/geometry fieldId=$fieldId',
        tag: 'NDVI.Repository',
      );
      return const [];
    }

    AppLogger.debug(
      'NDVI refresh index fieldId=$fieldId',
      tag: 'NDVI.Repository',
    );

    final result = await _remote.fetchNdvi(
      fieldId: fieldId,
      bbox: summary.bbox,
      geometry: summary.geometry,
    );
    if (result == null) return const [];

    final source = result.image?.source ?? 'auto';
    if (result.image != null) {
      await _local.save(result.image!.toEntity());
    }

    for (final date in result.availableDates) {
      if (result.image?.imageDate == date) continue;

      final existing = await _local.getByFieldIdAndDate(fieldId, date);
      if (existing != null && ndviModelHasRenderableData(existing)) continue;

      await _local.save(_dateStub(fieldId: fieldId, imageDate: date, source: source));
    }

    await _cachePolicy.markSynced(fieldId, ndviOriginFingerprint(summary));
    final all = await _local.getAll(fieldId);
    return all.map((model) => model.toEntity()).toList();
  }

  NdviImage _dateStub({
    required String fieldId,
    required String imageDate,
    required String source,
  }) {
    return NdviImage(
      id: '${fieldId}_$imageDate',
      fieldId: fieldId,
      imageDate: DateTime.parse(imageDate),
      ndviMin: 0,
      ndviMax: 0,
      ndviMean: 0,
      source: source,
      fetchedAt: DateTime.now(),
      syncStatus: 0,
    );
  }

  @override
  Future<void> save(NdviImage image) => _local.save(image);

  @override
  Future<void> deleteByFieldId(String fieldId) async {
    await _local.deleteAll(fieldId);
    await _cachePolicy.clear(fieldId);
  }
}

/// Fallback quando nenhuma política é injetada (ex.: testes legados).
class _NoOpNdviCachePolicy implements NdviCachePolicy {
  @override
  Future<void> clear(String fieldId) async {}

  @override
  Future<void> markSynced(String fieldId, String originFingerprint) async {}

  @override
  Future<bool> shouldInvalidate(String fieldId, String originFingerprint) async {
    return false;
  }
}
