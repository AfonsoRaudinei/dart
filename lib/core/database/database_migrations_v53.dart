import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migração SQLite v53 — escopo do convite em `producer_client_links`.
class DatabaseMigrationsV53 {
  DatabaseMigrationsV53._();

  static const _columns = <String, String>{
    'share_farms': 'INTEGER NOT NULL DEFAULT 1',
    'share_fields': 'INTEGER NOT NULL DEFAULT 1',
    'share_occurrences': 'INTEGER NOT NULL DEFAULT 1',
    'share_reports': 'INTEGER NOT NULL DEFAULT 1',
  };

  static Future<void> migrateToV53(Database db) async {
    if (!await DatabaseSchemaUtils.tableExists(db, 'producer_client_links')) {
      AppLogger.debug(
        'V53: tabela producer_client_links ausente — ignorado',
        tag: 'DB.Migration',
      );
      return;
    }

    for (final entry in _columns.entries) {
      if (!await DatabaseSchemaUtils.columnExists(
        db,
        'producer_client_links',
        entry.key,
      )) {
        await db.execute(
          'ALTER TABLE producer_client_links ADD COLUMN ${entry.key} ${entry.value}',
        );
      }
    }
  }
}
