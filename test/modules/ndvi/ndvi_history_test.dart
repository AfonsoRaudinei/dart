import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/domain/ndvi_history.dart';

NdviImage _image(String id, DateTime date) {
  return NdviImage(
    id: id,
    fieldId: 'F1',
    imageDate: date,
    ndviMin: 0.1,
    ndviMax: 0.8,
    ndviMean: 0.4,
    source: 'sentinel',
    fetchedAt: date,
    syncStatus: 0,
  );
}

void main() {
  final now = DateTime(2026, 9, 27);

  test('mantém a cena mais nova mesmo fora de 90 dias', () {
    final kept = ndviHistoryKept([
      _image('old', DateTime(2026, 1, 1)),
    ], now: now);
    expect(kept.single.id, 'old');
  });

  test('descarta cena antiga quando já existe uma dentro da janela', () {
    final kept = ndviHistoryKept([
      _image('jan', DateTime(2026, 1, 1)),
      _image('sep', DateTime(2026, 9, 1)),
    ], now: now);
    expect(kept.single.id, 'sep');
  });

  test('guarda no máximo 12 cenas, as mais novas', () {
    final images = [
      for (var day = 1; day <= 14; day++)
        _image('d$day', DateTime(2026, 9, day)),
    ];
    final kept = ndviHistoryKept(images, now: now);
    expect(kept, hasLength(kNdviHistoryMaxScenes));
    expect(kept.first.id, 'd14');
    expect(kept.last.id, 'd3');
  });
}
