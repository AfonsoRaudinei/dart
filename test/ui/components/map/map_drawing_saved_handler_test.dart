import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_visit_session_lookup.dart';
import 'package:soloforte_app/modules/drawing/domain/models/campo_test_photo_draft.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/ui/components/map/map_drawing_saved_handler.dart';

void main() {
  group('handleMapDrawingSaved', () {
  test('DrawingType.teste com draft não chama persistCampoTestPhoto', () {
    var persistCalls = 0;
    const draft = CampoTestPhotoDraft(
      localPath: '/tmp/photo.jpg',
      lat: -10.5,
      lng: -48.2,
    );
    handleMapDrawingSaved(
      feature: _feature(DrawingType.teste),
      campoTestPhoto: draft,
      session: null,
      onUpdateVisitArea: (_, {farmId}) async {},
      sessionLookup: _FakeSessionLookup(),
      persistCampoTestPhoto: ({required draft, required sessionLookup}) async {
        persistCalls++;
      },
    );
    expect(persistCalls, 0);
  });

  test('DrawingType.talhao com sessão sem areaId chama onUpdateVisitArea', () async {
    final completer = Completer<(String featureId, String? farmId)>();
    final session = VisitSessionSummary(
      id: 'sess-1',
      producerId: 'prod',
      status: 'active',
      startTime: _kStart,
      farmId: 'farm-from-session',
    );

    handleMapDrawingSaved(
      feature: _feature(DrawingType.talhao, fazendaId: 'farm-from-feature'),
      campoTestPhoto: null,
      session: session,
      onUpdateVisitArea: (featureId, {farmId}) async {
        completer.complete((featureId, farmId));
      },
      sessionLookup: _FakeSessionLookup(),
    );

    final result = await completer.future;
    expect(result.$1, 'feat-1');
    expect(result.$2, 'farm-from-feature');
  });
  });

  group('persistCampoTestPhotoFromDraft', () {
    test('storedPath null não chama SaveQuickPhoto', () async {
      var saveCalls = 0;

      await persistCampoTestPhotoFromDraft(
        draft: const CampoTestPhotoDraft(localPath: '/tmp/x.jpg'),
        sessionLookup: _FakeSessionLookup(),
        persistLocalCopy: (_) async => null,
        saveQuickPhoto: ({
          required bytes,
          required localPath,
          lat,
          lng,
        }) async {
          saveCalls++;
        },
      );

      expect(saveCalls, 0);
    });

    test('cópia ok propaga lat/lng para save', () async {
      Uint8List? savedBytes;
      String? savedPath;
      double? savedLat;
      double? savedLng;

      await persistCampoTestPhotoFromDraft(
        draft: const CampoTestPhotoDraft(
          localPath: '/tmp/x.jpg',
          lat: 1.5,
          lng: 2.5,
        ),
        sessionLookup: _FakeSessionLookup(),
        persistLocalCopy: (_) async => 'stored/photo.jpg',
        resolveLocalPath: (_) async => '/abs/photo.jpg',
        readFileBytes: (_) async => Uint8List.fromList([1, 2, 3]),
        saveQuickPhoto: ({
          required bytes,
          required localPath,
          lat,
          lng,
        }) async {
          savedBytes = bytes;
          savedPath = localPath;
          savedLat = lat;
          savedLng = lng;
        },
      );

      expect(savedBytes, Uint8List.fromList([1, 2, 3]));
      expect(savedPath, 'stored/photo.jpg');
      expect(savedLat, 1.5);
      expect(savedLng, 2.5);
    });
  });
}

final _kStart = DateTime.utc(2026, 1, 1);

DrawingFeature _feature(
  DrawingType tipo, {
  String? fazendaId,
}) {
  final now = DateTime.utc(2026, 11, 12);
  return DrawingFeature(
    id: 'feat-1',
    geometry: DrawingPolygon(
      coordinates: [
        [
          [0, 0],
          [1, 0],
          [1, 1],
          [0, 0],
        ],
      ],
    ),
    properties: DrawingProperties(
      nome: 'feat-1',
      tipo: tipo,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.aprovado,
      autorId: 'user',
      autorTipo: AuthorType.consultor,
      fazendaId: fazendaId,
      areaHa: 1,
      versao: 1,
      ativo: true,
      createdAt: now,
      updatedAt: now,
    ),
  );
}

class _FakeSessionLookup implements IVisitSessionLookup {
  @override
  Future<VisitSessionSummary?> getActiveSession() async => null;

  @override
  Future<VisitSessionSummary?> findById(String sessionId) async => null;

  @override
  Future<List<VisitSessionSummary>> listFinished() async => [];
}