import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:soloforte_app/modules/consultoria/quick_photo/data/vegetal_filter.dart';

void main() {
  group('applyVegetalFilter', () {
    test('converte tons verdes em branco', () {
      final source = img.Image(width: 4, height: 1)
        ..setPixelRgb(0, 0, 0, 128, 0)
        ..setPixelRgb(1, 0, 30, 70, 35)
        ..setPixelRgb(2, 0, 170, 220, 175)
        ..setPixelRgb(3, 0, 90, 130, 30);

      final filtered = applyVegetalFilter(source);

      for (var x = 0; x < filtered.width; x++) {
        _expectPixel(filtered, x, 255);
      }
    });

    test('converte cores não verdes em preto', () {
      final source = img.Image(width: 6, height: 1)
        ..setPixelRgb(0, 0, 255, 0, 0)
        ..setPixelRgb(1, 0, 255, 255, 0)
        ..setPixelRgb(2, 0, 0, 0, 255)
        ..setPixelRgb(3, 0, 128, 128, 128)
        ..setPixelRgb(4, 0, 255, 255, 255)
        ..setPixelRgb(5, 0, 0, 0, 0);

      final filtered = applyVegetalFilter(source);

      for (var x = 0; x < filtered.width; x++) {
        _expectPixel(filtered, x, 0);
      }
    });
  });

  group('encodeVegetalFilteredJpeg', () {
    test('persiste pixels filtrados no JPEG final', () {
      final source = img.Image(width: 2, height: 1)
        ..setPixelRgb(0, 0, 0, 180, 0)
        ..setPixelRgb(1, 0, 255, 0, 0);
      final jpeg = Uint8List.fromList(img.encodeJpg(source, quality: 95));

      final encoded = encodeVegetalFilteredJpeg(jpeg);
      expect(encoded, isNotNull);

      final decoded = img.decodeImage(encoded!);
      expect(decoded, isNotNull);
      _expectPixel(decoded!, 0, 255);
      _expectPixel(decoded, 1, 0);
    });

    test('retorna null quando bytes são inválidos', () {
      expect(encodeVegetalFilteredJpeg(Uint8List.fromList([1, 2, 3])), isNull);
    });
  });
}

void _expectPixel(img.Image image, int x, int expected) {
  final pixel = image.getPixel(x, 0);
  expect(pixel.r.toInt(), expected);
  expect(pixel.g.toInt(), expected);
  expect(pixel.b.toInt(), expected);
}
