import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';

abstract class INdviRepository {
  Future<List<NdviImage>> getByFieldId(String fieldId);
  Future<NdviImage?> getLatestByFieldId(String fieldId);
  Future<NdviImage?> ensureImageForDate(String fieldId, String imageDate);
  Future<void> save(NdviImage image);
  Future<void> deleteByFieldId(String fieldId);
}
