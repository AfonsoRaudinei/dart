import 'package:soloforte_app/modules/ndvi/data/repositories/i_ndvi_repository.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/domain/ndvi_image_utils.dart';

class FakeNdviRepository implements INdviRepository {
  final Map<String, List<NdviImage>> _storage = {};

  @override
  Future<List<NdviImage>> getByFieldId(String fieldId) async {
    final list = _storage[fieldId] ?? [];
    list.sort((a, b) => b.imageDate.compareTo(a.imageDate));
    return list;
  }

  @override
  Future<NdviImage?> getLatestByFieldId(String fieldId) async {
    final list = await getByFieldId(fieldId);
    return list.isNotEmpty ? list.first : null;
  }

  @override
  Future<void> save(NdviImage image) async {
    final list = _storage[image.fieldId] ?? [];
    list.removeWhere((i) => i.id == image.id);
    list.add(image);
    _storage[image.fieldId] = list;
  }

  @override
  Future<void> deleteByFieldId(String fieldId) async {
    _storage.remove(fieldId);
  }

  @override
  Future<NdviImage?> ensureImageForDate(String fieldId, String imageDate) async {
    final list = _storage[fieldId] ?? [];
    for (final image in list) {
      if (ndviImageDateKey(image.imageDate) == imageDate &&
          ndviImageHasRenderableData(image)) {
        return image;
      }
    }
    return null;
  }
}
