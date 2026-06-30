import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/ndvi/domain/ndvi_image_utils.dart';

void main() {
  test('normalizeNdviSource converte planet legado', () {
    expect(normalizeNdviSource('planet'), 'planet_preview');
    expect(normalizeNdviSource('sentinel'), 'sentinel');
  });

  test('ndviSourceLabel diferencia Sentinel e preview Planet', () {
    expect(ndviSourceLabel('sentinel'), 'Sentinel NDVI');
    expect(ndviSourceLabel('planet_preview'), 'Preview RGB (Planet)');
    expect(ndviSourceLabel('planet'), 'Preview RGB (Planet)');
  });

  test('mascara verde so e suportada para fontes NDVI reais', () {
    expect(ndviSupportsGreenMask('sentinel'), isTrue);
    expect(ndviSupportsGreenMask('planet_preview'), isFalse);
    expect(ndviSupportsGreenMask('planet'), isFalse);
  });

  test('preview Planet expoe disclaimer', () {
    expect(
      ndviPreviewDisclaimer('planet_preview'),
      contains('nao representa indice NDVI'),
    );
    expect(ndviPreviewDisclaimer('sentinel'), isNull);
  });
}
