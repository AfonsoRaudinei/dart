import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import '../utils/app_logger.dart';
import 'database_schema_utils.dart';

import 'database_migrations_v1_v23.dart';
import 'database_migrations_v24_v38.dart';

/// Fachada de migrações SQLite v1–v38 (Fase 3).
class DatabaseMigrations {
  DatabaseMigrations._();

  static Future<void> migrateToV1(Database db) => DatabaseMigrationsV1V23.migrateToV1(db);
  static Future<void> migrateToV2(Database db) => DatabaseMigrationsV1V23.migrateToV2(db);
  static Future<void> migrateToV3(Database db) => DatabaseMigrationsV1V23.migrateToV3(db);
  static Future<void> migrateToV4(Database db) => DatabaseMigrationsV1V23.migrateToV4(db);
  static Future<void> migrateToV5(Database db) => DatabaseMigrationsV1V23.migrateToV5(db);
  static Future<void> migrateToV6(Database db) => DatabaseMigrationsV1V23.migrateToV6(db);
  static Future<void> migrateToV7(Database db) => DatabaseMigrationsV1V23.migrateToV7(db);
  static Future<void> migrateToV8(Database db) => DatabaseMigrationsV1V23.migrateToV8(db);
  static Future<void> migrateToV9(Database db) => DatabaseMigrationsV1V23.migrateToV9(db);
  static Future<void> migrateToV10(Database db) => DatabaseMigrationsV1V23.migrateToV10(db);
  static Future<void> migrateToV11(Database db) => DatabaseMigrationsV1V23.migrateToV11(db);
  static Future<void> migrateToV12(Database db) => DatabaseMigrationsV1V23.migrateToV12(db);
  static Future<void> migrateToV13(Database db) => DatabaseMigrationsV1V23.migrateToV13(db);
  static Future<void> migrateToV14(Database db) => DatabaseMigrationsV1V23.migrateToV14(db);
  static Future<void> migrateToV15(Database db) => DatabaseMigrationsV1V23.migrateToV15(db);
  static Future<void> migrateToV16(Database db) => DatabaseMigrationsV1V23.migrateToV16(db);
  static Future<void> migrateToV17(Database db) => DatabaseMigrationsV1V23.migrateToV17(db);
  static Future<void> migrateToV18(Database db) => DatabaseMigrationsV1V23.migrateToV18(db);
  static Future<void> migrateToV19(Database db) => DatabaseMigrationsV1V23.migrateToV19(db);
  static Future<void> migrateToV20(Database db) => DatabaseMigrationsV1V23.migrateToV20(db);
  static Future<void> migrateToV21(Database db) => DatabaseMigrationsV1V23.migrateToV21(db);
  static Future<void> migrateToV22(Database db) => DatabaseMigrationsV1V23.migrateToV22(db);
  static Future<void> migrateToV23(Database db) => DatabaseMigrationsV1V23.migrateToV23(db);
  static Future<void> migrateToV24(Database db) => DatabaseMigrationsV24V38.migrateToV24(db);
  static Future<void> migrateToV25(Database db) => DatabaseMigrationsV24V38.migrateToV25(db);
  static Future<void> migrateToV26(Database db) => DatabaseMigrationsV24V38.migrateToV26(db);
  static Future<void> migrateToV27(Database db) => DatabaseMigrationsV24V38.migrateToV27(db);
  static Future<void> migrateToV28(Database db) => DatabaseMigrationsV24V38.migrateToV28(db);
  static Future<void> migrateToV29(Database db) => DatabaseMigrationsV24V38.migrateToV29(db);
  static Future<void> migrateToV30(Database db) => DatabaseMigrationsV24V38.migrateToV30(db);
  static Future<void> migrateToV31(Database db) => DatabaseMigrationsV24V38.migrateToV31(db);
  static Future<void> migrateToV32(Database db) => DatabaseMigrationsV24V38.migrateToV32(db);
  static Future<void> migrateToV33(Database db) => DatabaseMigrationsV24V38.migrateToV33(db);
  static Future<void> migrateToV34(Database db) => DatabaseMigrationsV24V38.migrateToV34(db);
  static Future<void> migrateToV35(Database db) => DatabaseMigrationsV24V38.migrateToV35(db);
  static Future<void> migrateToV36(Database db) => DatabaseMigrationsV24V38.migrateToV36(db);
  static Future<void> migrateToV37(Database db) => DatabaseMigrationsV24V38.migrateToV37(db);
  static Future<void> migrateToV38(Database db) => DatabaseMigrationsV24V38.migrateToV38(db);
}
