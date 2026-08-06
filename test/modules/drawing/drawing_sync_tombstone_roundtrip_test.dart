import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_local_store.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_remote_store.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_sync_service.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('drawing_roundtrip_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => tempDir.path);
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://mock-supabase-for-tests.co',
        anonKey: 'mock-anon-key-1234567890abcdef',
      );
    }
    await DatabaseHelper.instance.database;
  });

  setUp(() async {
    LocalSessionIdentity.resetForTesting();
    LocalSessionIdentity.remember('user-drawing-sync');
    DrawingLocalIdentityStore.resetEphemeralStateForTest();
    final db = await DatabaseHelper.instance.database;
    await db.delete('drawings');
  });

  tearDown(LocalSessionIdentity.resetForTesting);

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'delete → push tombstone → pull remoto não ressuscita drawing local',
    () async {
      final prefs = PreferencesService(await SharedPreferences.getInstance());
      final localStore = DrawingLocalStore(
        identityStore: DrawingLocalIdentityStore(preferences: prefs),
      );
      final remoteStore = _RoundTripDrawingRemoteStore();
      final service = DrawingSyncService(
        localStore: localStore,
        remoteStore: remoteStore,
      );

      final feature = _syncedFeature('drawing-roundtrip-1');
      await localStore.insert(feature);
      await localStore.delete('drawing-roundtrip-1');

      final pushResult = await service.synchronize();
      expect(pushResult.errors, 0);
      expect(remoteStore.pushed, hasLength(1));
      expect(remoteStore.pushed.single.properties.ativo, isFalse);

      remoteStore.pullQueue = [
        DrawingFeature(
          id: feature.id,
          geometry: feature.geometry,
          properties: feature.properties.copyWith(
            ativo: false,
            syncStatus: SyncStatus.synced,
            updatedAt: DateTime.utc(2026, 8, 6, 13),
          ),
        ),
      ];

      final pullResult = await service.synchronize();
      expect(pullResult.errors, 0);
      expect(await localStore.getAll(), isEmpty);
      expect(await localStore.getById('drawing-roundtrip-1'), isNull);
    },
  );
}

DrawingFeature _syncedFeature(String id) {
  return DrawingFeature(
    id: id,
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
      nome: 'Talhão roundtrip',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'user-drawing-sync',
      autorTipo: AuthorType.consultor,
      areaHa: 2.5,
      versao: 1,
      ativo: true,
      syncStatus: SyncStatus.synced,
      createdAt: DateTime.utc(2026, 8, 6, 10),
      updatedAt: DateTime.utc(2026, 8, 6, 10),
    ),
  );
}

class _RoundTripDrawingRemoteStore extends DrawingRemoteStore {
  final List<DrawingFeature> pushed = [];
  List<DrawingFeature> pullQueue = const [];

  @override
  Future<void> push(DrawingFeature feature) async {
    pushed.add(feature);
  }

  @override
  Future<List<DrawingFeature>> fetchUpdates(DateTime? lastSync) async {
    return pullQueue;
  }
}
