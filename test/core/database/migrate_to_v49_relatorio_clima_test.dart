import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  Future<Database> openLegacyRelatoriosDb() {
    databaseFactory = databaseFactoryFfi;
    return openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE relatorios (
            id TEXT PRIMARY KEY,
            visit_session_id TEXT NOT NULL
          )
        ''');
      },
    );
  }

  test('migrateToV49 adiciona clima_manual_json em relatorios', () async {
    final db = await openLegacyRelatoriosDb();
    expect(
      await DatabaseSchemaUtils.columnExists(db, 'relatorios', 'clima_manual_json'),
      isFalse,
    );

    await DatabaseHelper.instance.runMigrationsForTesting(db, 48, 49);

    expect(
      await DatabaseSchemaUtils.columnExists(db, 'relatorios', 'clima_manual_json'),
      isTrue,
    );

    await DatabaseHelper.instance.runMigrationsForTesting(db, 48, 49);
    expect(
      await DatabaseSchemaUtils.columnExists(db, 'relatorios', 'clima_manual_json'),
      isTrue,
    );

    await db.close();
  });
}
