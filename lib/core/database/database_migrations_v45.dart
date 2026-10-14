import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migração SQLite v45 — metadados NDVI (nuvem + degradado Sentinel).
class DatabaseMigrationsV45 {
  DatabaseMigrationsV45._();

  static Future<void> migrateToV45(Database db) async {
    if (!await DatabaseSchemaUtils.tableExists(db, 'ndvi_cache')) {
      AppLogger.debug(
        'V45: tabela ndvi_cache ausente — ignorado',
        tag: 'DB.Migration',
      );
      return;
    }

    if (!await DatabaseSchemaUtils.columnExists(
      db,
      'ndvi_cache',
      'cloud_coverage',
    )) {
      await db.execute(
        'ALTER TABLE ndvi_cache ADD COLUMN cloud_coverage REAL',
      );
      AppLogger.debug(
        'V45: coluna cloud_coverage em ndvi_cache',
        tag: 'DB',
      );
    }

    if (!await DatabaseSchemaUtils.columnExists(
      db,
      'ndvi_cache',
      'sentinel_degraded_reason',
    )) {
      await db.execute(
        "ALTER TABLE ndvi_cache ADD COLUMN sentinel_degraded_reason TEXT",
      );
      AppLogger.debug(
        'V45: coluna sentinel_degraded_reason em ndvi_cache',
        tag: 'DB',
      );
    }
  }
}
