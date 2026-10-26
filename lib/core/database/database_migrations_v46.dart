import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';

/// Migração SQLite v46 — combinações salvas de relatórios (ADR-052).
class DatabaseMigrationsV46 {
  DatabaseMigrationsV46._();

  /// Cria `relatorios_combinados`. Idempotente (`CREATE TABLE IF NOT EXISTS`).
  static Future<void> migrateToV46(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS relatorios_combinados (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        client_id TEXT NOT NULL,
        title TEXT NOT NULL,
        chapters_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL,
        sync_status TEXT NOT NULL DEFAULT 'pending_sync',
        deleted_at TEXT
      )
    ''');
    AppLogger.debug('V46: tabela relatorios_combinados', tag: 'DB');
  }
}
