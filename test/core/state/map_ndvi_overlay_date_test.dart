import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup.dart';
import 'package:soloforte_app/core/contracts/i_ndvi_latest_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/ndvi_latest_summary.dart';
import 'package:soloforte_app/core/state/map_ndvi_overlay.dart';

void main() {
  test('sem data selecionada pede a última imagem', () async {
    final lookup = _RecordingLookup();
    final container = _container(lookup);
    addTearDown(container.dispose);
    final keep = container.listen(mapNdviOverlaySummaryProvider, (_, __) {});
    addTearDown(keep.close);

    container.read(mapNdviOverlayFieldIdProvider.notifier).state = 'f1';
    final summary = await container.read(mapNdviOverlaySummaryProvider.future);

    expect(lookup.requestedDates, [null]);
    expect(summary?.imageDate, DateTime(2026, 10, 28));
    expect(container.read(mapNdviOverlayDateErrorProvider), isNull);
  });

  test('data selecionada pede essa imagem', () async {
    final lookup = _RecordingLookup();
    final container = _container(lookup);
    addTearDown(container.dispose);
    final keep = container.listen(mapNdviOverlaySummaryProvider, (_, __) {});
    addTearDown(keep.close);

    container.read(mapNdviOverlayFieldIdProvider.notifier).state = 'f1';
    container.read(mapNdviSelectedDateProvider.notifier).state =
        const MapNdviDateSelection(fieldId: 'f1', dateKey: '2026-10-16');

    final summary = await container.read(mapNdviOverlaySummaryProvider.future);

    expect(lookup.requestedDates, ['2026-10-16']);
    expect(summary?.imageDate, DateTime(2026, 10, 16));
  });

  test('falha da data nova mantém o raster anterior e marca erro', () async {
    final lookup = _RecordingLookup();
    final container = _container(lookup);
    addTearDown(container.dispose);
    final keep = container.listen(mapNdviOverlaySummaryProvider, (_, __) {});
    addTearDown(keep.close);

    container.read(mapNdviOverlayFieldIdProvider.notifier).state = 'f1';
    final first = await container.read(mapNdviOverlaySummaryProvider.future);
    expect(first?.imageDate, DateTime(2026, 10, 28));

    lookup.failKey = '2026-10-10';
    container.read(mapNdviSelectedDateProvider.notifier).state =
        const MapNdviDateSelection(fieldId: 'f1', dateKey: '2026-10-10');
    final kept = await container.read(mapNdviOverlaySummaryProvider.future);

    expect(kept?.imageDate, DateTime(2026, 10, 28));
    expect(
      container.read(mapNdviOverlayDateErrorProvider),
      const MapNdviDateError(fieldId: 'f1', dateKey: '2026-10-10'),
    );
  });

  test('falha sem raster anterior propaga o erro', () async {
    final lookup = _RecordingLookup()..failKey = '2026-10-10';
    final container = _container(lookup);
    addTearDown(container.dispose);

    container.read(mapNdviOverlayFieldIdProvider.notifier).state = 'f1';
    container.read(mapNdviSelectedDateProvider.notifier).state =
        const MapNdviDateSelection(fieldId: 'f1', dateKey: '2026-10-10');

    await expectLater(
      container.read(mapNdviOverlaySummaryProvider.future),
      throwsA(isA<StateError>()),
    );
  });

  test('trocar o talhão do overlay descarta a data escolhida', () async {
    final lookup = _RecordingLookup();
    final container = _container(lookup);
    addTearDown(container.dispose);
    final keep = container.listen(mapNdviOverlaySummaryProvider, (_, __) {});
    addTearDown(keep.close);

    container.read(mapNdviOverlayFieldIdProvider.notifier).state = 'f1';
    container.read(mapNdviSelectedDateProvider.notifier).state =
        const MapNdviDateSelection(fieldId: 'f1', dateKey: '2026-10-16');
    await container.read(mapNdviOverlaySummaryProvider.future);

    container.read(mapNdviOverlayFieldIdProvider.notifier).state = null;
    await container.read(mapNdviOverlaySummaryProvider.future);

    expect(container.read(mapNdviSelectedDateProvider), isNull);
    expect(container.read(mapNdviRetainedSummaryProvider), isNull);
  });
}

ProviderContainer _container(_RecordingLookup lookup) {
  return ProviderContainer(
    overrides: [ndviLatestLookupProvider.overrideWithValue(lookup)],
  );
}

class _RecordingLookup implements INdviLatestLookup {
  final List<String?> requestedDates = [];
  String? failKey;

  @override
  Future<NdviLatestSummary?> getLatest(
    String fieldId, {
    String? imageDate,
  }) async {
    requestedDates.add(imageDate);
    if (imageDate != null && imageDate == failKey) {
      throw StateError('ndvi-offline');
    }
    return NdviLatestSummary(
      imageDate: DateTime.parse(imageDate ?? '2026-10-28'),
      ndviMean: 0.5,
      ndviMin: 0.1,
      ndviMax: 0.9,
      sourceLabel: 'Sentinel NDVI',
      source: 'sentinel',
      isColormap: true,
      imageUrl: 'https://example.com/ndvi.png',
    );
  }
}
