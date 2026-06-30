import 'package:soloforte_app/modules/ndvi/data/models/ndvi_image_model.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';

bool ndviImageHasRenderableData(NdviImage image) {
  final localPath = image.localPath;
  if (localPath != null && localPath.isNotEmpty) return true;
  final imageUrl = image.imageUrl;
  return imageUrl != null && imageUrl.isNotEmpty;
}

bool ndviModelHasRenderableData(NdviImageModel model) {
  final localPath = model.localPath;
  if (localPath != null && localPath.isNotEmpty) return true;
  final imageUrl = model.imageUrl;
  return imageUrl != null && imageUrl.isNotEmpty;
}

String ndviImageDateKey(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Normaliza valores legados (`planet`) para a fonte atual.
String normalizeNdviSource(String source) {
  return switch (source.toLowerCase()) {
    'planet' => 'planet_preview',
    _ => source,
  };
}

bool ndviIsColormapSource(String source) {
  return switch (normalizeNdviSource(source)) {
    'planet_preview' => false,
    _ => true,
  };
}

bool ndviSupportsGreenMask(String source) => ndviIsColormapSource(source);

String ndviSourceLabel(String source) {
  return switch (normalizeNdviSource(source)) {
    'sentinel' => 'Sentinel NDVI',
    'planet_preview' => 'Preview RGB (Planet)',
    _ => 'Auto',
  };
}

String? ndviPreviewDisclaimer(String source) {
  if (ndviIsColormapSource(source)) return null;
  return 'Imagem RGB de referencia — nao representa indice NDVI.';
}
