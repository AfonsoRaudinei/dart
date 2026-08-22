import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/carteira/data/opportunity_lookup_impl.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/categoria_global.dart';
import 'package:soloforte_app/modules/carteira/domain/repositories/i_carteira_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const userId = 'user-1';
  const clientId = 'client-1';
  const categoriaId = 'cat-1';

  setUp(() {
    LocalSessionIdentity.resetForTesting();
    LocalSessionIdentity.remember(userId);
    databaseFactory = databaseFactoryFfi;
  });

  tearDown(LocalSessionIdentity.resetForTesting);

  Future<Database> openLookupDb() async {
    final db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE clients (
            id TEXT PRIMARY KEY,
            area_total REAL
          )
        ''');
        await db.execute('''
          CREATE TABLE carteira_lancamentos (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL,
            safra_id TEXT NOT NULL,
            categoria_id TEXT NOT NULL,
            cliente_id TEXT NOT NULL,
            quantidade REAL NOT NULL,
            closed_percent REAL NOT NULL DEFAULT 0.0,
            data_lancamento TEXT NOT NULL,
            created_at TEXT NOT NULL,
            deleted_at TEXT
          )
        ''');
      },
    );
    await db.insert('clients', {'id': clientId, 'area_total': 100.0});
    return db;
  }

  OpportunityLookupImpl lookupFor(Database db) {
    return OpportunityLookupImpl(
      repository: _FakeCarteiraRepository([
        CategoriaGlobal(
          id: categoriaId,
          userId: userId,
          nome: 'Defensivos',
          cor: '#4ADE80',
          ativo: true,
          ordem: 0,
          createdAt: DateTime.utc(2026, 8, 22),
          updatedAt: DateTime.utc(2026, 8, 22),
          valorReferencia: 1000,
        ),
      ]),
      db: DatabaseHelper.instance,
      databaseForTesting: db,
    );
  }

  test('SUM closed_percent ignora tombstone e conta deleted_at NULL legado', () async {
    final db = await openLookupDb();
    await db.insert('carteira_lancamentos', {
      'id': 'live-legacy',
      'user_id': userId,
      'safra_id': 's1',
      'categoria_id': categoriaId,
      'cliente_id': clientId,
      'quantidade': 0,
      'closed_percent': 40.0,
      'data_lancamento': '2026-08-22T10:00:00.000Z',
      'created_at': '2026-08-22T10:00:00.000Z',
      'deleted_at': null,
    });
    await db.insert('carteira_lancamentos', {
      'id': 'tombstone',
      'user_id': userId,
      'safra_id': 's1',
      'categoria_id': categoriaId,
      'cliente_id': clientId,
      'quantidade': 0,
      'closed_percent': 60.0,
      'data_lancamento': '2026-08-22T11:00:00.000Z',
      'created_at': '2026-08-22T11:00:00.000Z',
      'deleted_at': '2026-08-22T12:00:00.000Z',
    });

    final ops = await lookupFor(db).getOpenOpportunities(clientId);
    expect(ops, hasLength(1));
    expect(ops.first.closedPercent, 40.0);
    expect(ops.first.residualPercent, 60.0);

    await db.close();
  });

  test('só tombstone não fecha a oportunidade', () async {
    final db = await openLookupDb();
    await db.insert('carteira_lancamentos', {
      'id': 'tombstone-only',
      'user_id': userId,
      'safra_id': 's1',
      'categoria_id': categoriaId,
      'cliente_id': clientId,
      'quantidade': 0,
      'closed_percent': 100.0,
      'data_lancamento': '2026-08-22T11:00:00.000Z',
      'created_at': '2026-08-22T11:00:00.000Z',
      'deleted_at': '2026-08-22T12:00:00.000Z',
    });

    final ops = await lookupFor(db).getOpenOpportunities(clientId);
    expect(ops, hasLength(1));
    expect(ops.first.closedPercent, 0.0);
    expect(ops.first.residualPercent, 100.0);

    await db.close();
  });
}

class _FakeCarteiraRepository extends Fake implements ICarteiraRepository {
  _FakeCarteiraRepository(this._categorias);

  final List<CategoriaGlobal> _categorias;

  @override
  Future<List<CategoriaGlobal>> getCategorias(String userId) async =>
      _categorias;
}
