import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/modules/consultoria/publicacoes/data/publicacao_table.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('migrateToV41 cria publicacoes_tecnicas', () async {
    databaseFactory = databaseFactoryFfi;
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {},
    );

    final helper = DatabaseHelper.instance;
    await helper.runMigrationsForTesting(db, 40, 41);

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' AND name=?",
      [PublicacaoTable.tableName],
    );
    expect(tables, isNotEmpty);

    await db.insert(PublicacaoTable.tableName, {
      PublicacaoTable.colId: 'pub-1',
      PublicacaoTable.colUserId: 'user-1',
      PublicacaoTable.colAuthorId: 'author-1',
      PublicacaoTable.colTema: 'pragas',
      PublicacaoTable.colTitulo: 'Título',
      PublicacaoTable.colConteudo: 'Conteúdo',
      PublicacaoTable.colVisibility: 'privado',
      PublicacaoTable.colSyncStatus: 'local_only',
      PublicacaoTable.colCreatedAt: DateTime.now().toUtc().toIso8601String(),
      PublicacaoTable.colUpdatedAt: DateTime.now().toUtc().toIso8601String(),
      PublicacaoTable.colFotoPaths: '[]',
    });

    final rows = await db.query(PublicacaoTable.tableName);
    expect(rows, hasLength(1));
    await db.close();
  });
}
