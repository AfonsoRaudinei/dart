import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late Database db;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('repair_orphan_test');
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
    db = await DatabaseHelper.instance.database;
  });

  setUp(() async {
    LocalSessionIdentity.resetForTesting();
    await db.delete('clients');
  });

  tearDown(LocalSessionIdentity.resetForTesting);

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test('repairOrphanUserIds atribui órfãos quando não há outro usuário', () async {
    await db.insert('clients', {
      'id': 'cli-orphan-1',
      'user_id': '',
      'nome': 'Orfão',
      'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
      'updated_at': DateTime.utc(2026, 1, 1).toIso8601String(),
      'sync_status': 1,
    });

    await DatabaseHelper.instance.repairOrphanUserIds('user-b');

    final row = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: ['cli-orphan-1'],
    );
    expect(row.single['user_id'], 'user-b');
  });

  test(
    'repairOrphanUserIds ignora órfãos quando há dados de outro usuário',
    () async {
      await db.insert('clients', {
        'id': 'cli-user-a',
        'user_id': 'user-a',
        'nome': 'Cliente A',
        'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'updated_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'sync_status': 1,
      });
      await db.insert('clients', {
        'id': 'cli-orphan-2',
        'user_id': '',
        'nome': 'Orfão compartilhado',
        'created_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'updated_at': DateTime.utc(2026, 1, 1).toIso8601String(),
        'sync_status': 1,
      });

      await DatabaseHelper.instance.repairOrphanUserIds('user-b');

      final orphan = await db.query(
        'clients',
        where: 'id = ?',
        whereArgs: ['cli-orphan-2'],
      );
      expect(orphan.single['user_id'], '');
    },
  );
}
