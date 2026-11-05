import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migração SQLite v48 — plantio do talhão em `drawings`.
class DatabaseMigrationsV48 {
  DatabaseMigrationsV48._();

  /// Adiciona `data_plantio`, `data_emergencia` e `ciclo_dias` em `drawings`.
  /// Idempotente. Datas em `yyyy-MM-dd`.
  static Future<void> migrateToV48(Database db) async {
    if (!await DatabaseSchemaUtils.tableExists(db, 'drawings')) {
      AppLogger.debug(
        'V48: tabela drawings ausente — ignorado',
        tag: 'DB.Migration',
      );
      return;
    }

    const columns = <String, String>{
      'data_plantio': 'TEXT',
      'data_emergencia': 'TEXT',
      'ciclo_dias': 'INTEGER',
    };

    for (final entry in columns.entries) {
      if (!await DatabaseSchemaUtils.columnExists(db, 'drawings', entry.key)) {
        await db.execute(
          'ALTER TABLE drawings ADD COLUMN ${entry.key} ${entry.value}',
        );
        AppLogger.debug(
          'V48: coluna ${entry.key} adicionada em drawings',
          tag: 'DB',
        );
      } else {
        AppLogger.debug(
          'V48: coluna ${entry.key} já existe em drawings',
          tag: 'DB.Migration',
        );
      }
    }
  }
}
