import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/visitas/data/repositories/visit_repository.dart';
import 'package:soloforte_app/modules/visitas/domain/models/visit_session.dart';
import 'package:soloforte_app/modules/visitas/infra/visit_session_lookup_adapter.dart';

class FakeVisitRepository extends VisitRepository {
  VisitSession? activeSession;

  @override
  Future<VisitSession?> getActiveSession() async {
    return activeSession;
  }
}

void main() {
  group('VisitSessionLookupAdapter', () {
    test('retorna null quando não há sessão ativa', () async {
      final repo = FakeVisitRepository();
      final adapter = VisitSessionLookupAdapter(repo);

      final result = await adapter.getActiveSession();

      expect(result, isNull);
    });

    test('mapeia sessão ativa para summary', () async {
      final repo = FakeVisitRepository();
      repo.activeSession = VisitSession(
        id: 'session-1',
        producerId: 'producer-1',
        farmId: 'farm-1',
        areaId: 'field-1',
        activityType: 'Monitoramento',
        startTime: DateTime(2026, 3, 8, 9),
        initialLat: -15.0,
        initialLong: -47.0,
        status: 'active',
        createdAt: DateTime(2026, 3, 8, 9),
        updatedAt: DateTime(2026, 3, 8, 9),
      );

      final adapter = VisitSessionLookupAdapter(repo);
      final result = await adapter.getActiveSession();

      expect(result, isNotNull);
      expect(result!.id, 'session-1');
      expect(result.farmId, 'farm-1');
      expect(result.status, 'active');
      expect(result.isActive, isTrue);
    });
  });
}
