import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_sync_service.dart';
import 'package:soloforte_app/modules/visitas/domain/models/visit_session.dart';

VisitSession _session() => VisitSession(
  id: 'visit-1',
  producerId: 'client-1',
  farmId: 'farm-1',
  areaId: 'field-1',
  activityType: 'Monitoramento',
  startTime: DateTime(2026, 5, 31, 8),
  endTime: DateTime(2026, 5, 31, 9),
  initialLat: -10,
  initialLong: -48,
  status: 'finished',
  createdAt: DateTime(2026, 5, 31, 8),
  updatedAt: DateTime(2026, 5, 31, 9),
);

void main() {
  test('push usa start_time/end_time e não envia sync_status', () {
    final payload = VisitSyncService.toSupabasePayload(_session(), 'user-1');

    expect(payload['user_id'], 'user-1');
    expect(payload['producer_id'], 'client-1');
    expect(payload['farm_id'], 'farm-1');
    expect(payload['area_id'], 'field-1');
    expect(payload['activity_type'], 'Monitoramento');
    expect(payload['start_time'], '2026-05-31T08:00:00.000');
    expect(payload['end_time'], '2026-05-31T09:00:00.000');
    expect(payload['initial_lat'], -10.0);
    expect(payload['initial_long'], -48.0);
    expect(payload['status'], 'finished');
    expect(payload['created_at'], '2026-05-31T08:00:00.000');
    expect(payload['updated_at'], '2026-05-31T09:00:00.000');
    expect(payload.containsKey('started_at'), isFalse);
    expect(payload.containsKey('ended_at'), isFalse);
    expect(payload.containsKey('sync_status'), isFalse);
  });

  test('pull com start_time/end_time canônico', () {
    final local = VisitSyncService.fromSupabasePayload({
      'id': 'visit-1',
      'user_id': 'user-1',
      'producer_id': 'client-1',
      'farm_id': 'farm-1',
      'area_id': 'field-1',
      'activity_type': 'Monitoramento',
      'start_time': '2026-05-31T08:00:00.000',
      'end_time': null,
      'initial_lat': -10.5,
      'initial_long': -48.2,
      'status': 'active',
      'created_at': '2026-05-31T08:00:00.000',
      'updated_at': '2026-05-31T09:00:00.000',
    });

    expect(local['user_id'], 'user-1');
    expect(local['producer_id'], 'client-1');
    expect(local['farm_id'], 'farm-1');
    expect(local['area_id'], 'field-1');
    expect(local['activity_type'], 'Monitoramento');
    expect(local['start_time'], '2026-05-31T08:00:00.000');
    expect(local['end_time'], isNull);
    expect(local['initial_lat'], -10.5);
    expect(local['initial_long'], -48.2);
    expect(local['status'], 'active');
    expect(local['created_at'], '2026-05-31T08:00:00.000');
  });

  test('pull legado started_at/ended_at ainda funciona', () {
    final local = VisitSyncService.fromSupabasePayload({
      'id': 'visit-legacy',
      'user_id': 'user-1',
      'producer_id': 'client-1',
      'farm_id': 'farm-1',
      'area_id': 'field-1',
      'activity_type': 'Monitoramento',
      'started_at': '2026-05-31T08:00:00.000',
      'ended_at': '2026-05-31T10:00:00.000',
      'updated_at': '2026-05-31T10:00:00.000',
    });

    expect(local['start_time'], '2026-05-31T08:00:00.000');
    expect(local['end_time'], '2026-05-31T10:00:00.000');
    expect(local['status'], 'finished');
    expect(local['created_at'], '2026-05-31T08:00:00.000');
  });

  test('pull aceita backend sem farm_id', () {
    final local = VisitSyncService.fromSupabasePayload({
      'id': 'visit-legacy',
      'user_id': 'user-1',
      'producer_id': 'client-1',
      'area_id': 'field-1',
      'activity_type': 'Monitoramento',
      'start_time': '2026-05-31T08:00:00.000',
      'end_time': null,
      'updated_at': '2026-05-31T09:00:00.000',
    });

    expect(local['farm_id'], isNull);
    expect(local['area_id'], 'field-1');
    expect(local['status'], 'active');
  });
}
