import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/data/occurrence_repository.dart';
import 'package:soloforte_app/modules/consultoria/occurrences/domain/occurrence.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Directory tempDir;
  late Database db;
  const channel = MethodChannel('plugins.flutter.io/path_provider');

  setUpAll(() async {
    databaseFactory = databaseFactoryFfi;
    SharedPreferences.setMockInitialValues({});
    tempDir = await Directory.systemTemp.createTemp('occurrence_repo_test');
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

  tearDown(() async {
    await db.delete('occurrences');
  });

  tearDownAll(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  test(
    'cria ocorrência offline e relê depois mesmo sem currentUser hidratado',
    () async {
      final repository = OccurrenceRepository();
      final occurrence = Occurrence(
        id: 'occ-offline-1',
        visitSessionId: 'session-1',
        type: 'Info',
        description: 'Ocorrência criada offline',
        createdAt: DateTime.utc(2026, 7, 20, 12),
      );

      await repository.saveOccurrence(occurrence);

      final reread = await OccurrenceRepository().getOccurrencesBySession(
        'session-1',
      );

      expect(reread, hasLength(1));
      expect(reread.single.id, 'occ-offline-1');
      expect(reread.single.syncStatus, 'local_only');
      expect(reread.single.ownerUserId, '');
    },
  );

  test(
    'bootstrap sem currentUser não causa perda silenciosa em releitura global',
    () async {
      final repository = OccurrenceRepository();
      final occurrence = Occurrence(
        id: 'occ-offline-2',
        type: 'Info',
        description: 'Permanece local',
        createdAt: DateTime.utc(2026, 7, 20, 12),
      );

      await repository.saveOccurrence(occurrence);

      final all = await OccurrenceRepository().getAllOccurrences();
      final raw = await db.query(
        'occurrences',
        where: 'id = ?',
        whereArgs: ['occ-offline-2'],
      );

      expect(all.map((item) => item.id), contains('occ-offline-2'));
      expect(raw.single['user_id'], '');
      expect(raw.single['sync_status'], 'local_only');
    },
  );
}
