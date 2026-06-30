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
  test('push preserva contexto completo da visita', () {
    final payload = VisitSyncService.toSupabasePayload(_session(), 'user-1');

    expect(payload['user_id'], 'user-1');
    expect(payload['producer_id'], 'client-1');
    expect(payload['farm_id'], 'farm-1');
    expect(payload['area_id'], 'field-1');
    expect(payload['activity_type'], 'Monitoramento');
  });

  test('pull restaura contexto completo da visita', () {
    final local = VisitSyncService.fromSupabasePayload({
      'id': 'visit-1',
      'user_id': 'user-1',
      'producer_id': 'client-1',
      'farm_id': 'farm-1',
      'area_id': 'field-1',
      'activity_type': 'Monitoramento',
      'started_at': '2026-05-31T08:00:00.000',
      'ended_at': null,
      'updated_at': '2026-05-31T09:00:00.000',
    });

    expect(local['user_id'], 'user-1');
    expect(local['producer_id'], 'client-1');
    expect(local['farm_id'], 'farm-1');
    expect(local['area_id'], 'field-1');
    expect(local['activity_type'], 'Monitoramento');
    expect(local['status'], 'active');
  });

  test('pull aceita backend legado sem farm_id', () {
    final local = VisitSyncService.fromSupabasePayload({
      'id': 'visit-legacy',
      'user_id': 'user-1',
      'producer_id': 'client-1',
      'area_id': 'field-1',
      'activity_type': 'Monitoramento',
      'started_at': '2026-05-31T08:00:00.000',
      'ended_at': null,
      'updated_at': '2026-05-31T09:00:00.000',
    });

    expect(local['farm_id'], isNull);
    expect(local['area_id'], 'field-1');
  });
}
