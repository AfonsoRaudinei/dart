import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/infra/ndvi_latest_lookup_adapter.dart';

import 'fake_ndvi_repository.dart';

void main() {
  test('getLatest devolve localPath e imageUrl da última imagem', () async {
    final repo = FakeNdviRepository();
    await repo.save(
      NdviImage(
        id: 'img-1',
        fieldId: 'field-1',
        imageDate: DateTime(2026, 9, 12),
        ndviMin: 0.1,
        ndviMax: 0.9,
        ndviMean: 0.62,
        source: 'sentinel',
        fetchedAt: DateTime(2026, 9, 12),
        syncStatus: 0,
        localPath: '/tmp/ndvi/field-1.png',
        imageUrl: 'https://example.com/ndvi/field-1.png',
      ),
    );

    final summary = await NdviLatestLookupAdapter(repo).getLatest('field-1');

    expect(summary, isNotNull);
    expect(summary!.localPath, '/tmp/ndvi/field-1.png');
    expect(summary.imageUrl, 'https://example.com/ndvi/field-1.png');
    expect(summary.ndviMean, 0.62);
    expect(summary.source, 'sentinel');
    expect(summary.isColormap, isTrue);
  });

  test('getLatest marca planet_preview como não colormap', () async {
    final repo = FakeNdviRepository();
    await repo.save(
      NdviImage(
        id: 'img-planet',
        fieldId: 'field-2',
        imageDate: DateTime(2026, 9, 22),
        ndviMin: 0,
        ndviMax: 0,
        ndviMean: 0,
        source: 'planet',
        fetchedAt: DateTime(2026, 9, 22),
        syncStatus: 0,
        localPath: '/tmp/ndvi/field-2.png',
      ),
    );

    final summary = await NdviLatestLookupAdapter(repo).getLatest('field-2');

    expect(summary, isNotNull);
    expect(summary!.source, 'planet_preview');
    expect(summary.isColormap, isFalse);
  });
}
