import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  Future<Database> openLegacyOccurrencesDb() {
    databaseFactory = databaseFactoryFfi;
    return openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE occurrences (
            id TEXT PRIMARY KEY,
            type TEXT NOT NULL,
            description TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  test('migrateToV49 adiciona field_id nullable em occurrences', () async {
    final db = await openLegacyOccurrencesDb();

    expect(
      await DatabaseSchemaUtils.columnExists(db, 'occurrences', 'field_id'),
      isFalse,
    );

    await DatabaseHelper.instance.runMigrationsForTesting(db, 48, 49);

    expect(
      await DatabaseSchemaUtils.columnExists(db, 'occurrences', 'field_id'),
      isTrue,
    );

    await db.insert('occurrences', {
      'id': 'occ-legado',
      'type': 'Info',
      'description': 'linha anterior à v49',
      'created_at': '2026-11-01T00:00:00.000',
      'updated_at': '2026-11-01T00:00:00.000',
    });

    final rows = await db.query(
      'occurrences',
      where: 'id = ?',
      whereArgs: ['occ-legado'],
    );
    expect(rows, hasLength(1));
    expect(rows.first['field_id'], isNull);

    await DatabaseHelper.instance.runMigrationsForTesting(db, 48, 49);
    expect(
      await DatabaseSchemaUtils.columnExists(db, 'occurrences', 'field_id'),
      isTrue,
    );

    await db.close();
  });
}
