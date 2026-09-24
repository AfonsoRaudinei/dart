import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/database/database_schema_utils.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('migrateToV44 adiciona fonte em clima_atual_cache', () async {
    databaseFactory = databaseFactoryFfi;
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clima_atual_cache (
            cache_key TEXT PRIMARY KEY,
            user_id TEXT NOT NULL DEFAULT '',
            temperatura REAL NOT NULL,
            sensacao_termica REAL NOT NULL,
            condicao TEXT NOT NULL,
            condicao_codigo TEXT NOT NULL,
            vento_velocidade REAL NOT NULL,
            vento_direcao TEXT NOT NULL,
            umidade INTEGER NOT NULL,
            precipitacao REAL NOT NULL,
            pressao REAL NOT NULL,
            visibilidade REAL NOT NULL,
            cobertura_nuvens INTEGER NOT NULL,
            indice_uv INTEGER NOT NULL,
            nascer_sol TEXT NOT NULL,
            por_sol TEXT NOT NULL,
            latitude REAL NOT NULL,
            longitude REAL NOT NULL,
            cidade TEXT NOT NULL,
            atualizado_em TEXT NOT NULL,
            cached_at TEXT NOT NULL
          )
        ''');
      },
    );

    expect(
      await DatabaseSchemaUtils.columnExists(db, 'clima_atual_cache', 'fonte'),
      isFalse,
    );

    await DatabaseHelper.instance.runMigrationsForTesting(db, 43, 44);

    expect(
      await DatabaseSchemaUtils.columnExists(db, 'clima_atual_cache', 'fonte'),
      isTrue,
    );

    await DatabaseHelper.instance.runMigrationsForTesting(db, 43, 44);
    expect(
      await DatabaseSchemaUtils.columnExists(db, 'clima_atual_cache', 'fonte'),
      isTrue,
    );

    await db.close();
  });
}
