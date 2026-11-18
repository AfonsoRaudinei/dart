import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migração SQLite v55 — validação de emergência no plantio (ADR-063).
class DatabaseMigrationsV55 {
  DatabaseMigrationsV55._();

  static const _columns = <String, String>{
    'data_validacao': 'TEXT',
    'avaliacao_emergencia': 'TEXT',
  };

  static Future<void> migrateToV55(Database db) async {
    if (!await DatabaseSchemaUtils.tableExists(db, 'occurrences')) {
      AppLogger.debug(
        'V55: tabela occurrences ausente — ignorado',
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
          'V55: coluna ${entry.key} adicionada em occurrences',
          tag: 'DB',
        );
      } else {
        AppLogger.debug(
          'V55: coluna ${entry.key} já existe em occurrences',
          tag: 'DB.Migration',
        );
      }
    }
  }
}