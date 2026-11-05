import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migração SQLite v47 — campos de plantio em `occurrences`.
class DatabaseMigrationsV47 {
  DatabaseMigrationsV47._();

  static const _columns = <String, String>{
    'data_emergencia': 'TEXT',
    'sementes_por_metro': 'REAL',
    'estande_plantas': 'INTEGER',
    'avaliacao_plantio': 'TEXT',
    'objetivo_plantio': 'TEXT',
  };

  /// Adiciona colunas nullable de plantio em `occurrences`. Idempotente.
  static Future<void> migrateToV47(Database db) async {
    if (!await DatabaseSchemaUtils.tableExists(db, 'occurrences')) {
      AppLogger.debug(
        'V47: tabela occurrences ausente — ignorado',
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
          'V47: coluna ${entry.key} adicionada em occurrences',
          tag: 'DB',
        );
      } else {
        AppLogger.debug(
          'V47: coluna ${entry.key} já existe em occurrences',
          tag: 'DB.Migration',
        );
      }
    }
  }
}
