/// Extrai nuvens de um tile de infravermelho em tons de cinza.
///
/// O composto `globalir` pinta a superfície quente por volta do cinza 60 e os
/// topos frios mais claros. A matriz (componentes 0–255) força o tile a branco
/// e usa o canal vermelho como alfa, então o chão some e a nuvem fica.
const int climaCloudSurfaceCutoff = 104;
const int climaCloudPeak = 184;

List<double> buildClimaCloudExtractMatrix({
  int surfaceCutoff = climaCloudSurfaceCutoff,
  int cloudPeak = climaCloudPeak,
}) {
  final span = (cloudPeak - surfaceCutoff).toDouble();
  final scale = 255 / span;
  final offset = -surfaceCutoff * scale;
  return <double>[
    0,
    0,
    0,
    0,
    255,
    0,
    0,
    0,
    0,
    255,
    0,
    0,
    0,
    0,
    255,
    scale,
    0,
    0,
    0,
    offset,
  ];
}

final List<double> climaCloudExtractMatrix = buildClimaCloudExtractMatrix();

/// Alfa resultante da matriz para uma luminância de infravermelho (0–255).
double climaCloudExtractAlpha(int luminance) {
  final alpha =
      climaCloudExtractMatrix[15] * luminance + climaCloudExtractMatrix[19];
  if (alpha < 0) return 0;
  if (alpha > 255) return 255;
  return alpha;
}
