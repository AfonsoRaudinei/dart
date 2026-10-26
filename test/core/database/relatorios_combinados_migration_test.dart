import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:soloforte_app/core/database/database_migrations.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  test('migrateToV46 cria relatorios_combinados e é idempotente', () async {
    final dir = await Directory.systemTemp.createTemp(
      'relatorios_combinados_v46',
    );
    final db = await databaseFactoryFfi.openDatabase(
      p.join(dir.path, 'v46.db'),
    );
    addTearDown(() async {
      await db.close();
      if (dir.existsSync()) dir.deleteSync(recursive: true);
    });

    await db.execute('PRAGMA user_version = 45');
    await DatabaseMigrations.migrateToV46(db);
    await DatabaseMigrations.migrateToV46(db);

    final rows = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = 'relatorios_combinados'",
    );
    expect(rows, isNotEmpty);
  });
}
