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
import 'package:soloforte_app/modules/drawing/domain/models/drawing_models.dart';
import 'package:soloforte_app/modules/drawing/domain/models/teste_execucao.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late Database db;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('teste_execucao_store_test');
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
    LocalSessionIdentity.resetForTesting();
    LocalSessionIdentity.remember('user-teste-exec-1');
    await db.delete('teste_execucoes');
  });

  tearDown(LocalSessionIdentity.resetForTesting);

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('insert e findByDrawingId retorna registro persistido', () async {
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    final store = TesteExecucaoLocalStore(
      identityStore: DrawingLocalIdentityStore(preferences: prefs),
    );
    final now = DateTime.utc(2026, 11, 21, 12);
    const drawingId = 'drawing-teste-99';

    await store.insert(
      TesteExecucao(
        id: 'te-1',
        drawingId: drawingId,
        userId: '',
        syncStatus: SyncStatus.pending_sync,
        talhao: 'Talhão Norte',
        implementacao: 'Herbicida X',
        fotoUrl: 'https://example.com/foto.jpg',
        criadoEm: now,
        atualizadoEm: now,
      ),
    );

    final rows = await store.findByDrawingId(drawingId);
    expect(rows, hasLength(1));
    expect(rows.first.id, 'te-1');
    expect(rows.first.drawingId, drawingId);
    expect(rows.first.talhao, 'Talhão Norte');
    expect(rows.first.implementacao, 'Herbicida X');
    expect(rows.first.syncStatus, SyncStatus.pending_sync);
  });
}