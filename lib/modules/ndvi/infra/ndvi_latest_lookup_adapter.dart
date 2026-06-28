import '../../../core/contracts/i_ndvi_latest_lookup.dart';
import '../../../core/contracts/ndvi_latest_summary.dart';
import '../data/repositories/i_ndvi_repository.dart';
import '../domain/ndvi_image_utils.dart';

/// Lookup neutro da última imagem NDVI. ADR-045.
class NdviLatestLookupAdapter implements INdviLatestLookup {
  NdviLatestLookupAdapter(this._repository);

  final INdviRepository _repository;

  @override
  Future<NdviLatestSummary?> getLatest(String fieldId) async {
    final image = await _repository.getLatestByFieldId(fieldId);
    if (image == null) return null;

    return NdviLatestSummary(
      imageDate: image.imageDate,
      ndviMean: image.ndviMean,
      ndviMin: image.ndviMin,
      ndviMax: image.ndviMax,
      sourceLabel: ndviSourceLabel(image.source),
    );
  }
}
