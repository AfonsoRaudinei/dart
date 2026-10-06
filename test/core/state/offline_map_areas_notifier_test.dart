import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/state/map_state.dart';

void main() {
  late ProviderContainer container;

  Future<void> setUpContainer() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    container = ProviderContainer(
      overrides: [preferencesServiceProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
  }

  OfflineMapAreaConfig farmArea({
    required String farmId,
    required double south,
    required double west,
    required double north,
    required double east,
  }) {
    return OfflineMapAreaConfig(
      id: 'farm:$farmId',
      layerKey: 'sat',
      south: south,
      west: west,
      north: north,
      east: east,
      minZoom: 14,
      maxZoom: 18,
      createdAt: DateTime(2026, 10, 5),
    );
  }

  test('duas fazendas sem overlap viram duas entradas farm:', () async {
    await setUpContainer();
    final notifier = container.read(offlineMapAreasProvider.notifier);

    notifier.updateArea(
      farmArea(farmId: 'A', south: -10, west: -48, north: -9, east: -47),
    );
    notifier.updateArea(
      farmArea(farmId: 'B', south: -8, west: -46, north: -7, east: -45),
    );

    final areas = container.read(offlineMapAreasProvider);
    expect(areas.map((a) => a.id), ['farm:A', 'farm:B']);
  });

  test(
    'fazenda B com bbox dentro de A não engole farm:A nem perde o id',
    () async {
      await setUpContainer();
      final notifier = container.read(offlineMapAreasProvider.notifier);
      final farmA = farmArea(
        farmId: 'A',
        south: -10,
        west: -48,
        north: -9,
        east: -47,
      );
      notifier.updateArea(farmA);
      notifier.updateArea(
        farmArea(
          farmId: 'B',
          south: -9.8,
          west: -47.8,
          north: -9.2,
          east: -47.2,
        ),
      );

      final areas = container.read(offlineMapAreasProvider);
      expect(areas.map((a) => a.id), ['farm:A', 'farm:B']);
      final keptA = areas.firstWhere((a) => a.id == 'farm:A');
      expect(keptA.south, farmA.south);
      expect(keptA.west, farmA.west);
      expect(keptA.north, farmA.north);
      expect(keptA.east, farmA.east);
    },
  );

  test('mesmo farm:id rebaixa só a área daquela fazenda', () async {
    await setUpContainer();
    final notifier = container.read(offlineMapAreasProvider.notifier);
    notifier.updateArea(
      farmArea(farmId: 'A', south: -10, west: -48, north: -9, east: -47),
    );
    notifier.updateArea(
      farmArea(
        farmId: 'A',
        south: -10.2,
        west: -48.2,
        north: -8.8,
        east: -46.8,
      ),
    );

    final areas = container.read(offlineMapAreasProvider);
    expect(areas, hasLength(1));
    expect(areas.single.id, 'farm:A');
    expect(areas.single.south, -10.2);
    expect(areas.single.east, -46.8);
  });

  test(
    'viewport timestamp ainda une bbox contido, sem engolir farm:',
    () async {
      await setUpContainer();
      final notifier = container.read(offlineMapAreasProvider.notifier);
      notifier.updateArea(
        farmArea(farmId: 'A', south: -10, west: -48, north: -9, east: -47),
      );
      notifier.updateArea(
        OfflineMapAreaConfig(
          id: '1728000000000',
          layerKey: 'sat',
          south: -12,
          west: -50,
          north: -8,
          east: -45,
          minZoom: 12,
          maxZoom: 18,
          createdAt: DateTime(2026, 10, 5),
        ),
      );
      notifier.updateArea(
        OfflineMapAreaConfig(
          id: '1728000000001',
          layerKey: 'sat',
          south: -11,
          west: -49,
          north: -10,
          east: -46,
          minZoom: 14,
          maxZoom: 16,
          createdAt: DateTime(2026, 10, 5),
        ),
      );

      final areas = container.read(offlineMapAreasProvider);
      expect(areas.map((a) => a.id), ['farm:A', '1728000000000']);
    },
  );

  test('intersectionWith recorta e devolve null sem overlap', () {
    final area = OfflineMapAreaConfig(
      id: 'farm:A',
      layerKey: 'sat',
      south: -10,
      west: -48,
      north: -9,
      east: -47,
      minZoom: 14,
      maxZoom: 18,
      createdAt: DateTime(2026, 10, 5),
    );

    final clipped = area.intersectionWith(
      south: -10.5,
      west: -48.5,
      north: -8.5,
      east: -46.5,
    );
    expect(clipped, isNotNull);
    expect(clipped!.south, -10);
    expect(clipped.west, -48);
    expect(clipped.north, -9);
    expect(clipped.east, -47);

    expect(
      area.intersectionWith(south: -8, west: -46, north: -7, east: -45),
      isNull,
    );
  });
}
