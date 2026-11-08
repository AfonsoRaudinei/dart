import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('migrateToV50 adiciona cor em drawings', () async {
    databaseFactory = databaseFactoryFfi;
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE drawings (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL DEFAULT '',
            nome TEXT NOT NULL
          )
        ''');
      },
    );

    expect(
      await DatabaseSchemaUtils.columnExists(db, 'drawings', 'cor'),
      isFalse,
    );

    await DatabaseHelper.instance.runMigrationsForTesting(db, 49, 50);

    expect(
      await DatabaseSchemaUtils.columnExists(db, 'drawings', 'cor'),
      isTrue,
    );
    await db.close();
  });
}
