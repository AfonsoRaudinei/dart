import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge_provider.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup_geofence_provider.dart';
import 'package:soloforte_app/modules/dashboard/domain/user_location_fix.dart';
import 'package:soloforte_app/modules/dashboard/providers/location_providers.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_repository.dart';
import 'package:soloforte_app/modules/visitas/domain/models/visit_session.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/geofence_controller.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';

class _FakeFieldLookup implements IFieldLookup {
  _FakeFieldLookup({List<FieldSummary> fields = const []}) : _fields = fields;

  final List<FieldSummary> _fields;
  int listAllCalls = 0;

  @override
  Future<FieldSummary?> findById(String fieldId) async => null;

  @override
  Future<List<FieldSummary>> listAll() async {
    listAllCalls++;
    return _fields;
  }

  @override
  Future<List<FieldSummary>> listByFarmId(String farmId) async => const [];
}

class _FakeVisitRepository extends VisitRepository {
  @override
  Future<VisitSession?> getActiveSession() async => null;
}

class _FakeAgendaBridge implements IAgendaSessionBridge {
  @override
  Future<void> linkSessionToEvent({
    required String agendaEventId,
    required String sessionId,
  }) async {}

  @override
  Future<void> markEventAsDone(String sessionId) async {}
}

void main() {
  test('avalia posição já cacheada ao ativar no mapa', () async {
    final fieldLookup = _FakeFieldLookup();
    final container = ProviderContainer(
      overrides: [
        locationStreamProvider.overrideWith(
          (ref) => Stream.value(
            const UserLocationFix(
              position: LatLng(-15, -47),
              accuracyM: 8,
            ),
          ),
        ),
        iFieldLookupGeofenceProvider.overrideWithValue(fieldLookup),
        visitRepositoryProvider.overrideWithValue(_FakeVisitRepository()),
        agendaSessionBridgeProvider.overrideWithValue(_FakeAgendaBridge()),
      ],
    );
    addTearDown(container.dispose);

    final locationKeepAlive = container.listen(
      locationStreamProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(locationKeepAlive.close);
    await container.pump();
    expect(container.read(locationStreamProvider).valueOrNull, isNotNull);

    final mapLifecycle = container.listen(
      geofenceControllerProvider,
      (previous, next) {},
      fireImmediately: true,
    );
    addTearDown(mapLifecycle.close);
    await container.pump();

    expect(fieldLookup.listAllCalls, 1);
  });

  test(
    'usa stream foreground, aplica throttle e encerra no teardown',
    () async {
      final positions = StreamController<UserLocationFix>.broadcast();
      final fieldLookup = _FakeFieldLookup();
      final container = ProviderContainer(
        overrides: [
          locationStreamProvider.overrideWith((ref) => positions.stream),
          iFieldLookupGeofenceProvider.overrideWithValue(fieldLookup),
          visitRepositoryProvider.overrideWithValue(_FakeVisitRepository()),
          agendaSessionBridgeProvider.overrideWithValue(_FakeAgendaBridge()),
        ],
      );
      addTearDown(() async {
        await positions.close();
        container.dispose();
      });

      final mapLifecycle = container.listen(
        geofenceControllerProvider,
        (previous, next) {},
        fireImmediately: true,
      );
      await container.pump();

      positions.add(
        const UserLocationFix(position: LatLng(-15, -47), accuracyM: 6),
      );
      await container.pump();
      expect(fieldLookup.listAllCalls, 1);

      positions.add(
        const UserLocationFix(
          position: LatLng(-15.0001, -47.0001),
          accuracyM: 6,
        ),
      );
      await container.pump();
      expect(fieldLookup.listAllCalls, 1);

      mapLifecycle.close();
      await container.pump();
      positions.add(
        const UserLocationFix(position: LatLng(-16, -48), accuracyM: 6),
      );
      await container.pump();
      expect(fieldLookup.listAllCalls, 1);
    },
  );

  group('GeofenceController.isInsideOrCloseForTest', () {
    const outer = [
      [-47.93, -15.78],
      [-47.92, -15.78],
      [-47.92, -15.77],
      [-47.93, -15.77],
      [-47.93, -15.78],
    ];
    const hole = [
      [-47.927, -15.777],
      [-47.923, -15.777],
      [-47.923, -15.773],
      [-47.927, -15.773],
      [-47.927, -15.777],
    ];

    FieldSummary fieldSummary(String geoJson) => FieldSummary(
          id: 'f1',
          name: 'Talhão',
          farmId: 'farm',
          areaHa: 10,
          geometry: geoJson,
        );

    test('MultiPolygon: dentro de qualquer parte', () {
      final geo = jsonEncode({
        'type': 'MultiPolygon',
        'coordinates': [
          [outer],
          [
            [
              [-47.88, -15.78],
              [-47.87, -15.78],
              [-47.87, -15.77],
              [-47.88, -15.77],
              [-47.88, -15.78],
            ],
          ],
        ],
      });
      final container = ProviderContainer(
        overrides: [
          locationStreamProvider.overrideWith((ref) => const Stream.empty()),
          iFieldLookupGeofenceProvider.overrideWithValue(_FakeFieldLookup()),
          visitRepositoryProvider.overrideWithValue(_FakeVisitRepository()),
          agendaSessionBridgeProvider.overrideWithValue(_FakeAgendaBridge()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(geofenceControllerProvider);
      expect(
        controller.isInsideOrCloseForTest(
          const LatLng(-15.775, -47.925),
          fieldSummary(geo),
        ),
        isTrue,
      );
      expect(
        controller.isInsideOrCloseForTest(
          const LatLng(-15.775, -47.875),
          fieldSummary(geo),
        ),
        isTrue,
      );
    });

    test('furo: ponto no buraco não conta como dentro', () {
      final geo = jsonEncode({
        'type': 'Polygon',
        'coordinates': [outer, hole],
      });
      final container = ProviderContainer(
        overrides: [
          locationStreamProvider.overrideWith((ref) => const Stream.empty()),
          iFieldLookupGeofenceProvider.overrideWithValue(_FakeFieldLookup()),
          visitRepositoryProvider.overrideWithValue(_FakeVisitRepository()),
          agendaSessionBridgeProvider.overrideWithValue(_FakeAgendaBridge()),
        ],
      );
      addTearDown(container.dispose);
      final controller = container.read(geofenceControllerProvider);
      expect(
        controller.isInsideOrCloseForTest(
          const LatLng(-15.775, -47.925),
          fieldSummary(geo),
        ),
        isFalse,
      );
    });
  });
}
