import 'dart:io';
import 'dart:math' as math;

import 'package:image/image.dart' as img;

/// Estatísticas NDVI estimadas a partir do PNG colormap (evalscript RdYlGn).
class NdviColormapStats {
  const NdviColormapStats({
    required this.ndviMin,
    required this.ndviMax,
    required this.ndviMean,
  });

  final double ndviMin;
  final double ndviMax;
  final double ndviMean;
}

/// Centros aproximados das faixas do evalscript Sentinel Hub (0–255).
const _colormapBuckets = <({int r, int g, int b, double ndvi})>[
  (r: 128, g: 0, b: 0, ndvi: -0.1),
  (r: 255, g: 77, b: 0, ndvi: 0.1),
  (r: 255, g: 204, b: 0, ndvi: 0.3),
  (r: 153, g: 230, b: 51, ndvi: 0.5),
  (r: 26, g: 153, b: 26, ndvi: 0.75),
];

double? estimateNdviFromColormapRgb(int red, int green, int blue) {
  var best = double.infinity;
  double? ndvi;
  for (final bucket in _colormapBuckets) {
    final dr = red - bucket.r;
    final dg = green - bucket.g;
    final db = blue - bucket.b;
    final dist = (dr * dr + dg * dg + db * db).toDouble();
    if (dist < best) {
      best = dist;
      ndvi = bucket.ndvi;
    }
  }
  // Ignora pixels de máscara cinza escuro (sem dado).
  if (best > 120 * 120) return null;
  return ndvi;
}

NdviColormapStats? computeNdviStatsFromColormapPngFile(File file) {
  if (!file.existsSync()) return null;
  img.Image? decoded;
  try {
    decoded = img.decodePng(file.readAsBytesSync());
  } catch (_) {
    return null;
  }
  if (decoded == null) return null;

  final values = <double>[];
  for (var y = 0; y < decoded.height; y++) {
    for (var x = 0; x < decoded.width; x++) {
      final pixel = decoded.getPixel(x, y);
      if (pixel.a < 128) continue;
      final estimate = estimateNdviFromColormapRgb(
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
      );
      if (estimate != null) values.add(estimate);
    }
  }
  if (values.isEmpty) return null;

  final sum = values.fold<double>(0, (a, b) => a + b);
  return NdviColormapStats(
    ndviMin: values.reduce(math.min),
    ndviMax: values.reduce(math.max),
    ndviMean: sum / values.length,
  );
}
