import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_local_store.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_remote_store.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_sync_service.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://mock-supabase-for-tests.co',
        anonKey: 'mock-anon-key-1234567890abcdef',
      );
    }
  });

  test(
    'DrawingSyncService retorna erro recuperavel quando pull remoto falha',
    () async {
      final service = DrawingSyncService(
        localStore: _FakeDrawingLocalStore(),
        remoteStore: _FailingDrawingRemoteStore(),
      );

      final result = await service.synchronize();

      expect(result.errors, 1);
      expect(result.updated, isEmpty);
      expect(result.conflicts, isEmpty);
    },
  );

  test(
    'DrawingSyncService preserva pendencia local quando push falha por rede',
    () async {
      final pendingFeature = DrawingFeature(
        id: 'drawing-pending-1',
        geometry: DrawingPolygon(
          coordinates: [
            [
              [-48.0, -10.0],
              [-47.99, -10.0],
              [-47.99, -9.99],
              [-48.0, -10.0],
            ],
          ],
        ),
        properties: DrawingProperties(
          nome: 'Talhão pendente',
          tipo: DrawingType.talhao,
          origem: DrawingOrigin.desenho_manual,
          status: DrawingStatus.rascunho,
          autorId: 'user-1',
          autorTipo: AuthorType.consultor,
          areaHa: 1.2,
          versao: 1,
          ativo: true,
          syncStatus: SyncStatus.pending_sync,
          createdAt: DateTime.utc(2026, 7, 20, 12),
          updatedAt: DateTime.utc(2026, 7, 20, 12),
        ),
      );
      final localStore = _CapturingDrawingLocalStore(pending: [pendingFeature]);
      final service = DrawingSyncService(
        localStore: localStore,
        remoteStore: _PushFailingDrawingRemoteStore(),
      );

      final result = await service.synchronize();

      expect(result.errors, 1);
      expect(result.updated, isEmpty);
      expect(result.conflicts, isEmpty);
      expect(localStore.updated, isEmpty);
    },
  );
}

class _FakeDrawingLocalStore extends DrawingLocalStore {
  @override
  Future<List<DrawingFeature>> getPendingSync() async => const [];
}

class _CapturingDrawingLocalStore extends DrawingLocalStore {
  _CapturingDrawingLocalStore({required List<DrawingFeature> pending})
    : _pending = pending;

  final List<DrawingFeature> _pending;
  final List<DrawingFeature> updated = [];

  @override
  Future<List<DrawingFeature>> getPendingSync() async => _pending;

  @override
  Future<void> update(DrawingFeature feature) async {
    updated.add(feature);
  }
}

class _FailingDrawingRemoteStore extends DrawingRemoteStore {
  @override
  Future<List<DrawingFeature>> fetchUpdates(DateTime? lastSync) {
    throw StateError('auth not ready');
  }
}

class _PushFailingDrawingRemoteStore extends DrawingRemoteStore {
  @override
  Future<void> push(DrawingFeature feature) async {
    throw TimeoutException('offline');
  }

  @override
  Future<List<DrawingFeature>> fetchUpdates(DateTime? lastSync) async =>
      const [];
}
