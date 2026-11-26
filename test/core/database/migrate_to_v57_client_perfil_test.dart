import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const newColumns = [
    'perfil_dominante',
    'perfil_secundario',
    'perfil_pontos_a',
    'perfil_pontos_b',
    'perfil_pontos_c',
    'perfil_pontos_d',
    'perfil_atualizado_em',
  ];

  Future<Database> openLegacyClientsDb() {
    databaseFactory = databaseFactoryFfi;
    return openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clients (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL DEFAULT '',
            nome TEXT NOT NULL,
            created_at TEXT NOT NULL,
            updated_at TEXT NOT NULL
          )
        ''');
      },
    );
  }

  test('migrateToV57 adiciona colunas de perfil em clients', () async {
    final db = await openLegacyClientsDb();

    for (final column in newColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'clients', column),
        isFalse,
      );
    }

    await DatabaseHelper.instance.runMigrationsForTesting(db, 56, 57);

    for (final column in newColumns) {
      expect(
        await DatabaseSchemaUtils.columnExists(db, 'clients', column),
        isTrue,
      );
    }

    await db.close();
  });
}