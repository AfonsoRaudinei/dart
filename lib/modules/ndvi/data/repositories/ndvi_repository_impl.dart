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
    // 1. Cache local primeiro (offline-first)
    final cached = await _local.getLatest(fieldId);
    if (cached != null) return cached.toEntity();

    // 2. Sem cache — buscar bbox/geometria via IFieldLookup
    final summary = await _fieldLookup.findById(fieldId);
    if (summary == null || (summary.bbox == null && summary.geometry == null)) {
      return null;
    }

    // 3. Buscar remoto
    final model = await _remote.fetchNdvi(
      fieldId: fieldId,
      bbox: summary.bbox,
      geometry: summary.geometry,
    );
    if (model == null) return null;

    // 4. Salvar no cache local
    final image = model.toEntity();
    await _local.save(image);
    return image;
  }

  @override
  Future<List<NdviImage>> getByFieldId(String fieldId) async {
    final list = await _local.getAll(fieldId);
    return list.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> save(NdviImage image) => _local.save(image);

  @override
  Future<void> deleteByFieldId(String fieldId) => _local.deleteAll(fieldId);
}
