import 'package:image/image.dart' as img;

img.Image applyVegetalFilter(img.Image src) {
  final output = img.Image(width: src.width, height: src.height);
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final pixel = src.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final isGreen = g > 100 && g > r * 1.2 && g > b * 1.2;
      final out = isGreen ? 255 : 0;
      output.setPixelRgb(x, y, out, out, out);
    }
  }
  return output;
}
