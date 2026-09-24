import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/ndvi_latest_summary.dart';
import 'package:soloforte_app/core/state/map_ndvi_overlay.dart';

void main() {
  test('preview RGB não cobre o talhão no mapa', () {
    final planet = NdviLatestSummary(
      imageDate: DateTime(2026, 9, 22),
      ndviMean: 0,
      ndviMin: 0,
      ndviMax: 0,
      sourceLabel: 'Preview RGB (Planet)',
      source: 'planet_preview',
      isColormap: false,
      imageUrl: 'https://example.com/planet.jpg',
    );

    expect(mapNdviSummaryCoversField(planet), isFalse);
    expect(mapNdviSummaryCoversField(null), isFalse);
  });

  test('colormap com URL ou arquivo local cobre o talhão', () {
    final remote = NdviLatestSummary(
      imageDate: DateTime(2026, 9, 12),
      ndviMean: 0.62,
      ndviMin: 0.1,
      ndviMax: 0.9,
      sourceLabel: 'Sentinel NDVI',
      source: 'sentinel',
      isColormap: true,
      imageUrl: 'https://example.com/ndvi.png',
    );
    final missingFile = NdviLatestSummary(
      imageDate: DateTime(2026, 9, 12),
      ndviMean: 0.62,
      ndviMin: 0.1,
      ndviMax: 0.9,
      sourceLabel: 'Sentinel NDVI',
      source: 'sentinel',
      isColormap: true,
      localPath: '/tmp/soloforte-ndvi-ausente.png',
    );
    final file = File('${Directory.systemTemp.path}/soloforte-ndvi-overlay.png')
      ..writeAsBytesSync([1, 2, 3]);
    addTearDown(() {
      if (file.existsSync()) file.deleteSync();
    });
    final local = NdviLatestSummary(
      imageDate: DateTime(2026, 9, 12),
      ndviMean: 0.4,
      ndviMin: 0,
      ndviMax: 0.8,
      sourceLabel: 'Sentinel NDVI',
      source: 'sentinel',
      isColormap: true,
      localPath: file.path,
    );

    expect(mapNdviSummaryCoversField(remote), isTrue);
    expect(mapNdviSummaryCoversField(missingFile), isFalse);
    expect(mapNdviSummaryCoversField(local), isTrue);
  });
}
