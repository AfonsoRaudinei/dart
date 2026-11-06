import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const occurrenceColumns = [
    'andamento',
    'responsavel_nome',
    'audio_path',
    'audio_duration_sec',
    'amostra_codigo',
    'amostra_coletor',
    'amostra_tramite',
    'amostra_laudo_texto',
    'amostra_analises_json',
    'field_id',
    'recomendacao_acao',
    'recomendacao_dose',
    'recomendacao_quando',
  ];
  const relatorioColumns = ['clima_manual_json'];
  const visitSessionColumns = ['route_stops_json', 'route_current_index'];

  Future<Database> openLegacyDb({bool withAllTables = true}) {
    databaseFactory = databaseFactoryFfi;
    return openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE occurrences (
            id TEXT PRIMARY KEY,
            description TEXT
          )
        ''');
        if (!withAllTables) return;
        await db.execute('''
          CREATE TABLE relatorios (
            id TEXT PRIMARY KEY
          )
        ''');
        await db.execute('''
          CREATE TABLE visit_sessions (
            id TEXT PRIMARY KEY
          )
        ''');
      },
    );
  }

  Future<void> expectColumns(
    Database db,
    String table,
    List<String> columns,
  ) async {
    for (final column in columns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, table, column),
        isTrue,
        reason: '$table.$column',
      );
    }
  }

  test('migrateToV49 adiciona colunas, backfill de andamento e índice',
      () async {
    final db = await openLegacyDb();
    await db.insert('occurrences', {'id': 'occ-legado', 'description': 'x'});

    await DatabaseHelper.instance.runMigrationsForTesting(db, 48, 49);

    await expectColumns(db, 'occurrences', occurrenceColumns);
    await expectColumns(db, 'relatorios', relatorioColumns);
    await expectColumns(db, 'visit_sessions', visitSessionColumns);

    final rows = await db.query(
      'occurrences',
      where: 'id = ?',
      whereArgs: ['occ-legado'],
    );
    expect(rows.single['andamento'], 'aberta');

    final index = await db.query(
      'sqlite_master',
      where: 'type = ? AND name = ?',
      whereArgs: ['index', 'idx_occurrences_field_id'],
    );
    expect(index, hasLength(1));

    await db.close();
  });

  test('migrateToV49 é idempotente', () async {
    final db = await openLegacyDb();

    await DatabaseHelper.instance.runMigrationsForTesting(db, 48, 49);
    await DatabaseHelper.instance.runMigrationsForTesting(db, 48, 49);

    await expectColumns(db, 'occurrences', occurrenceColumns);
    await expectColumns(db, 'relatorios', relatorioColumns);
    await expectColumns(db, 'visit_sessions', visitSessionColumns);

    await db.close();
  });

  test('migrateToV49 ignora relatorios e visit_sessions ausentes', () async {
    final db = await openLegacyDb(withAllTables: false);

    await DatabaseHelper.instance.runMigrationsForTesting(db, 48, 49);

    await expectColumns(db, 'occurrences', occurrenceColumns);
    expect(await DatabaseSchemaUtils.tableExists(db, 'relatorios'), isFalse);
    expect(
      await DatabaseSchemaUtils.tableExists(db, 'visit_sessions'),
      isFalse,
    );

    await db.close();
  });
}
