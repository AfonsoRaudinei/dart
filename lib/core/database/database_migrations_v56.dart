import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';

/// Migração SQLite v56 — implementação do campo de teste (ADR-064).
class DatabaseMigrationsV56 {
  DatabaseMigrationsV56._();

  static Future<void> migrateToV56(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS teste_execucoes (
        id TEXT PRIMARY KEY,
        drawing_id TEXT NOT NULL,
        user_id TEXT NOT NULL,
        sync_status TEXT NOT NULL,
        talhao TEXT,
        implementacao TEXT,
        foto_url TEXT,
        criado_em TEXT NOT NULL,
        atualizado_em TEXT NOT NULL,
        deleted_at TEXT
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_teste_execucoes_drawing '
      'ON teste_execucoes(drawing_id)',
    );
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_teste_execucoes_sync '
      'ON teste_execucoes(sync_status)',
    );
    AppLogger.debug('V56: tabela teste_execucoes criada', tag: 'DB.Migration');
  }
}