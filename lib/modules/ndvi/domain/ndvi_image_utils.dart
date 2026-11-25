import 'package:soloforte_app/modules/ndvi/data/models/ndvi_image_model.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';

export 'package:soloforte_app/core/utils/ndvi_civil_date.dart';

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

/// Normaliza valores legados (`planet`) para a fonte atual.
String normalizeNdviSource(String source) {
  return switch (source.toLowerCase()) {
    'planet' => 'planet_preview',
    _ => source,
  };
}

bool ndviIsRefinedSource(String source) {
  return normalizeNdviSource(source) == 'sentinel_refined';
}

bool ndviIsColormapSource(String source) {
  return switch (normalizeNdviSource(source)) {
    'planet_preview' || 'unavailable' => false,
    _ => true,
  };
}

bool ndviSupportsGreenMask(String source) => ndviIsColormapSource(source);

String ndviSourceLabel(String source) {
  return switch (normalizeNdviSource(source)) {
    'sentinel' => 'Sentinel NDVI',
    'sentinel_refined' => 'Sentinel NDVI (Ouro)',
    'planet_preview' => 'Preview RGB (Planet)',
    'unavailable' => 'NDVI indisponivel',
    _ => 'Auto',
  };
}

bool ndviShowsTenMeterPixelLabel(String source) =>
    ndviIsRefinedSource(source);

String? ndviLowCoverHint(String source, double mean) {
  if (!ndviIsRefinedSource(source)) return null;
  if (mean < 0.2 || mean >= 0.4) return null;
  return 'Cobertura vegetal baixa (NDVI médio)';
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
    'requested_date_unavailable' =>
      'Nenhuma cena NDVI nesta data para o talhao.',
    _ => 'Sentinel indisponivel ($code).',
  };
}

String? ndviPreviewDisclaimer(
  String source, {
  String? sentinelDegradedReason,
}) {
  if (normalizeNdviSource(source) == 'unavailable') {
    return ndviDegradedReasonLabel(sentinelDegradedReason) ??
        'Mapa NDVI indisponivel para esta area.';
  }
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

String ndviSceneAgeLabel(DateTime imageDate, {DateTime? now}) {
  final clock = now ?? DateTime.now();
  final today = DateTime(clock.year, clock.month, clock.day);
  final scene = DateTime(imageDate.year, imageDate.month, imageDate.day);
  final days = today.difference(scene).inDays;
  if (days <= 7) return '';
  if (days < 30) return 'há ${days}d';
  final months = (days / 30).floor();
  if (months < 12) return 'há ${months}m';
  final years = (days / 365).floor();
  return 'há ${years}a';
}

String ndviDateChipLabel(
  DateTime date, {
  double? cloudCoverage,
  DateTime? referenceNow,
}) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final cloud = ndviCloudCoverageLabel(cloudCoverage);
  final age = ndviSceneAgeLabel(date, now: referenceNow);
  final core = cloud == null ? '$day/$month' : '$day/$month · ${cloudCoverage!.round()}%';
  if (age.isEmpty) return core;
  return '$core · $age';
}

/// Stats reais da edge; stubs e falha de amostragem ficam 0/0/0.
bool ndviImageHasMeasuredStats(NdviImage image) {
  if (!ndviImageHasRenderableData(image)) return false;
  return image.ndviMin != 0 ||
      image.ndviMax != 0 ||
      image.ndviMean != 0;
}
