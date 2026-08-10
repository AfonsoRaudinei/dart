import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/modules/consultoria/quick_photo/data/quick_photo_repository.dart';
import 'package:soloforte_app/modules/consultoria/quick_photo/data/services/quick_photo_client_id_backfill_service.dart';
import 'package:soloforte_app/modules/consultoria/quick_photo/domain/quick_photo_record.dart';

void main() {
  group('QuickPhotoClientIdBackfillService', () {
    test('preenche client_id via visit_session_id sem sobrescrever existente',
        () async {
      final repository = _FakeQuickPhotoRepository();
      final service = QuickPhotoClientIdBackfillService(
        repository: repository,
        visitLookup: _FakeVisitSessionLookup(),
      );

      final photos = [
        _photo(id: 'p1', visitSessionId: 'session-a'),
        _photo(id: 'p2', visitSessionId: 'session-b', clientId: 'cli-existing'),
      ];

      final result = await service.backfillIfNeeded(photos);

      expect(result[0].clientId, 'cli-a');
      expect(result[1].clientId, 'cli-existing');
      expect(repository.patchedIds, ['p1']);
    });

    test('sem visit_session_id permanece sem client_id', () async {
      final repository = _FakeQuickPhotoRepository();
      final service = QuickPhotoClientIdBackfillService(
        repository: repository,
        visitLookup: _FakeVisitSessionLookup(),
      );

      final result = await service.backfillIfNeeded([
        _photo(id: 'orphan'),
      ]);

      expect(result.single.clientId, isNull);
      expect(repository.patchedIds, isEmpty);
    });
  });

  group('QuickPhotoClientIdCoverage', () {
    test('calcula percentual', () {
      final coverage = QuickPhotoClientIdCoverage.audit(const [
        'cli-1',
        null,
        'cli-2',
      ]);
      expect(coverage.total, 3);
      expect(coverage.withClientId, 2);
      expect(coverage.withoutClientId, 1);
      expect(coverage.percentWithClientId, closeTo(66.7, 0.1));
    });
  });
}

QuickPhotoRecord _photo({
  required String id,
  String? visitSessionId,
  String? clientId,
}) {
  return QuickPhotoRecord(
    id: id,
    imagePath: '/$id.jpg',
    createdAt: DateTime.utc(2026, 6, 1),
    visitSessionId: visitSessionId,
    clientId: clientId,
  );
}

class _FakeVisitSessionLookup implements IVisitSessionLookup {
  @override
  Future<VisitSessionSummary?> findById(String sessionId) async {
    switch (sessionId) {
      case 'session-a':
        return VisitSessionSummary(
          id: sessionId,
          producerId: 'cli-a',
          status: 'finished',
          startTime: DateTime.utc(2026, 6, 1),
        );
      case 'session-b':
        return VisitSessionSummary(
          id: sessionId,
          producerId: 'cli-b',
          status: 'finished',
          startTime: DateTime.utc(2026, 6, 1),
        );
      default:
        return null;
    }
  }

  @override
  Future<VisitSessionSummary?> getActiveSession() async => null;
}

class _FakeQuickPhotoRepository implements IQuickPhotoClientIdPatcher {
  final patchedIds = <String>[];

  @override
  Future<QuickPhotoRecord?> patchClientIdIfMissing({
    required String photoId,
    required String clientId,
  }) async {
    patchedIds.add(photoId);
    return QuickPhotoRecord(
      id: photoId,
      imagePath: '/$photoId.jpg',
      createdAt: DateTime.utc(2026, 6, 1),
      visitSessionId: photoId == 'p1' ? 'session-a' : null,
      clientId: clientId,
    );
  }
}
