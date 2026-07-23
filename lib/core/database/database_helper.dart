import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import '../utils/app_logger.dart';
import 'database_migrations.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'soloforte.db');

    final db = await openDatabase(
      path,
      version: 40,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );

    // 🎯 Validação de integridade pós-boot
    await _validateSchema(db);

    return db;
  }

  // ════════════════════════════════════════════════════════════════════
  // ORQUESTRADOR DE SCHEMA
  // ════════════════════════════════════════════════════════════════════

  Future<void> _onCreate(Database db, int version) async {
    if (kDebugMode) {
      AppLogger.debug('Database: Instalação limpa (v0 → v$version)', tag: 'DB');
    }
    await _runMigrations(db, 0, version);
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (kDebugMode) {
      AppLogger.debug(
        'Database Upgrade: v$oldVersion → v$newVersion',
        tag: 'DB',
      );
    }
    await _runMigrations(db, oldVersion, newVersion);
  }

  /// 🔁 Orquestrador Determinístico de Migrações
  Future<void> _runMigrations(
    Database db,
    int fromVersion,
    int toVersion,
  ) async {
    for (int v = fromVersion + 1; v <= toVersion; v++) {
      if (kDebugMode) AppLogger.debug('Aplicando migração: v$v', tag: 'DB');
      switch (v) {
        case 1:
          await DatabaseMigrations.migrateToV1(db);
          break;
        case 2:
          await DatabaseMigrations.migrateToV2(db);
          break;
        case 3:
          await DatabaseMigrations.migrateToV3(db);
          break;
        case 4:
          await DatabaseMigrations.migrateToV4(db);
          break;
        case 5:
          await DatabaseMigrations.migrateToV5(db);
          break;
        case 6:
          await DatabaseMigrations.migrateToV6(db);
          break;
        case 7:
          await DatabaseMigrations.migrateToV7(db);
          break;
        case 8:
          await DatabaseMigrations.migrateToV8(db);
          break;
        case 9:
          await DatabaseMigrations.migrateToV9(db);
          break;
        case 10:
          await DatabaseMigrations.migrateToV10(db);
          break;
        case 11:
          await DatabaseMigrations.migrateToV11(db);
          break;
        case 12:
          await DatabaseMigrations.migrateToV12(db);
          break;
        case 13:
          await DatabaseMigrations.migrateToV13(db);
          break;
        case 14:
          await DatabaseMigrations.migrateToV14(db);
          break;
        case 15:
          await DatabaseMigrations.migrateToV15(db);
          break;
        case 16:
          await DatabaseMigrations.migrateToV16(db);
          break;
        case 17:
          await DatabaseMigrations.migrateToV17(db);
          break;
        case 18:
          await DatabaseMigrations.migrateToV18(db);
          break;
        case 19:
          await DatabaseMigrations.migrateToV19(db);
          break;
        case 20:
          await DatabaseMigrations.migrateToV20(db);
          break;
        case 21:
          await DatabaseMigrations.migrateToV21(db);
          break;
        case 22:
          await DatabaseMigrations.migrateToV22(db);
          break;
        case 23:
          await DatabaseMigrations.migrateToV23(db);
          break;
        case 24:
          await DatabaseMigrations.migrateToV24(db);
          break;
        case 25:
          await DatabaseMigrations.migrateToV25(db);
          break;
        case 26:
          await DatabaseMigrations.migrateToV26(db);
          break;
        case 27:
          await DatabaseMigrations.migrateToV27(db);
          break;
        case 28:
          await DatabaseMigrations.migrateToV28(db);
          break;
        case 29:
          await DatabaseMigrations.migrateToV29(db);
          break;
        case 30:
          await DatabaseMigrations.migrateToV30(db);
          break;
        case 31:
          await DatabaseMigrations.migrateToV31(db);
          break;
        case 32:
          await DatabaseMigrations.migrateToV32(db);
          break;
        case 33:
          await DatabaseMigrations.migrateToV33(db);
          break;
        case 34:
          await DatabaseMigrations.migrateToV34(db);
          break;
        case 35:
          await DatabaseMigrations.migrateToV35(db);
          break;
        case 36:
          await DatabaseMigrations.migrateToV36(db);
          break;
        case 37:
          await DatabaseMigrations.migrateToV37(db);
          break;
        case 38:
          await DatabaseMigrations.migrateToV38(db);
          break;
        case 39:
          await DatabaseMigrations.migrateToV39(db);
          break;
        case 40:
          await DatabaseMigrations.migrateToV40(db);
          break;
      }
    }
  }

  @visibleForTesting
  Future<void> runMigrationsForTesting(
    Database db,
    int fromVersion,
    int toVersion,
  ) =>
      _runMigrations(db, fromVersion, toVersion);

  Future<void> _validateSchema(Database db) async {
    if (!kDebugMode) return;

    final criticalTables = ['clients', 'drawings', 'agenda_events'];
    for (final table in criticalTables) {
      final res = await db.rawQuery(
        "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
        [table],
      );
      if (res.isEmpty) {
        AppLogger.error(
          'ERRO CRÍTICO: Tabela "$table" não encontrada após boot.',
          tag: 'DB',
        );
      } else {
        AppLogger.debug('Database: Tabela "$table" validada.', tag: 'DB');
      }
    }
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }

  /// Remove registros locais do usuário.
  ///
  /// 🛡 Somente exclusão de conta (`SessionController.deleteAccount`).
  /// Logout **não** deve chamar este método — dados offline-first permanecem.
  Future<void> clearUserLocalData(String userId) async {
    final normalized = userId.trim();
    if (normalized.isEmpty) {
      AppLogger.warning(
        'clearUserLocalData ignorado: userId vazio',
        tag: 'DB',
      );
      return;
    }

    final db = await database;
    await db.transaction((txn) => _clearUserLocalData(txn, normalized));
  }

  Future<void> _clearUserLocalData(DatabaseExecutor db, String userId) async {
    const tablesWithUserId = [
      'clients',
      'farms',
      'fields',
      'visit_sessions',
      'occurrences',
      'visit_reports',
      'agenda_events',
      'agenda_visit_sessions',
      'drawings',
      'client_culturas',
      'clima_atual_cache',
      'clima_horaria_cache',
      'clima_diaria_cache',
      'ndvi_cache',
      'publicacoes_tecnicas',
      'relatorios',
      'relatorios_v2',
      'carteira_categorias',
      'carteira_cliente_categorias',
      'carteira_tipos_produto',
      'carteira_safras',
      'carteira_metas',
      'carteira_lancamentos',
      'quick_photos',
      'user_profile_edits',
    ];

    for (final table in tablesWithUserId) {
      try {
        await db.delete(table, where: 'user_id = ?', whereArgs: [userId]);
      } catch (_) {
        // Tabela ausente ou sem coluna esperada — ignorar no logout.
      }
    }

    try {
      await db.delete(
        'occurrences',
        where: 'cached_by_user_id = ?',
        whereArgs: [userId],
      );
    } catch (_) {
      // Coluna disponivel apenas a partir da v38.
    }

    try {
      await db.delete(
        'producer_client_links',
        where: 'producer_user_id = ? OR consultor_user_id = ?',
        whereArgs: [userId, userId],
      );
    } catch (_) {
      // Tabela de vínculo pode não existir em bancos legados.
    }

    try {
      await db.delete(
        'user_profile_cache',
        where: 'id = ?',
        whereArgs: [userId],
      );
    } catch (_) {
      // Tabela ausente — ignorar no logout.
    }
  }

  /// Repara registros órfãos criados sem user_id.
  ///
  /// Atualiza apenas linhas com `user_id` vazio ou nulo para o usuário atual.
  /// Idempotente e tolerante a tabelas ausentes.
  Future<void> repairOrphanUserIds(String userId) async {
    if (userId.isEmpty) return;

    final db = await database;

    const tablesWithUserId = <String>[
      'clients',
      'farms',
      'fields',
      'visit_sessions',
      'occurrences',
      'visit_reports',
      'agenda_events',
      'agenda_visit_sessions',
      'drawings',
      'client_culturas',
      'clima_atual_cache',
      'clima_horaria_cache',
      'clima_diaria_cache',
      'ndvi_cache',
      'publicacoes_tecnicas',
      'relatorios',
      'relatorios_v2',
      'carteira_categorias',
      'carteira_cliente_categorias',
      'carteira_tipos_produto',
      'carteira_safras',
      'carteira_metas',
      'carteira_lancamentos',
    ];

    for (final table in tablesWithUserId) {
      try {
        final count = await db.rawUpdate(
          "UPDATE $table SET user_id = ? WHERE user_id = '' OR user_id IS NULL",
          [userId],
        );
        if (count > 0) {
          AppLogger.debug('repairOrphanUserIds: $count linhas em $table', tag: 'DB');
        }
      } catch (e) {
        AppLogger.error('repairOrphanUserIds erro em $table', tag: 'DB', error: e);
      }
    }
  }
}
