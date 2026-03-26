import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_remote_datasource.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/i_ndvi_repository.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';

class NdviRepositoryImpl implements INdviRepository {
  final NdviLocalDatasource _local;
  // ignore: unused_field
  final NdviRemoteDatasource _remote;

  const NdviRepositoryImpl(this._local, this._remote);

  @override
  Future<NdviImage?> getLatestByFieldId(String fieldId) async {
    final cached = await _local.getLatest(fieldId);
    if (cached != null) return cached.toEntity();
    return null;
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
