import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'fake_ndvi_repository.dart';

void main() {
  late FakeNdviRepository repo;

  setUp(() {
    repo = FakeNdviRepository();
  });

  test('getLatestByFieldId retorna a mais recente', () async {
    final img1 = NdviImage(
      id: '1', fieldId: 'F1', imageDate: DateTime(2026, 1, 1),
      ndviMin: 0.1, ndviMax: 0.8, ndviMean: 0.5, source: 'auto',
      fetchedAt: DateTime.now(), syncStatus: 0,
    );
    final img2 = NdviImage(
      id: '2', fieldId: 'F1', imageDate: DateTime(2026, 2, 1),
      ndviMin: 0.1, ndviMax: 0.8, ndviMean: 0.6, source: 'auto',
      fetchedAt: DateTime.now(), syncStatus: 0,
    );
    
    await repo.save(img1);
    await repo.save(img2);

    final latest = await repo.getLatestByFieldId('F1');
    expect(latest?.id, '2');
  });

  test('getLatestByFieldId com field inexistente retorna null', () async {
    final latest = await repo.getLatestByFieldId('INEXISTENTE');
    expect(latest, isNull);
  });

  test('deleteByFieldId limpa os dados', () async {
    final img = NdviImage(
       id: '1', fieldId: 'F1', imageDate: DateTime(2026, 1, 1),
      ndviMin: 0.1, ndviMax: 0.8, ndviMean: 0.5, source: 'auto',
      fetchedAt: DateTime.now(), syncStatus: 0,
    );
    
    await repo.save(img);
    await repo.deleteByFieldId('F1');
    final check = await repo.getByFieldId('F1');
    expect(check, isEmpty);
  });
}
