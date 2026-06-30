import 'package:image/image.dart' as img;

const double _minGreenHue = 70;
const double _maxGreenHue = 170;
const double _minGreenSaturation = 0.35;
const double _minGreenBrightness = 0.18;

/// Converts a colored NDVI image into a binary green mask.
///
/// Green pixels become white. Every other visible color becomes black.
img.Image applyNdviGreenMask(img.Image source) {
  final output = img.Image(
    width: source.width,
    height: source.height,
    numChannels: 4,
  );

  for (var y = 0; y < source.height; y++) {
    for (var x = 0; x < source.width; x++) {
      final pixel = source.getPixel(x, y);
      final alpha = pixel.a.toInt();
      if (alpha <= 0) {
        output.setPixelRgba(x, y, 0, 0, 0, 0);
        continue;
      }

      final isGreen = isNdviGreenPixel(
        red: pixel.r.toInt(),
        green: pixel.g.toInt(),
        blue: pixel.b.toInt(),
      );
      final value = isGreen ? 255 : 0;
      output.setPixelRgba(x, y, value, value, value, alpha);
    }
  }

  return output;
}

bool isNdviGreenPixel({
  required int red,
  required int green,
  required int blue,
}) {
  final maxChannel = red > green
      ? (red > blue ? red : blue)
      : (green > blue ? green : blue);
  final minChannel = red < green
      ? (red < blue ? red : blue)
      : (green < blue ? green : blue);
  final chroma = maxChannel - minChannel;

  if (maxChannel < 16 || chroma < 8) return false;

  final brightness = maxChannel / 255;
  if (brightness < _minGreenBrightness) return false;

  final saturation = chroma / maxChannel;
  if (saturation < _minGreenSaturation) return false;

  final hue = switch (maxChannel) {
    final value when value == red => 60 * (((green - blue) / chroma) % 6),
    final value when value == green => 60 * (((blue - red) / chroma) + 2),
    _ => 60 * (((red - green) / chroma) + 4),
  };
  final normalizedHue = hue < 0 ? hue + 360 : hue;

  return normalizedHue >= _minGreenHue && normalizedHue <= _maxGreenHue;
}
