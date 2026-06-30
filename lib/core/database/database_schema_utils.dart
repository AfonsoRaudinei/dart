import 'package:sqflite/sqflite.dart';

/// Utilitários de introspecção de schema SQLite (Fase 3 — extraído de [DatabaseHelper]).
class DatabaseSchemaUtils {
  DatabaseSchemaUtils._();

  static Future<bool> tableExists(Database db, String tableName) async {
    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ? LIMIT 1",
      [tableName],
    );
    return rows.isNotEmpty;
  }

  static Future<bool> columnExists(
    DatabaseExecutor db,
    String tableName,
    String columnName,
  ) async {
    final columns = await db.rawQuery('PRAGMA table_info($tableName)');
    return columns.any((column) => column['name'] == columnName);
  }

  static Future<void> renameTableIfExists(
    Database db,
    String tableName,
    String backupName,
  ) async {
    final exists = await tableExists(db, tableName);
    final backupExists = await tableExists(db, backupName);
    if (exists && !backupExists) {
      await db.execute('ALTER TABLE $tableName RENAME TO $backupName');
    }
  }
}
