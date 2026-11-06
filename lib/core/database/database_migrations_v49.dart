import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

/// Migração SQLite v49 — colunas locais de ocorrências, relatórios e visitas.
///
/// Só colunas nullable. `occurrences.field_id` e `visit_sessions.route_*`
/// são apenas locais e não vão ao Supabase.
class DatabaseMigrationsV49 {
  DatabaseMigrationsV49._();

  /// Idempotente. Cada tabela ausente é ignorada de forma independente.
  static Future<void> migrateToV49(Database db) async {
    final hasOccurrences = await _addColumns(db, 'occurrences', const {
      'andamento': 'TEXT',
      'responsavel_nome': 'TEXT',
      'audio_path': 'TEXT',
      'audio_duration_sec': 'INTEGER',
      'amostra_codigo': 'TEXT',
      'amostra_coletor': 'TEXT',
      'amostra_tramite': 'TEXT',
      'amostra_laudo_texto': 'TEXT',
      'amostra_analises_json': 'TEXT',
      'field_id': 'TEXT',
      'recomendacao_acao': 'TEXT',
      'recomendacao_dose': 'TEXT',
      'recomendacao_quando': 'TEXT',
    });

    if (hasOccurrences) {
      await db.execute(
        "UPDATE occurrences SET andamento = 'aberta' "
        "WHERE andamento IS NULL OR trim(andamento) = ''",
      );
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_occurrences_field_id '
        'ON occurrences(field_id)',
      );
    }

    await _addColumns(db, 'relatorios', const {
      'clima_manual_json': 'TEXT',
    });

    await _addColumns(db, 'visit_sessions', const {
      'route_stops_json': 'TEXT',
      'route_current_index': 'INTEGER',
    });
  }

  /// Retorna `false` quando a tabela não existe.
  static Future<bool> _addColumns(
    Database db,
    String table,
    Map<String, String> columns,
  ) async {
    if (!await DatabaseSchemaUtils.tableExists(db, table)) {
      AppLogger.debug(
        'V49: tabela $table ausente — ignorado',
        tag: 'DB.Migration',
      );
      return false;
    }

    for (final entry in columns.entries) {
      if (!await DatabaseSchemaUtils.columnExists(db, table, entry.key)) {
        await db.execute(
          'ALTER TABLE $table ADD COLUMN ${entry.key} ${entry.value}',
        );
        AppLogger.debug(
          'V49: coluna ${entry.key} adicionada em $table',
          tag: 'DB',
        );
      } else {
        AppLogger.debug(
          'V49: coluna ${entry.key} já existe em $table',
          tag: 'DB.Migration',
        );
      }
    }
    return true;
  }
}
