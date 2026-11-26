import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/ndvi/domain/ndvi_image_utils.dart';

void main() {
  test('ndviNormalizeImageDateStorage corta ISO', () {
    expect(
      ndviNormalizeImageDateStorage('2026-03-01T00:00:00.000Z'),
      '2026-03-01',
    );
  });

  test('ndviParseCivilImageDate ignora fuso em chave curta', () {
    expect(
      ndviParseCivilImageDate('2026-03-01'),
      DateTime(2026, 3, 1),
    );
  });

  test('ndviDateChipLabel inclui idade após 7 dias', () {
    final scene = DateTime(2026, 1, 1);
    final now = DateTime(2026, 1, 20);
    expect(
      ndviDateChipLabel(scene, referenceNow: now),
      contains('há 19d'),
    );
  });
}