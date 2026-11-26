import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';

/// Migração SQLite v57 — diagnóstico de perfil de atendimento do cliente.
class DatabaseMigrationsV57 {
  DatabaseMigrationsV57._();

  static Future<void> migrateToV57(Database db) async {
    const columns = <String, String>{
      'perfil_dominante': 'TEXT',
      'perfil_secundario': 'TEXT',
      'perfil_pontos_a': 'INTEGER',
      'perfil_pontos_b': 'INTEGER',
      'perfil_pontos_c': 'INTEGER',
      'perfil_pontos_d': 'INTEGER',
      'perfil_atualizado_em': 'TEXT',
    };

    for (final entry in columns.entries) {
      try {
        await db.execute(
          'ALTER TABLE clients ADD COLUMN ${entry.key} ${entry.value}',
        );
        AppLogger.debug(
          'V57: coluna ${entry.key} adicionada em clients',
          tag: 'DB.Migration',
        );
      } catch (_) {
        AppLogger.debug(
          'V57: ${entry.key} já existe em clients — ignorado',
          tag: 'DB.Migration',
        );
      }
    }
  }
}