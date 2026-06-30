import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:soloforte_app/modules/ndvi/data/processing/ndvi_green_mask_processor.dart';

void main() {
  group('applyNdviGreenMask', () {
    test('verde claro, medio e escuro viram branco', () {
      final source = img.Image(width: 4, height: 1)
        ..setPixelRgb(0, 0, 130, 230, 120)
        ..setPixelRgb(1, 0, 0, 255, 0)
        ..setPixelRgb(2, 0, 20, 160, 20)
        ..setPixelRgb(3, 0, 0, 80, 0);

      final mask = applyNdviGreenMask(source);

      for (var x = 0; x < mask.width; x++) {
        _expectPixel(mask, x, 255);
      }
    });

    test('amarelo, vermelho e laranja viram preto', () {
      final source = img.Image(width: 3, height: 1)
        ..setPixelRgb(0, 0, 255, 255, 0)
        ..setPixelRgb(1, 0, 255, 0, 0)
        ..setPixelRgb(2, 0, 255, 128, 0);

      final mask = applyNdviGreenMask(source);

      _expectPixel(mask, 0, 0);
      _expectPixel(mask, 1, 0);
      _expectPixel(mask, 2, 0);
    });

    test('cinza, preto e branco viram preto', () {
      final source = img.Image(width: 3, height: 1)
        ..setPixelRgb(0, 0, 128, 128, 128)
        ..setPixelRgb(1, 0, 0, 0, 0)
        ..setPixelRgb(2, 0, 255, 255, 255);

      final mask = applyNdviGreenMask(source);

      _expectPixel(mask, 0, 0);
      _expectPixel(mask, 1, 0);
      _expectPixel(mask, 2, 0);
    });

    test('mantem a mascara estritamente binaria', () {
      final source = img.Image(width: 4, height: 1)
        ..setPixelRgb(0, 0, 0, 255, 0)
        ..setPixelRgb(1, 0, 255, 0, 0)
        ..setPixelRgb(2, 0, 255, 255, 0)
        ..setPixelRgb(3, 0, 20, 160, 20);

      final mask = applyNdviGreenMask(source);

      for (var x = 0; x < mask.width; x++) {
        final pixel = mask.getPixel(x, 0);
        final channels = [pixel.r.toInt(), pixel.g.toInt(), pixel.b.toInt()];

        expect(channels.toSet().length, 1);
        expect(channels.first == 0 || channels.first == 255, isTrue);
      }
    });

    test('classifica verde por hue, saturacao e brilho minimos', () {
      expect(isNdviGreenPixel(red: 190, green: 255, blue: 0), isTrue);
      expect(isNdviGreenPixel(red: 0, green: 80, blue: 0), isTrue);
      expect(isNdviGreenPixel(red: 0, green: 28, blue: 0), isFalse);
      expect(isNdviGreenPixel(red: 255, green: 255, blue: 0), isFalse);
      expect(isNdviGreenPixel(red: 255, green: 128, blue: 0), isFalse);
      expect(isNdviGreenPixel(red: 120, green: 85, blue: 45), isFalse);
      expect(isNdviGreenPixel(red: 80, green: 96, blue: 72), isFalse);
    });

    test('respeita alpha para nao contaminar fundo fora da camada NDVI', () {
      final source = img.Image(width: 3, height: 1, numChannels: 4)
        ..setPixelRgba(0, 0, 0, 255, 0, 0)
        ..setPixelRgba(1, 0, 0, 255, 0, 255)
        ..setPixelRgba(2, 0, 255, 0, 0, 255);

      final mask = applyNdviGreenMask(source);

      _expectPixel(mask, 0, 0, alpha: 0);
      _expectPixel(mask, 1, 255, alpha: 255);
      _expectPixel(mask, 2, 0, alpha: 255);
    });
  });
}

void _expectPixel(img.Image image, int x, int expected, {int alpha = 255}) {
  final pixel = image.getPixel(x, 0);
  expect(pixel.r.toInt(), expected);
  expect(pixel.g.toInt(), expected);
  expect(pixel.b.toInt(), expected);
  expect(pixel.a.toInt(), alpha);
}
