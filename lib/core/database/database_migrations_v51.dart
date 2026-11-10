import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migração SQLite v51 — término do plantio e ciclo em `occurrences` (ADR-058).
class DatabaseMigrationsV51 {
  DatabaseMigrationsV51._();

  static const _columns = <String, String>{
    'data_fim_plantio': 'TEXT',
    'ciclo_dias': 'INTEGER',
  };

  /// Adiciona colunas nullable em `occurrences`. Idempotente.
  static Future<void> migrateToV51(Database db) async {
    if (!await DatabaseSchemaUtils.tableExists(db, 'occurrences')) {
      AppLogger.debug(
        'V51: tabela occurrences ausente — ignorado',
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
          'V51: coluna ${entry.key} adicionada em occurrences',
          tag: 'DB',
        );
      } else {
        AppLogger.debug(
          'V51: coluna ${entry.key} já existe em occurrences',
          tag: 'DB.Migration',
        );
      }
    }
  }
}
