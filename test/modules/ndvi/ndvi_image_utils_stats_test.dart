import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/domain/ndvi_image_utils.dart';

void main() {
  test('ndviImageHasMeasuredStats false quando stats zeradas com imagem', () {
    final image = NdviImage(
      id: '1',
      fieldId: 'f1',
      imageDate: DateTime(2026, 10, 13),
      ndviMin: 0,
      ndviMax: 0,
      ndviMean: 0,
      localPath: '/tmp/ndvi.png',
      source: 'sentinel',
      fetchedAt: DateTime.now(),
      syncStatus: 0,
    );
    expect(ndviImageHasMeasuredStats(image), isFalse);
  });

  test('ndviImageHasMeasuredStats true quando ha valor nao zero', () {
    final image = NdviImage(
      id: '1',
      fieldId: 'f1',
      imageDate: DateTime(2026, 10, 13),
      ndviMin: 0.1,
      ndviMax: 0.8,
      ndviMean: 0.5,
      localPath: '/tmp/ndvi.png',
      source: 'sentinel',
      fetchedAt: DateTime.now(),
      syncStatus: 0,
    );
    expect(ndviImageHasMeasuredStats(image), isTrue);
  });
}
