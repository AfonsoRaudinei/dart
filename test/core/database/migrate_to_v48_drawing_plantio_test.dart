import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const plantioColumns = ['data_plantio', 'data_emergencia', 'ciclo_dias'];

  Future<Database> openLegacyDrawingsDb() {
    databaseFactory = databaseFactoryFfi;
    return openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE drawings (
            id TEXT PRIMARY KEY,
            nome TEXT NOT NULL
          )
        ''');
      },
    );
  }

  test('migrateToV48 adiciona colunas de plantio em drawings', () async {
    final db = await openLegacyDrawingsDb();

    for (final column in plantioColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'drawings', column),
        isFalse,
      );
    }

    await DatabaseHelper.instance.runMigrationsForTesting(db, 47, 48);

    for (final column in plantioColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'drawings', column),
        isTrue,
      );
    }

    await db.insert('drawings', {
      'id': 'draw-legado',
      'nome': 'linha anterior à v48',
    });

    final rows = await db.query(
      'drawings',
      where: 'id = ?',
      whereArgs: ['draw-legado'],
    );
    expect(rows, hasLength(1));
    for (final column in plantioColumns) {
      expect(rows.first[column], isNull);
    }

    await DatabaseHelper.instance.runMigrationsForTesting(db, 47, 48);
    for (final column in plantioColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'drawings', column),
        isTrue,
      );
    }

    await db.close();
  });
}
