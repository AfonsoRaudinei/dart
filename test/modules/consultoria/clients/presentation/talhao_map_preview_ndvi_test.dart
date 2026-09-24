import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/contracts/ndvi_latest_summary.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/farm_linked_field_list.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/talhao_map_preview.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late File png;

  setUp(() {
    png = File('${Directory.systemTemp.path}/soloforte_ndvi_card_test.png');
    png.writeAsBytesSync(
      base64Decode(
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
      ),
    );
  });

  tearDown(() {
    if (png.existsSync()) png.deleteSync();
  });

  test('legenda omite média 0 do preview RGB', () {
    final planet = NdviLatestSummary(
      imageDate: DateTime(2026, 9, 22),
      ndviMean: 0,
      ndviMin: 0,
      ndviMax: 0,
      sourceLabel: 'Preview RGB (Planet)',
      source: 'planet_preview',
      isColormap: false,
      localPath: '/tmp/planet.png',
    );
    final sentinel = NdviLatestSummary(
      imageDate: DateTime(2026, 9, 12),
      ndviMean: 0.62,
      ndviMin: 0.1,
      ndviMax: 0.9,
      sourceLabel: 'Sentinel NDVI',
      source: 'sentinel',
      isColormap: true,
      localPath: '/tmp/ndvi.png',
    );

    expect(talhaoCardNdviCaption(planet), isNull);
    expect(talhaoCardNdviBadge(planet), 'Preview RGB');
    expect(talhaoCardNdviCaption(sentinel), '0.62 · 12/09');
    expect(talhaoCardNdviBadge(sentinel), isNull);
  });

  testWidgets('sentinel monta o overlay recortado ao polígono', (tester) async {
    await tester.pumpWidget(
      _host(
        TalhaoMapPreviewWidget(
          vertices: _triangle,
          nome: 'Th 10',
          areaHa: 95,
          showNdvi: true,
          ndviIsColormap: true,
          ndviLocalPath: png.path,
          ndviCaption: '0.62 · 12/09',
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('ndvi-polygon-overlay')), findsOneWidget);
    expect(find.text('0.62 · 12/09'), findsOneWidget);
    expect(find.text('Preview RGB'), findsNothing);
    expect(find.text('Sem NDVI'), findsNothing);
  });

  testWidgets('planet_preview não georreferencia e mostra Preview RGB', (
    tester,
  ) async {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      final message = details.exceptionAsString();
      if (message.contains('ClientException') ||
          message.contains('basemaps.cartocdn.com')) {
        return;
      }
      previousOnError?.call(details);
    };
    addTearDown(() => FlutterError.onError = previousOnError);

    await tester.pumpWidget(
      _host(
        TalhaoMapPreviewWidget(
          vertices: _triangle,
          nome: 'Th 4',
          areaHa: 37,
          showNdvi: true,
          ndviLocalPath: png.path,
          ndviBadge: 'Preview RGB',
        ),
      ),
    );
    await tester.pump();

    expect(find.byKey(const Key('ndvi-polygon-overlay')), findsNothing);
    expect(find.text('Preview RGB'), findsOneWidget);
    expect(find.text('0.00 · 22/09'), findsNothing);
    expect(find.text('Sem NDVI'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

const _triangle = <LatLng>[
  LatLng(-10.2, -48.4),
  LatLng(-10.2, -48.2),
  LatLng(-10.4, -48.3),
];

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(width: 360, height: 420, child: child),
    ),
  );
}
