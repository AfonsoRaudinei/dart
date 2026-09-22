import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migração SQLite v43 — material (cultivar) em `drawings`.
class DatabaseMigrationsV43 {
  DatabaseMigrationsV43._();

  /// Adiciona `material TEXT` em `drawings`. Idempotente.
  static Future<void> migrateToV43(Database db) async {
    if (!await DatabaseSchemaUtils.tableExists(db, 'drawings')) {
      AppLogger.debug(
        'V43: tabela drawings ausente — ignorado',
        tag: 'DB.Migration',
      );
      return;
    }

    if (!await DatabaseSchemaUtils.columnExists(db, 'drawings', 'material')) {
      await db.execute('ALTER TABLE drawings ADD COLUMN material TEXT');
      AppLogger.debug('V43: coluna material adicionada em drawings', tag: 'DB');
    } else {
      AppLogger.debug(
        'V43: coluna material já existe em drawings',
        tag: 'DB.Migration',
      );
    }
  }
}
