import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const tables = <String>[
    'carteira_tipos_produto',
    'carteira_categorias',
    'carteira_config',
    'carteira_safras',
    'carteira_metas',
    'carteira_cliente_categorias',
    'carteira_lancamentos',
  ];

  test('migrateToV42 cria colunas de sync nas tabelas carteira', () async {
    databaseFactory = databaseFactoryFfi;
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE carteira_tipos_produto (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            codigo TEXT NOT NULL,
            label TEXT NOT NULL,
            converte_sacas_ha INTEGER NOT NULL DEFAULT 0,
            sistema INTEGER NOT NULL DEFAULT 0,
            ativo INTEGER NOT NULL DEFAULT 1,
            ordem INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE carteira_categorias (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL DEFAULT '',
            nome TEXT NOT NULL,
            cor TEXT NOT NULL DEFAULT '#4ADE80',
            ativo INTEGER NOT NULL DEFAULT 1,
            ordem INTEGER NOT NULL DEFAULT 0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE carteira_config (
            user_id TEXT PRIMARY KEY,
            valor_grao REAL NOT NULL DEFAULT 0.0,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE carteira_safras (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL DEFAULT '',
            nome TEXT NOT NULL,
            data_inicio TEXT NOT NULL,
            data_fim TEXT NOT NULL,
            ativa INTEGER NOT NULL DEFAULT 1,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE carteira_metas (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL DEFAULT '',
            safra_id TEXT NOT NULL,
            categoria_id TEXT NOT NULL,
            quantidade REAL NOT NULL DEFAULT 0.0,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE carteira_cliente_categorias (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL DEFAULT '',
            cliente_id TEXT NOT NULL,
            categoria_id TEXT NOT NULL,
            percentual_fechado INTEGER NOT NULL DEFAULT 0,
            observacao TEXT,
            updated_at TEXT NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE carteira_lancamentos (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL DEFAULT '',
            safra_id TEXT NOT NULL,
            categoria_id TEXT NOT NULL,
            cliente_id TEXT NOT NULL,
            quantidade REAL NOT NULL,
            observacao TEXT,
            data_lancamento TEXT NOT NULL,
            created_at TEXT NOT NULL
          )
        ''');
      },
    );

    await db.insert('carteira_lancamentos', {
      'id': 'l1',
      'user_id': 'u1',
      'safra_id': 's1',
      'categoria_id': 'c1',
      'cliente_id': 'cl1',
      'quantidade': 4.0,
      'data_lancamento': '2026-08-22T10:00:00.000Z',
      'created_at': '2026-08-22T10:00:00.000Z',
    });

    final helper = DatabaseHelper.instance;
    await helper.runMigrationsForTesting(db, 41, 42);

    for (final table in tables) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, table, 'sync_status'),
        isTrue,
        reason: '$table.sync_status',
      );
      expect(
        await DatabaseSchemaUtils.columnExists(db, table, 'deleted_at'),
        isTrue,
        reason: '$table.deleted_at',
      );
    }

    expect(
      await DatabaseSchemaUtils.columnExists(
        db,
        'carteira_lancamentos',
        'updated_at',
      ),
      isTrue,
    );
    expect(
      await DatabaseSchemaUtils.columnExists(db, 'carteira_config', 'updated_at'),
      isTrue,
    );

    final rows = await db.query('carteira_lancamentos');
    expect(rows, hasLength(1));
    expect(rows.first['sync_status'], 'pending_sync');
    expect(rows.first['updated_at'], '2026-08-22T10:00:00.000Z');
    expect(rows.first['deleted_at'], isNull);

    await db.close();
  });
}
