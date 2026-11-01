import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_field_refresh.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_field_refresh_provider.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/ndvi_latest_summary.dart';
import 'package:soloforte_app/core/state/map_ndvi_overlay.dart';
import 'package:soloforte_app/modules/ndvi/data/repositories/i_ndvi_repository.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';
import 'package:soloforte_app/modules/ndvi/infra/ndvi_field_refresh_adapter.dart';
import 'package:soloforte_app/modules/ndvi/infra/ndvi_latest_lookup_adapter.dart';
import 'package:soloforte_app/modules/ndvi/presentation/providers/ndvi_providers.dart';

void main() {
  test(
    'getLatest com data usa ensureImageForDate e sem data usa a última',
    () async {
      final repo = _CountingRepository();
      final adapter = NdviLatestLookupAdapter(repo);

      final dated = await adapter.getLatest('field-1', imageDate: '2026-10-16');
      final latest = await adapter.getLatest('field-1');

      expect(repo.ensured, ['2026-10-16']);
      expect(repo.latestCalls, 1);
      expect(dated?.imageDate, DateTime(2026, 10, 16));
      expect(latest?.imageDate, DateTime(2026, 10, 28));
    },
  );

  test('refresh invalida o overlay do mapa', () async {
    final lookup = _CountingLookup();
    final container = ProviderContainer(
      overrides: [
        ndviRepositoryProvider.overrideWithValue(_CountingRepository()),
        ndviLatestLookupProvider.overrideWithValue(lookup),
        ndviFieldRefreshProvider.overrideWith(
          (ref) => NdviFieldRefreshAdapter(ref),
        ),
      ],
    );
    addTearDown(container.dispose);
    final keep = container.listen(mapNdviOverlaySummaryProvider, (_, __) {});
    addTearDown(keep.close);

    container.read(mapNdviOverlayFieldIdProvider.notifier).state = 'f1';
    await container.read(mapNdviOverlaySummaryProvider.future);
    expect(lookup.calls, 1);

    final refresh = container.read(ndviFieldRefreshProvider);
    expect(refresh, isA<INdviFieldRefresh>());
    await refresh.clearCacheAndReload('f1');
    await container.read(mapNdviOverlaySummaryProvider.future);

    expect(lookup.calls, 2);
  });
}

class _CountingLookup implements INdviLatestLookup {
  int calls = 0;

  @override
  Future<NdviLatestSummary?> getLatest(
    String fieldId, {
    String? imageDate,
  }) async {
    calls++;
    return NdviLatestSummary(
      imageDate: DateTime(2026, 10, 28),
      ndviMean: 0.4,
      ndviMin: 0,
      ndviMax: 0.8,
      sourceLabel: 'Sentinel NDVI',
      source: 'sentinel',
      isColormap: true,
      imageUrl: 'https://example.com/ndvi.png',
    );
  }
}

class _CountingRepository implements INdviRepository {
  int latestCalls = 0;
  final List<String> ensured = [];

  NdviImage _image(String fieldId, DateTime date) {
    return NdviImage(
      id: '$fieldId-${date.toIso8601String()}',
      fieldId: fieldId,
      imageDate: date,
      ndviMin: 0.1,
      ndviMax: 0.8,
      ndviMean: 0.4,
      source: 'sentinel',
      fetchedAt: DateTime(2026, 10, 28),
      syncStatus: 0,
      imageUrl: 'https://example.com/ndvi.png',
    );
  }

  @override
  Future<void> deleteByFieldId(String fieldId) async {}

  @override
  Future<NdviImage?> ensureImageForDate(
    String fieldId,
    String imageDate,
  ) async {
    ensured.add(imageDate);
    return _image(fieldId, DateTime.parse(imageDate));
  }

  @override
  Future<List<NdviImage>> getByFieldId(String fieldId) async => const [];

  @override
  Future<NdviImage?> getLatestByFieldId(String fieldId) async {
    latestCalls++;
    return _image(fieldId, DateTime(2026, 10, 28));
  }

  @override
  Future<void> save(NdviImage image) async {}
}
