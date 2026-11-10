import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migração SQLite v52 — cultura e safra em `occurrences` (ADR-059).
class DatabaseMigrationsV52 {
  DatabaseMigrationsV52._();

  static const _columns = <String, String>{
    'cultura': 'TEXT',
    'safra': 'TEXT',
  };

  /// Adiciona colunas nullable em `occurrences`. Idempotente.
  static Future<void> migrateToV52(Database db) async {
    if (!await DatabaseSchemaUtils.tableExists(db, 'occurrences')) {
      AppLogger.debug(
        'V52: tabela occurrences ausente — ignorado',
        tag: 'DB.Migration',
      );
      return;
    }

    for (final entry in _columns.entries) {
      if (!await DatabaseSchemaUtils.columnExists(
        db,
        'occurrences',
        entry.key,
      )) {
        await db.execute(
          'ALTER TABLE occurrences ADD COLUMN ${entry.key} ${entry.value}',
        );
        AppLogger.debug(
          'V52: coluna ${entry.key} adicionada em occurrences',
          tag: 'DB',
        );
      } else {
        AppLogger.debug(
          'V52: coluna ${entry.key} já existe em occurrences',
          tag: 'DB.Migration',
        );
      }
    }
  }
}
