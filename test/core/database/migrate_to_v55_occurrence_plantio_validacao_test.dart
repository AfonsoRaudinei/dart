import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const newColumns = ['data_validacao', 'avaliacao_emergencia'];

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

  test('migrateToV55 adiciona validação de emergência em occurrences', () async {
    final db = await openLegacyOccurrencesDb();

    for (final column in newColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'occurrences', column),
        isFalse,
      );
    }

    await DatabaseHelper.instance.runMigrationsForTesting(db, 54, 55);

    for (final column in newColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'occurrences', column),
        isTrue,
      );
    }

    await db.insert('occurrences', {
      'id': 'occ-v55',
      'type': 'Info',
      'description': 'emergência',
      'created_at': '2026-11-17T00:00:00.000',
      'updated_at': '2026-11-17T00:00:00.000',
      'data_validacao': '2026-11-17',
      'avaliacao_emergencia': 'boa',
    });

    final row = await db.query(
      'occurrences',
      where: 'id = ?',
      whereArgs: ['occ-v55'],
    );
    expect(row.single['data_validacao'], '2026-11-17');
    expect(row.single['avaliacao_emergencia'], 'boa');

    await DatabaseHelper.instance.runMigrationsForTesting(db, 54, 55);
    for (final column in newColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'occurrences', column),
        isTrue,
      );
    }

    await db.close();
  });

  test('migrateToV55 sem tabela occurrences não falha', () async {
    databaseFactory = databaseFactoryFfi;
    final db = await openDatabase(inMemoryDatabasePath);

    await DatabaseHelper.instance.runMigrationsForTesting(db, 54, 55);

    expect(await DatabaseSchemaUtils.tableExists(db, 'occurrences'), isFalse);
    await db.close();
  });
}