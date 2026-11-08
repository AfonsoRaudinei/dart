import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migração SQLite v50 — persiste `drawings.cor` (condição do talhão).
///
/// O ARGB já viajava no JSON remoto de `properties`. Localmente a coluna não
/// existia, então a cor sumia ao reabrir o mapa.
class DatabaseMigrationsV50 {
  DatabaseMigrationsV50._();

  static Future<void> migrateToV50(Database db) async {
    if (!await DatabaseSchemaUtils.tableExists(db, 'drawings')) {
      AppLogger.debug(
        'V50: tabela drawings ausente — ignorado',
        tag: 'DB.Migration',
      );
      return;
    }

    if (!await DatabaseSchemaUtils.columnExists(db, 'drawings', 'cor')) {
      await db.execute('ALTER TABLE drawings ADD COLUMN cor INTEGER');
      AppLogger.debug('V50: coluna cor adicionada em drawings', tag: 'DB');
    } else {
      AppLogger.debug(
        'V50: coluna cor já existe em drawings',
        tag: 'DB.Migration',
      );
    }
  }
}
