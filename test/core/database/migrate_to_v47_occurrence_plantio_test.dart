import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const plantioColumns = [
    'data_emergencia',
    'sementes_por_metro',
    'estande_plantas',
    'avaliacao_plantio',
    'objetivo_plantio',
  ];

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

  test('migrateToV47 adiciona colunas de plantio em occurrences', () async {
    final db = await openLegacyOccurrencesDb();

    for (final column in plantioColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'occurrences', column),
        isFalse,
      );
    }

    await DatabaseHelper.instance.runMigrationsForTesting(db, 46, 47);

    for (final column in plantioColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'occurrences', column),
        isTrue,
      );
    }

    await db.insert('occurrences', {
      'id': 'occ-legado',
      'type': 'Info',
      'description': 'linha anterior à v47',
      'created_at': '2026-11-01T00:00:00.000',
      'updated_at': '2026-11-01T00:00:00.000',
    });

    final rows = await db.query(
      'occurrences',
      where: 'id = ?',
      whereArgs: ['occ-legado'],
    );
    expect(rows, hasLength(1));
    for (final column in plantioColumns) {
      expect(rows.first[column], isNull);
    }

    await DatabaseHelper.instance.runMigrationsForTesting(db, 46, 47);
    for (final column in plantioColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'occurrences', column),
        isTrue,
      );
    }

    await db.close();
  });
}
