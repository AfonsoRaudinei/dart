import 'dart:io';

import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/ndvi_cache_policy.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/i_ndvi_repository.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/domain/ndvi_history.dart';
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
      if (ndviIsColormapSource(image.source) &&
          ndviImageHasRenderableData(image)) {
        return image;
      }
    }
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
      final kept = await _capHistory(
        fieldId,
        cached.map((model) => model.toEntity()).toList(),
      );
      return _preferSentinel(fieldId, summary, kept, force: false);
    }

    if (cached.isNotEmpty) {
      AppLogger.debug(
        'NDVI índice desatualizado fieldId=$fieldId',
        tag: 'NDVI.Repository',
      );
    }

    final refreshed = await _refreshIndex(fieldId, summary);
    if (refreshed.isEmpty) {
      return _capHistory(
        fieldId,
        cached.map((model) => model.toEntity()).toList(),
      );
    }
    return _preferSentinel(fieldId, summary, refreshed, force: true);
  }

  @override
  Future<NdviImage?> ensureImageForDate(
    String fieldId,
    String imageDate,
  ) async {
    final cached = await _local.getByFieldIdAndDate(fieldId, imageDate);
    if (cached != null &&
        ndviModelHasRenderableData(cached) &&
        ndviIsColormapSource(cached.source)) {
      return cached.toEntity();
    }

    final summary = await _fieldLookup.findById(fieldId);
    if (summary == null || (summary.bbox == null && summary.geometry == null)) {
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
      source: cached != null && !ndviIsColormapSource(cached.source)
          ? 'sentinel'
          : 'auto',
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
    if (summary == null || (summary.bbox == null && summary.geometry == null)) {
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

      await _local.save(
        _dateStub(fieldId: fieldId, imageDate: date, source: source),
      );
    }

    await _cachePolicy.markSynced(fieldId, ndviOriginFingerprint(summary));
    final all = await _local.getAll(fieldId);
    return _capHistory(fieldId, all.map((model) => model.toEntity()).toList());
  }

  Future<List<NdviImage>> _preferSentinel(
    String fieldId,
    FieldSummary? summary,
    List<NdviImage> images, {
    required bool force,
  }) async {
    if (images.isEmpty ||
        summary == null ||
        (summary.bbox == null && summary.geometry == null)) {
      return images;
    }
    final newest = images.first;
    if (ndviIsColormapSource(newest.source) &&
        ndviImageHasRenderableData(newest)) {
      return images;
    }
    if (!force &&
        DateTime.now().difference(newest.fetchedAt) <
            const Duration(hours: 24)) {
      return images;
    }

    try {
      final result = await _remote.fetchNdvi(
        fieldId: fieldId,
        bbox: summary.bbox,
        geometry: summary.geometry,
        date: ndviImageDateKey(newest.imageDate),
        source: 'sentinel',
      );
      if (result?.image != null) {
        await _local.save(result!.image!.toEntity());
      }
    } catch (error) {
      AppLogger.warning(
        'NDVI sentinel retry falhou fieldId=$fieldId',
        tag: 'NDVI.Repository',
        error: error,
      );
    }

    final all = await _local.getAll(fieldId);
    return _capHistory(fieldId, all.map((model) => model.toEntity()).toList());
  }

  Future<List<NdviImage>> _capHistory(
    String fieldId,
    List<NdviImage> images,
  ) async {
    final kept = ndviHistoryKept(images);
    final keptKeys = kept
        .map((image) => ndviImageDateKey(image.imageDate))
        .toSet();
    for (final image in images) {
      final key = ndviImageDateKey(image.imageDate);
      if (keptKeys.contains(key)) continue;
      await _local.deleteByFieldAndDate(fieldId, key);
      _deleteLocalFile(image.localPath);
    }
    return kept;
  }

  void _deleteLocalFile(String? path) {
    if (path == null || path.isEmpty) return;
    try {
      final file = File(path);
      if (file.existsSync()) file.deleteSync();
    } catch (_) {}
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
  Future<bool> shouldInvalidate(
    String fieldId,
    String originFingerprint,
  ) async {
    return false;
  }
}
