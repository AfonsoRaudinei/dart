import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge.dart';
import 'package:soloforte_app/core/contracts/i_agenda_session_bridge_provider.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_repository.dart';
import 'package:soloforte_app/modules/visitas/domain/models/visit_route_stop.dart';
import 'package:soloforte_app/modules/visitas/domain/models/visit_session.dart';
import 'package:soloforte_app/modules/visitas/domain/visit_route_advance.dart';
import 'package:soloforte_app/modules/visitas/presentation/controllers/visit_controller.dart';
import 'package:soloforte_app/modules/visitas/presentation/visit_route_notification_port.dart';

class _FakeVisitRepository extends VisitRepository {
  VisitSession? active;

  @override
  Future<VisitSession?> getActiveSession() async => active;

  @override
  Future<void> saveRouteState(
    String sessionId, {
    required String? routeStopsJson,
    required int? routeCurrentIndex,
  }) async {
    final current = active;
    if (current == null || current.id != sessionId) return;
    active = current.copyWithRoute(
      routeStopsJson: routeStopsJson,
      routeCurrentIndex: routeCurrentIndex,
    );
  }
}

class _FakeAgendaBridge implements IAgendaSessionBridge {
  @override
  Future<void> linkSessionToEvent({
    required String agendaEventId,
    required String sessionId,
  }) async {}

  @override
  Future<void> markEventAsDone(String sessionId) async {}

  @override
  Future<void> registerFieldCheckIn(FieldVisitCheckIn input) async {}

  @override
  Future<void> updateFieldVisitPlace({
    required String sessionId,
    String? farmId,
    String? areaId,
    bool clearArea = false,
  }) async {}

  @override
  Future<void> closeFieldVisit(String sessionId) async {}

  @override
  Future<void> registerFinishedFieldVisit(FieldVisitCheckIn input) async {}
}

class _FakeRouteNotifications implements VisitRouteNotificationPort {
  int nextCalls = 0;
  int? lastIndex;
  int? lastTotal;
  String? lastPayload;
  int completedCalls = 0;

  @override
  Future<bool> ensurePermission() async => true;

  @override
  Future<bool> showNextStop({
    required int index,
    required int total,
    required String payload,
  }) async {
    nextCalls++;
    lastIndex = index;
    lastTotal = total;
    lastPayload = payload;
    return true;
  }

  @override
  Future<bool> showRouteCompleted({required int total}) async {
    completedCalls++;
    return true;
  }
}

VisitSession _sessionWithRoute() {
  final stops = [
    const VisitRouteStop(
      index: 1,
      lat: -10.2,
      lng: -48.2,
      status: VisitRouteStopStatus.pending,
    ),
    const VisitRouteStop(
      index: 2,
      lat: -10.6,
      lng: -48.6,
      status: VisitRouteStopStatus.pending,
    ),
  ];
  return VisitSession(
    id: 'session-route',
    producerId: 'producer-1',
    areaId: 'area-1',
    activityType: 'Visita técnica',
    startTime: DateTime(2026, 11, 5, 8),
    initialLat: -10.2,
    initialLong: -48.2,
    status: 'active',
    createdAt: DateTime(2026, 11, 5, 8),
    updatedAt: DateTime(2026, 11, 5, 8),
    routeStopsJson: VisitRouteStop.encodeList(stops),
    routeCurrentIndex: 1,
  );
}

void main() {
  test('advance marca a parada e aponta a próxima', () {
    final session = _sessionWithRoute();
    final advance = advanceVisitRoute(
      stops: session.routeStops,
      currentIndex: session.routeCurrentIndex,
      occurrenceId: 'occ-1',
    );

    expect(advance, isNotNull);
    expect(advance!.completed.isDone, isTrue);
    expect(advance.completed.occurrenceId, 'occ-1');
    expect(advance.currentIndex, 2);
    expect(advance.next?.index, 2);
    expect(advance.stops.first.status, VisitRouteStopStatus.done);
    expect(advance.stops.last.status, VisitRouteStopStatus.pending);
  });

  test('concluir parada dispara notificação da próxima', () async {
    final repo = _FakeVisitRepository()..active = _sessionWithRoute();
    final notes = _FakeRouteNotifications();
    final container = ProviderContainer(
      overrides: [
        visitRepositoryProvider.overrideWithValue(repo),
        agendaSessionBridgeProvider.overrideWithValue(_FakeAgendaBridge()),
        visitRouteNotificationPortProvider.overrideWithValue(notes),
      ],
    );
    addTearDown(container.dispose);

    final controller = container.read(visitControllerProvider.notifier);
    await Future<void>.delayed(Duration.zero);
    expect(container.read(visitControllerProvider).valueOrNull, isNotNull);
    await controller.completeCurrentStop(occurrenceId: 'occ-9');

    final session = container.read(visitControllerProvider).valueOrNull;
    expect(session?.routeCurrentIndex, 2);
    expect(session?.routeStops.first.isDone, isTrue);
    expect(session?.routeStops.first.occurrenceId, 'occ-9');
    expect(notes.nextCalls, 1);
    expect(notes.lastIndex, 2);
    expect(notes.lastTotal, 2);
    expect(notes.lastPayload, contains('modo=foco'));
    expect(notes.lastPayload, contains('lat='));
    expect(notes.lastPayload, contains('lng='));
    expect(notes.completedCalls, 0);

    await controller.completeCurrentStop(occurrenceId: 'occ-10');
    final done = container.read(visitControllerProvider).valueOrNull;
    expect(done?.routeCurrentIndex, isNull);
    expect(done?.currentRouteStop, isNull);
    expect(notes.completedCalls, 1);
  });
}
