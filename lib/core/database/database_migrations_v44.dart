import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migração SQLite v44 — fonte meteorológica em `clima_atual_cache`.
class DatabaseMigrationsV44 {
  DatabaseMigrationsV44._();

  static Future<void> migrateToV44(Database db) async {
    if (!await DatabaseSchemaUtils.tableExists(db, 'clima_atual_cache')) {
      AppLogger.debug(
        'V44: tabela clima_atual_cache ausente — ignorado',
        tag: 'DB.Migration',
      );
      return;
    }

    if (!await DatabaseSchemaUtils.columnExists(
      db,
      'clima_atual_cache',
      'fonte',
    )) {
      await db.execute(
        "ALTER TABLE clima_atual_cache ADD COLUMN fonte TEXT NOT NULL DEFAULT ''",
      );
      AppLogger.debug(
        'V44: coluna fonte adicionada em clima_atual_cache',
        tag: 'DB',
      );
    } else {
      AppLogger.debug(
        'V44: coluna fonte já existe em clima_atual_cache',
        tag: 'DB.Migration',
      );
    }
  }
}
