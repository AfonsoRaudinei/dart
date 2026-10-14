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

String? ndviDegradedReasonLabel(String? code) {
  if (code == null || code.isEmpty) return null;
  return switch (code) {
    'cdse_oauth_failed' =>
      'OAuth Copernicus (CDSE) invalido ou expirado no servidor.',
    'commercial_oauth_failed' =>
      'OAuth Sentinel Hub comercial invalido no servidor.',
    'sentinel_credentials_missing' =>
      'Credenciais Sentinel nao configuradas no servidor.',
    'cdse_catalog_failed' || 'commercial_catalog_failed' =>
      'Catalogo Sentinel indisponivel para esta area.',
    'cdse_no_scenes' || 'commercial_no_scenes' =>
      'Nenhuma cena Sentinel sem nuvens excessivas no periodo.',
    'cdse_process_failed' || 'commercial_process_failed' =>
      'Processamento NDVI falhou nesta data.',
    _ => 'Sentinel indisponivel ($code).',
  };
}

String? ndviPreviewDisclaimer(
  String source, {
  String? sentinelDegradedReason,
}) {
  if (ndviIsColormapSource(source)) return null;
  final detail = ndviDegradedReasonLabel(sentinelDegradedReason);
  if (detail != null) {
    return 'Preview RGB (Planet). $detail';
  }
  return 'Preview RGB (Planet). Mapa NDVI Sentinel indisponivel: '
      'verifique credenciais Sentinel Hub no servidor ou aguarde passagem sem nuvens.';
}

String? ndviCloudCoverageLabel(double? cloudCoverage) {
  if (cloudCoverage == null) return null;
  if (cloudCoverage < 0) return null;
  return 'Nuvem ${cloudCoverage.round()}%';
}

String ndviDateChipLabel(DateTime date, {double? cloudCoverage}) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final cloud = ndviCloudCoverageLabel(cloudCoverage);
  if (cloud == null) return '$day/$month';
  return '$day/$month · ${cloudCoverage!.round()}%';
}

/// Stats reais da edge; stubs e falha de amostragem ficam 0/0/0.
bool ndviImageHasMeasuredStats(NdviImage image) {
  if (!ndviImageHasRenderableData(image)) return false;
  return image.ndviMin != 0 ||
      image.ndviMax != 0 ||
      image.ndviMean != 0;
}
