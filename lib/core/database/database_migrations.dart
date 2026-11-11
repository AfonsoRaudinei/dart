import 'package:sqflite/sqflite.dart';

import 'database_migrations_v1_v23.dart';
import 'database_migrations_v24_v38.dart';
import 'database_migrations_v42.dart';
import 'database_migrations_v43.dart';
import 'database_migrations_v44.dart';
import 'database_migrations_v45.dart';
import 'database_migrations_v46.dart';
import 'database_migrations_v47.dart';
import 'database_migrations_v48.dart';
import 'database_migrations_v49.dart';
import 'database_migrations_v50.dart';
import 'database_migrations_v51.dart';
import 'database_migrations_v52.dart';
import 'database_migrations_v53.dart';

/// Fachada de migrações SQLite v1–v53 (Fase 3).
class DatabaseMigrations {
  DatabaseMigrations._();

  static Future<void> migrateToV1(Database db) =>
      DatabaseMigrationsV1V23.migrateToV1(db);
  static Future<void> migrateToV2(Database db) =>
      DatabaseMigrationsV1V23.migrateToV2(db);
  static Future<void> migrateToV3(Database db) =>
      DatabaseMigrationsV1V23.migrateToV3(db);
  static Future<void> migrateToV4(Database db) =>
      DatabaseMigrationsV1V23.migrateToV4(db);
  static Future<void> migrateToV5(Database db) =>
      DatabaseMigrationsV1V23.migrateToV5(db);
  static Future<void> migrateToV6(Database db) =>
      DatabaseMigrationsV1V23.migrateToV6(db);
  static Future<void> migrateToV7(Database db) =>
      DatabaseMigrationsV1V23.migrateToV7(db);
  static Future<void> migrateToV8(Database db) =>
      DatabaseMigrationsV1V23.migrateToV8(db);
  static Future<void> migrateToV9(Database db) =>
      DatabaseMigrationsV1V23.migrateToV9(db);
  static Future<void> migrateToV10(Database db) =>
      DatabaseMigrationsV1V23.migrateToV10(db);
  static Future<void> migrateToV11(Database db) =>
      DatabaseMigrationsV1V23.migrateToV11(db);
  static Future<void> migrateToV12(Database db) =>
      DatabaseMigrationsV1V23.migrateToV12(db);
  static Future<void> migrateToV13(Database db) =>
      DatabaseMigrationsV1V23.migrateToV13(db);
  static Future<void> migrateToV14(Database db) =>
      DatabaseMigrationsV1V23.migrateToV14(db);
  static Future<void> migrateToV15(Database db) =>
      DatabaseMigrationsV1V23.migrateToV15(db);
  static Future<void> migrateToV16(Database db) =>
      DatabaseMigrationsV1V23.migrateToV16(db);
  static Future<void> migrateToV17(Database db) =>
      DatabaseMigrationsV1V23.migrateToV17(db);
  static Future<void> migrateToV18(Database db) =>
      DatabaseMigrationsV1V23.migrateToV18(db);
  static Future<void> migrateToV19(Database db) =>
      DatabaseMigrationsV1V23.migrateToV19(db);
  static Future<void> migrateToV20(Database db) =>
      DatabaseMigrationsV1V23.migrateToV20(db);
  static Future<void> migrateToV21(Database db) =>
      DatabaseMigrationsV1V23.migrateToV21(db);
  static Future<void> migrateToV22(Database db) =>
      DatabaseMigrationsV1V23.migrateToV22(db);
  static Future<void> migrateToV23(Database db) =>
      DatabaseMigrationsV1V23.migrateToV23(db);
  static Future<void> migrateToV24(Database db) =>
      DatabaseMigrationsV24V38.migrateToV24(db);
  static Future<void> migrateToV25(Database db) =>
      DatabaseMigrationsV24V38.migrateToV25(db);
  static Future<void> migrateToV26(Database db) =>
      DatabaseMigrationsV24V38.migrateToV26(db);
  static Future<void> migrateToV27(Database db) =>
      DatabaseMigrationsV24V38.migrateToV27(db);
  static Future<void> migrateToV28(Database db) =>
      DatabaseMigrationsV24V38.migrateToV28(db);
  static Future<void> migrateToV29(Database db) =>
      DatabaseMigrationsV24V38.migrateToV29(db);
  static Future<void> migrateToV30(Database db) =>
      DatabaseMigrationsV24V38.migrateToV30(db);
  static Future<void> migrateToV31(Database db) =>
      DatabaseMigrationsV24V38.migrateToV31(db);
  static Future<void> migrateToV32(Database db) =>
      DatabaseMigrationsV24V38.migrateToV32(db);
  static Future<void> migrateToV33(Database db) =>
      DatabaseMigrationsV24V38.migrateToV33(db);
  static Future<void> migrateToV34(Database db) =>
      DatabaseMigrationsV24V38.migrateToV34(db);
  static Future<void> migrateToV35(Database db) =>
      DatabaseMigrationsV24V38.migrateToV35(db);
  static Future<void> migrateToV36(Database db) =>
      DatabaseMigrationsV24V38.migrateToV36(db);
  static Future<void> migrateToV37(Database db) =>
      DatabaseMigrationsV24V38.migrateToV37(db);
  static Future<void> migrateToV38(Database db) =>
      DatabaseMigrationsV24V38.migrateToV38(db);
  static Future<void> migrateToV39(Database db) =>
      DatabaseMigrationsV24V38.migrateToV39(db);
  static Future<void> migrateToV40(Database db) =>
      DatabaseMigrationsV24V38.migrateToV40(db);
  static Future<void> migrateToV41(Database db) =>
      DatabaseMigrationsV24V38.migrateToV41(db);
  static Future<void> migrateToV42(Database db) =>
      DatabaseMigrationsV42.migrateToV42(db);
  static Future<void> migrateToV43(Database db) =>
      DatabaseMigrationsV43.migrateToV43(db);
  static Future<void> migrateToV44(Database db) =>
      DatabaseMigrationsV44.migrateToV44(db);
  static Future<void> migrateToV45(Database db) =>
      DatabaseMigrationsV45.migrateToV45(db);
  static Future<void> migrateToV46(Database db) =>
      DatabaseMigrationsV46.migrateToV46(db);
  static Future<void> migrateToV47(Database db) =>
      DatabaseMigrationsV47.migrateToV47(db);
  static Future<void> migrateToV48(Database db) =>
      DatabaseMigrationsV48.migrateToV48(db);
  static Future<void> migrateToV49(Database db) =>
      DatabaseMigrationsV49.migrateToV49(db);
  static Future<void> migrateToV50(Database db) =>
      DatabaseMigrationsV50.migrateToV50(db);
  static Future<void> migrateToV51(Database db) =>
      DatabaseMigrationsV51.migrateToV51(db);
  static Future<void> migrateToV52(Database db) =>
      DatabaseMigrationsV52.migrateToV52(db);
  static Future<void> migrateToV53(Database db) =>
      DatabaseMigrationsV53.migrateToV53(db);
}
