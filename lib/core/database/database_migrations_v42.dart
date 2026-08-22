import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migração SQLite v42 — ADR-051: metadados de sync nas tabelas da carteira.
class DatabaseMigrationsV42 {
  DatabaseMigrationsV42._();

  static const tables = <String>[
    'carteira_tipos_produto',
    'carteira_categorias',
    'carteira_config',
    'carteira_safras',
    'carteira_metas',
    'carteira_cliente_categorias',
    'carteira_lancamentos',
  ];

  /// Adiciona `sync_status`, `deleted_at` e `updated_at` (onde faltar).
  ///
  /// Idempotente: [DatabaseSchemaUtils.columnExists] + ALTER.
  static Future<void> migrateToV42(Database db) async {
    for (final table in tables) {
      if (!await DatabaseSchemaUtils.tableExists(db, table)) {
        AppLogger.debug(
          'V42: tabela $table ausente — ignorado',
          tag: 'DB.Migration',
        );
        continue;
      }

      if (!await DatabaseSchemaUtils.columnExists(db, table, 'sync_status')) {
        await db.execute(
          "ALTER TABLE $table ADD COLUMN sync_status TEXT NOT NULL "
          "DEFAULT 'pending_sync'",
        );
      }

      if (!await DatabaseSchemaUtils.columnExists(db, table, 'deleted_at')) {
        await db.execute('ALTER TABLE $table ADD COLUMN deleted_at TEXT');
      }
    }

    if (await DatabaseSchemaUtils.tableExists(db, 'carteira_lancamentos') &&
        !await DatabaseSchemaUtils.columnExists(
          db,
          'carteira_lancamentos',
          'updated_at',
        )) {
      await db.execute(
        'ALTER TABLE carteira_lancamentos ADD COLUMN updated_at TEXT',
      );
      await db.execute(
        'UPDATE carteira_lancamentos '
        'SET updated_at = created_at WHERE updated_at IS NULL',
      );
    }

    if (await DatabaseSchemaUtils.tableExists(db, 'carteira_config') &&
        !await DatabaseSchemaUtils.columnExists(
          db,
          'carteira_config',
          'updated_at',
        )) {
      await db.execute(
        'ALTER TABLE carteira_config ADD COLUMN updated_at TEXT',
      );
    }

    AppLogger.debug(
      'V42: sync_status/deleted_at nas 7 tabelas carteira; '
      'updated_at em lancamentos/config se faltava.',
      tag: 'DB',
    );
  }
}
