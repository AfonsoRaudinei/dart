import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('migrateToV43 adiciona material em drawings', () async {
    databaseFactory = databaseFactoryFfi;
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE drawings (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL DEFAULT '',
            nome TEXT NOT NULL,
            tipo TEXT NOT NULL,
            origem TEXT NOT NULL,
            status TEXT NOT NULL,
            geojson TEXT NOT NULL,
            area_ha REAL,
            autor_id TEXT NOT NULL,
            autor_tipo TEXT NOT NULL,
            sync_status TEXT NOT NULL,
            versao INTEGER,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL,
            ativo INTEGER DEFAULT 1
          )
        ''');
      },
    );

    expect(
      await DatabaseSchemaUtils.columnExists(db, 'drawings', 'material'),
      isFalse,
    );

    await DatabaseHelper.instance.runMigrationsForTesting(db, 42, 43);

    expect(
      await DatabaseSchemaUtils.columnExists(db, 'drawings', 'material'),
      isTrue,
    );
    await db.close();
  });
}
