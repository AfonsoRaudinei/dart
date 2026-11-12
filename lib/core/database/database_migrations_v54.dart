import 'package:sqflite/sqflite.dart';

/// Confirmação da visita para o calendário do produtor. ADR-061.
class DatabaseMigrationsV54 {
  DatabaseMigrationsV54._();

  static Future<void> migrateToV54(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS visit_producer_confirmations (
        id TEXT PRIMARY KEY,
        visit_session_id TEXT NOT NULL UNIQUE,
        client_id TEXT NOT NULL,
        consultor_user_id TEXT NOT NULL,
        confirmed_at TEXT NOT NULL,
        visited_at TEXT NOT NULL,
        farm_name TEXT,
        field_name TEXT,
        sync_status TEXT NOT NULL,
        user_id TEXT NOT NULL
      )
    ''');
  }
}
