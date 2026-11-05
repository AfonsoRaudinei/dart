import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const amostraColumns = [
    'amostra_codigo',
    'amostra_coletor',
    'amostra_tramite',
    'amostra_laudo_texto',
    'amostra_analises_json',
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

  test('migrateToV49 adiciona colunas de amostra em occurrences', () async {
    final db = await openLegacyOccurrencesDb();

    for (final column in amostraColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'occurrences', column),
        isFalse,
      );
    }

    await DatabaseHelper.instance.runMigrationsForTesting(db, 48, 49);

    for (final column in amostraColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'occurrences', column),
        isTrue,
      );
    }

    await db.insert('occurrences', {
      'id': 'occ-legado-v49',
      'type': 'Info',
      'description': 'linha anterior à v49',
      'created_at': '2026-11-05T00:00:00.000',
      'updated_at': '2026-11-05T00:00:00.000',
    });

    final rows = await db.query(
      'occurrences',
      where: 'id = ?',
      whereArgs: ['occ-legado-v49'],
    );
    expect(rows, hasLength(1));
    for (final column in amostraColumns) {
      expect(rows.first[column], isNull);
    }

    await db.close();
  });
}
