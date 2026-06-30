import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/ndvi/data/models/ndvi_image_model.dart';

void main() {
  test('fromMap com todos os campos cria a entidade correta', () {
    final map = {
      'id': '123',
      'field_id': 'F1',
      'image_date': '2026-03-01T00:00:00.000',
      'ndvi_min': 0.2,
      'ndvi_max': 0.9,
      'ndvi_mean': 0.6,
      'source': 'sentinel',
      'fetched_at': '2026-03-01T12:00:00.000',
      'sync_status': 1
    };

    final model = NdviImageModel.fromMap(map);
    final entity = model.toEntity();

    expect(entity.id, '123');
    expect(entity.fieldId, 'F1');
    expect(entity.ndviMin, 0.2);
    expect(entity.syncStatus, 1);
  });

  test('toMap gera o map correto', () {
    final map = {
      'id': '123',
      'field_id': 'F1',
      'image_date': '2026-03-01T00:00:00.000Z',
      'ndvi_min': 0.2,
      'ndvi_max': 0.9,
      'ndvi_mean': 0.6,
      'image_url': null,
      'local_path': null,
      'source': 'sentinel',
      'fetched_at': '2026-03-01T12:00:00.000Z',
      'sync_status': 1
    };

    final model = NdviImageModel.fromMap(map);
    final outMap = model.toMap();

    expect(outMap['id'], '123');
    expect(outMap['field_id'], 'F1');
    expect(outMap['ndvi_max'], 0.9);
  });
}
