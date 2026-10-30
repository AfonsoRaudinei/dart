import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/agronomic_models.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/field_providers.dart';
import 'package:soloforte_app/ui/screens/map/layers/talhao_polygon_layer.dart';
import 'package:shared_preferences/shared_preferences.dart';

Talhao _field(String id, Map<String, dynamic> geometry) {
  return Talhao(
    id: id,
    name: 'Campo $id',
    areaHa: 10,
    crop: 'Milho',
    harvest: '2025/26',
    geometry: geometry,
  );
}

const _ring = [
  [-47.93, -15.78],
  [-47.92, -15.78],
  [-47.92, -15.77],
  [-47.93, -15.77],
  [-47.93, -15.78],
];

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('TalhaoPolygonLayer renderiza N polígonos para MultiPolygon', (
    tester,
  ) async {
    final fields = [
      _field('a', {
        'type': 'MultiPolygon',
        'coordinates': [
          [_ring],
          [
            [
              [-47.91, -15.78],
              [-47.90, -15.78],
              [-47.90, -15.77],
              [-47.91, -15.77],
              [-47.91, -15.78],
            ],
          ],
        ],
      }),
    ];

    final preferencesService = PreferencesService(
      await SharedPreferences.getInstance(),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          preferencesServiceProvider.overrideWithValue(preferencesService),
          mapFieldsProvider.overrideWith((ref) async => fields),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: FlutterMap(
              options: MapOptions(
                initialCenter: LatLng(-15.775, -47.915),
                initialZoom: 12,
              ),
              children: [TalhaoPolygonLayer()],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final layer = tester.widget<PolygonLayer>(find.byType(PolygonLayer));
    expect(layer.polygons, hasLength(2));
    expect(layer.polygons.every((p) => p.points.isNotEmpty), isTrue);
  });
}
