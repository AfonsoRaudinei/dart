import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/ndvi/data/datasources/ndvi_local_datasource.dart';
import 'package:soloforte_app/modules/ndvi/domain/entities/ndvi_image.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late Database db;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('ndvi_local_ds_test');
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

  setUp(LocalSessionIdentity.resetForTesting);

  tearDown(() async {
    LocalSessionIdentity.resetForTesting();
    await db.delete('ndvi_cache');
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('ndvi_cache isolado por user_id', () async {
    final datasource = NdviLocalDatasource();
    final image = NdviImage(
      id: 'ndvi-1',
      fieldId: 'field-a',
      imageDate: DateTime.utc(2026, 7, 1),
      ndviMin: 0.1,
      ndviMax: 0.8,
      ndviMean: 0.5,
      source: 'auto',
      fetchedAt: DateTime.utc(2026, 7, 1, 12),
      syncStatus: 0,
    );

    LocalSessionIdentity.remember('user-a');
    await datasource.save(image);
    expect(await datasource.getLatest('field-a'), isNotNull);

    LocalSessionIdentity.remember('user-b');
    expect(await datasource.getLatest('field-a'), isNull);
    expect(await datasource.getAll('field-a'), isEmpty);

    LocalSessionIdentity.remember('user-a');
    expect(await datasource.getLatest('field-a'), isNotNull);
  });
}
