import 'package:image/image.dart' as img;

img.Image applyVegetalFilter(img.Image src) {
  final output = img.Image(width: src.width, height: src.height);
  for (var y = 0; y < src.height; y++) {
    for (var x = 0; x < src.width; x++) {
      final pixel = src.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();
      final isGreen = isVegetalGreen(red: r, green: g, blue: b);
      final out = isGreen ? 255 : 0;
      output.setPixelRgb(x, y, out, out, out);
    }
  }
  return output;
}

bool isVegetalGreen({required int red, required int green, required int blue}) {
  final maxChannel = red > green
      ? (red > blue ? red : blue)
      : (green > blue ? green : blue);
  final minChannel = red < green
      ? (red < blue ? red : blue)
      : (green < blue ? green : blue);
  final chroma = maxChannel - minChannel;

  if (maxChannel < 16 || chroma < 8) return false;

  final saturation = chroma / maxChannel;
  if (saturation < 0.12) return false;

  final hue = switch (maxChannel) {
    final value when value == red => 60 * (((green - blue) / chroma) % 6),
    final value when value == green => 60 * (((blue - red) / chroma) + 2),
    _ => 60 * (((red - green) / chroma) + 4),
  };
  final normalizedHue = hue < 0 ? hue + 360 : hue;

  return normalizedHue >= 70 && normalizedHue <= 170;
}
