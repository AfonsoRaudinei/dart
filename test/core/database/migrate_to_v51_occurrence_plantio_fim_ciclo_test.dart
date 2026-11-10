import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const newColumns = ['data_fim_plantio', 'ciclo_dias'];

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

  test('migrateToV51 adiciona término do plantio e ciclo em occurrences',
      () async {
    final db = await openLegacyOccurrencesDb();

    for (final column in newColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'occurrences', column),
        isFalse,
      );
    }

    await DatabaseHelper.instance.runMigrationsForTesting(db, 50, 51);

    for (final column in newColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'occurrences', column),
        isTrue,
      );
    }

    await db.insert('occurrences', {
      'id': 'occ-legado',
      'type': 'Info',
      'description': 'linha anterior à v51',
      'created_at': '2026-11-01T00:00:00.000',
      'updated_at': '2026-11-01T00:00:00.000',
    });
    await db.insert('occurrences', {
      'id': 'occ-v51',
      'type': 'Info',
      'description': 'plantio',
      'created_at': '2026-11-09T00:00:00.000',
      'updated_at': '2026-11-09T00:00:00.000',
      'data_fim_plantio': '2026-10-30',
      'ciclo_dias': 115,
    });

    final legado = await db.query(
      'occurrences',
      where: 'id = ?',
      whereArgs: ['occ-legado'],
    );
    for (final column in newColumns) {
      expect(legado.single[column], isNull);
    }
    final novo = await db.query(
      'occurrences',
      where: 'id = ?',
      whereArgs: ['occ-v51'],
    );
    expect(novo.single['data_fim_plantio'], '2026-10-30');
    expect(novo.single['ciclo_dias'], 115);

    await DatabaseHelper.instance.runMigrationsForTesting(db, 50, 51);
    for (final column in newColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'occurrences', column),
        isTrue,
      );
    }

    await db.close();
  });

  test('migrateToV51 sem tabela occurrences não falha', () async {
    databaseFactory = databaseFactoryFfi;
    final db = await openDatabase(inMemoryDatabasePath);

    await DatabaseHelper.instance.runMigrationsForTesting(db, 50, 51);

    expect(await DatabaseSchemaUtils.tableExists(db, 'occurrences'), isFalse);
    await db.close();
  });
}
