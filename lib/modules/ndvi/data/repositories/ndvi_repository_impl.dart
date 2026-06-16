import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/i_ndvi_repository.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';

class NdviRepositoryImpl implements INdviRepository {
  final NdviLocalDatasource _local;
  final NdviRemoteDatasource _remote;
  final IFieldLookup _fieldLookup;

  const NdviRepositoryImpl(this._local, this._remote, this._fieldLookup);

  @override
  Future<NdviImage?> getLatestByFieldId(String fieldId) async {
    final images = await getByFieldId(fieldId);
    return images.isEmpty ? null : images.first;
  }

  @override
  Future<List<NdviImage>> getByFieldId(String fieldId) async {
    final cached = await _local.getAll(fieldId);
    if (cached.isNotEmpty) {
      return cached.map((model) => model.toEntity()).toList();
    }

    return _fetchAndCacheFirstImage(fieldId);
  }

  Future<List<NdviImage>> _fetchAndCacheFirstImage(String fieldId) async {
    try {
      final summary = await _fieldLookup.findById(fieldId);
      if (summary == null ||
          (summary.bbox == null && summary.geometry == null)) {
        return const [];
      }

      final model = await _remote.fetchNdvi(
        fieldId: fieldId,
        bbox: summary.bbox,
        geometry: summary.geometry,
      );
      if (model == null) return const [];

      final image = model.toEntity();
      await _local.save(image);
      return [image];
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> save(NdviImage image) => _local.save(image);

  @override
  Future<void> deleteByFieldId(String fieldId) => _local.deleteAll(fieldId);
}
