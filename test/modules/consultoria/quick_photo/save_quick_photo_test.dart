import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/modules/consultoria/quick_photo/data/quick_photo_repository.dart';
import 'package:soloforte_app/modules/consultoria/quick_photo/domain/quick_photo_record.dart';
import 'package:soloforte_app/modules/consultoria/quick_photo/domain/save_quick_photo.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeVisitSessionLookup implements IVisitSessionLookup {
  VisitSessionSummary? session;

  @override
  Future<VisitSessionSummary?> getActiveSession() async => session;

  @override
  Future<VisitSessionSummary?> findById(String sessionId) async {
    final active = await getActiveSession();
    if (active != null && active.id == sessionId) return active;
    return null;
  }
}

class _FakeQuickPhotoRepository extends QuickPhotoRepository {
  QuickPhotoRecord? lastSaved;
  String? capturedVisitSessionId;
  int uploadCalls = 0;

  _FakeQuickPhotoRepository()
      : super(
          supabase: SupabaseClient(
            'https://example.supabase.co',
            'anon-key',
          ),
        );

  @override
  Future<QuickPhotoRecord> uploadAndInsert({
    required Uint8List bytes,
    required String localPath,
    double? lat,
    double? lng,
    String? visitSessionId,
    QuickPhotoType type = QuickPhotoType.normal,
  }) async {
    uploadCalls += 1;
    capturedVisitSessionId = visitSessionId;
    lastSaved = QuickPhotoRecord(
      id: 'photo-1',
      imagePath: localPath,
      latitude: lat,
      longitude: lng,
      createdAt: DateTime.utc(2026, 8, 17),
      visitSessionId: visitSessionId,
      type: type.value,
    );
    return lastSaved!;
  }
}

void main() {
  late FakeVisitSessionLookup lookup;
  late _FakeQuickPhotoRepository repository;
  late SaveQuickPhoto useCase;

  setUp(() {
    lookup = FakeVisitSessionLookup();
    repository = _FakeQuickPhotoRepository();
    useCase = SaveQuickPhoto(repository, lookup);
  });

  final bytes = Uint8List.fromList([1, 2, 3]);

  test(
    'salva foto com visitSessionId quando sessão ativa existe',
    () async {
      lookup.session = VisitSessionSummary(
        id: 'session-abc-123',
        producerId: 'producer-1',
        status: 'active',
        startTime: DateTime.utc(2026, 8, 17),
      );

      final saved = await useCase.execute(
        bytes: bytes,
        localPath: '/tmp/foto.jpg',
      );

      expect(saved.visitSessionId, 'session-abc-123');
      expect(repository.capturedVisitSessionId, 'session-abc-123');
      expect(repository.uploadCalls, 1);
    },
  );

  test(
    'salva foto sem bloquear quando não há sessão ativa',
    () async {
      lookup.session = null;

      final saved = await useCase.execute(
        bytes: bytes,
        localPath: '/tmp/foto.jpg',
      );

      expect(saved.visitSessionId, isNull);
      expect(repository.capturedVisitSessionId, isNull);
      expect(repository.uploadCalls, 1);
    },
  );
}
