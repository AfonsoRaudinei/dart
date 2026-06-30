import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('upgrade v1 to v5 does not fail on duplicate fields sync_status', () async {
    final dbPath = p.join(Directory.systemTemp.path, 'soloforte_migration_test.db');
    final file = File(dbPath);
    if (file.existsSync()) {
      file.deleteSync();
    }

    // Simula schema v1 (sem sync_status em fields)
    final dbV1 = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clients (
            id TEXT PRIMARY KEY,
            nome TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE farms (
            id TEXT PRIMARY KEY,
            cliente_id TEXT NOT NULL,
            nome TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE fields (
            id TEXT PRIMARY KEY,
            fazenda_id TEXT NOT NULL,
            nome TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
    await dbV1.close();

    // Replica lógica de upgrade corrigida (oldVersion < 2 sem duplicata)
    final db = await openDatabase(
      dbPath,
      version: 5,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE clients ADD COLUMN sync_status INTEGER DEFAULT 1',
          );
          await db.execute(
            'ALTER TABLE farms ADD COLUMN sync_status INTEGER DEFAULT 1',
          );
          await db.execute(
            'ALTER TABLE fields ADD COLUMN sync_status INTEGER DEFAULT 1',
          );
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE visit_sessions (
              id TEXT PRIMARY KEY,
              producer_id TEXT NOT NULL,
              area_id TEXT NOT NULL,
              activity_type TEXT NOT NULL,
              start_time TEXT NOT NULL,
              status TEXT NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        }
      },
    );

    final columns = await db.rawQuery('PRAGMA table_info(fields)');
    final syncColumns =
        columns.where((c) => c['name'] == 'sync_status').toList();
    expect(syncColumns.length, 1);

    await db.close();
    if (file.existsSync()) {
      file.deleteSync();
    }
  });
}
