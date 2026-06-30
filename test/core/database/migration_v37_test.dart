import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  sqfliteFfiInit();

  setUpAll(() {
    databaseFactory = databaseFactoryFfi;
  });

  test('migra v35 para v38 preservando tabela legada de relatórios', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await db.execute('''
      CREATE TABLE relatorios_v2 (
        id TEXT PRIMARY KEY,
        titulo TEXT NOT NULL,
        descricao TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        created_by TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        deleted_at TEXT,
        visit_session_id TEXT,
        occurrence_ids TEXT
      )
    ''');
    await db.insert('relatorios_v2', {
      'id': 'report-legacy',
      'titulo': 'Legado',
      'descricao': '',
      'created_at': '2026-06-01T00:00:00.000Z',
      'updated_at': '2026-06-01T00:00:00.000Z',
      'created_by': 'user-1',
      'sync_status': 'synced',
    });

    await db.execute('''
      CREATE TABLE occurrences (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        client_id TEXT
      )
    ''');

    await DatabaseHelper.instance.runMigrationsForTesting(db, 35, 38);

    final reportColumns = await db.rawQuery('PRAGMA table_info(relatorios_v2)');
    final reportColumnNames = reportColumns
        .map((column) => column['name'])
        .toSet();
    expect(reportColumnNames, containsAll(<Object?>['client_id', 'user_id']));

    final links = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name = 'producer_client_links'",
    );
    expect(links, isNotEmpty);

    final legacy = await db.query(
      'relatorios_v2',
      where: 'id = ?',
      whereArgs: ['report-legacy'],
    );
    expect(legacy.single['titulo'], 'Legado');
    expect(legacy.single['user_id'], '');

    final occurrenceColumns = await db.rawQuery(
      'PRAGMA table_info(occurrences)',
    );
    expect(
      occurrenceColumns.map((column) => column['name']),
      containsAll(<Object?>[
        'remote_id',
        'cached_by_user_id',
        'external_source',
        'external_analysis_id',
        'analysis_payload_json',
        'deleted_at',
      ]),
    );
  });

  test('instalação limpa até v38 cria tabelas e colunas finais', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);

    await DatabaseHelper.instance.runMigrationsForTesting(db, 0, 38);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table'",
    );
    final tableNames = tables.map((table) => table['name']).toSet();
    expect(
      tableNames,
      containsAll(<Object?>['producer_client_links', 'relatorios_v2']),
    );

    final columns = await db.rawQuery('PRAGMA table_info(relatorios_v2)');
    final columnNames = columns.map((column) => column['name']).toSet();
    expect(columnNames, containsAll(<Object?>['client_id', 'user_id']));
  });
}
