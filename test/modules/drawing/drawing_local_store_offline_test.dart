import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/modules/drawing/data/data_sources/drawing_local_store.dart';
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late Database db;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('drawing_store_test');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getApplicationDocumentsDirectory' ||
              call.method == 'getApplicationDocumentsPath') {
            return tempDir.path;
          }
          return tempDir.path;
        });
    try {
      Supabase.instance;
    } catch (_) {
      await Supabase.initialize(
        url: 'https://mock-supabase-for-tests.co',
        anonKey: 'mock-anon-key-1234567890abcdef',
      );
    }
    db = await DatabaseHelper.instance.database;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    DrawingLocalIdentityStore.resetEphemeralStateForTest();
    await db.delete('drawings');
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('desenha offline e relê depois com previsibilidade local', () async {
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    final store = DrawingLocalStore(
      identityStore: DrawingLocalIdentityStore(preferences: prefs),
    );
    final feature = _feature('drawing-offline-1');

    await store.insert(feature);

    final byId = await DrawingLocalStore(
      identityStore: DrawingLocalIdentityStore(preferences: prefs),
    ).getById('drawing-offline-1');
    final all = await store.getAll();

    expect(byId, isNotNull);
    expect(byId!.id, 'drawing-offline-1');
    expect(byId.properties.syncStatus, SyncStatus.local_only);
    expect(all.map((item) => item.id), contains('drawing-offline-1'));
  });

  test(
    'currentUser indisponível no bootstrap não gera perda silenciosa',
    () async {
      final prefs = PreferencesService(await SharedPreferences.getInstance());
      final store = DrawingLocalStore(
        identityStore: DrawingLocalIdentityStore(preferences: prefs),
      );
      final feature = _feature(
        'drawing-offline-2',
        syncStatus: SyncStatus.pending_sync,
      );

      await store.insert(feature);

      final raw = await db.query(
        'drawings',
        where: 'id = ?',
        whereArgs: ['drawing-offline-2'],
      );
      final reread = await store.getById('drawing-offline-2');

      expect(raw.single['user_id'], '');
      expect(raw.single['sync_status'], 'local_only');
      expect(reread, isNotNull);
      expect(reread!.properties.syncStatus, SyncStatus.local_only);
    },
  );
}

DrawingFeature _feature(
  String id, {
  SyncStatus syncStatus = SyncStatus.local_only,
}) {
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
      nome: 'Talhão $id',
      tipo: DrawingType.talhao,
      origem: DrawingOrigin.desenho_manual,
      status: DrawingStatus.rascunho,
      autorId: 'user-1',
      autorTipo: AuthorType.consultor,
      areaHa: 1.2,
      versao: 1,
      ativo: true,
      createdAt: DateTime.utc(2026, 7, 20, 12),
      updatedAt: DateTime.utc(2026, 7, 20, 12),
      syncStatus: syncStatus,
    ),
  );
}
