import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/modules/carteira/data/opportunity_lookup_impl.dart';
import 'package:soloforte_app/modules/carteira/data/repositories/carteira_repository_impl.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_safra.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/categoria_global.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  const userId = 'user-safra';
  const clientId = 'client-safra';
  const categoriaId = 'cat-safra';
  const safraComLancamentos = 'safra-2025';
  const safraVazia = 'safra-2026';

  late Database db;
  late CarteiraRepositoryImpl repo;
  late OpportunityLookupImpl lookup;

  setUp(() async {
    LocalSessionIdentity.resetForTesting();
    LocalSessionIdentity.remember(userId);
    databaseFactory = databaseFactoryFfi;

    db = await openDatabase(
      inMemoryDatabasePath,
      version: 1,
      singleInstance: false,
      onCreate: (db, _) =>
          DatabaseHelper.instance.runMigrationsForTesting(db, 0, 57),
    );
    repo = CarteiraRepositoryImpl(dbHelper: _InMemoryDbHelper(db));
    lookup = OpportunityLookupImpl(
      repository: repo,
      db: DatabaseHelper.instance,
      databaseForTesting: db,
    );

    final now = DateTime.utc(2026, 9, 10);
    await db.insert('clients', {
      'id': clientId,
      'user_id': userId,
      'nome': 'Produtor Safra',
      'area_total': 100.0,
      'created_at': now.toIso8601String(),
      'updated_at': now.toIso8601String(),
    });
    await repo.saveCategoria(
      CategoriaGlobal(
        id: categoriaId,
        userId: userId,
        nome: 'Defensivos',
        cor: '#F87171',
        ativo: true,
        ordem: 0,
        valorReferencia: 1000,
        createdAt: now,
        updatedAt: now,
      ),
    );
    for (final (id, inicio) in [
      (safraComLancamentos, 2025),
      (safraVazia, 2026),
    ]) {
      await repo.saveSafra(
        CarteiraSafra(
          id: id,
          userId: userId,
          nome: 'Safra $inicio/${inicio + 1}',
          dataInicio: DateTime.utc(inicio, 9, 1),
          dataFim: DateTime.utc(inicio + 1, 8, 31),
          ativa: false,
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    await db.insert('carteira_lancamentos', {
      'id': 'lanc-2025',
      'user_id': userId,
      'safra_id': safraComLancamentos,
      'categoria_id': categoriaId,
      'cliente_id': clientId,
      'quantidade': 0,
      'closed_percent': 40.0,
      'data_lancamento': now.toIso8601String(),
      'created_at': now.toIso8601String(),
    });
  });

  tearDown(() async {
    LocalSessionIdentity.resetForTesting();
    await db.close();
  });

  test('safra sem lançamentos ativa: nada fechado e oportunidade cheia', () async {
    await repo.ativarSafra(safraVazia, userId);

    expect(await repo.getClosedPercentTodos(userId, safraVazia), isEmpty);
    expect(
      await repo.getClosedPercentByClienteCategoria(
        clientId,
        categoriaId,
        userId,
        safraVazia,
      ),
      0.0,
    );

    final ops = await lookup.getOpenOpportunities(clientId);
    expect(ops, hasLength(1));
    expect(ops.first.closedPercent, 0.0);
    expect(ops.first.residualPercent, 100.0);
  });

  test('safra com lançamentos ativa: reflete só os lançamentos dela', () async {
    await repo.ativarSafra(safraComLancamentos, userId);

    expect(await repo.getClosedPercentTodos(userId, safraComLancamentos), {
      '${clientId}_$categoriaId': 40.0,
    });
    expect(
      await repo.getClosedPercentByClienteCategoria(
        clientId,
        categoriaId,
        userId,
        safraComLancamentos,
      ),
      40.0,
    );

    final ops = await lookup.getOpenOpportunities(clientId);
    expect(ops, hasLength(1));
    expect(ops.first.closedPercent, 40.0);
    expect(ops.first.residualPercent, 60.0);
  });

  test('sem safra ativa o lookup não devolve oportunidade', () async {
    expect(await repo.getSafraAtiva(userId), isNull);
    expect(await lookup.getOpenOpportunities(clientId), isEmpty);
  });
}

class _InMemoryDbHelper extends Fake implements DatabaseHelper {
  _InMemoryDbHelper(this._db);

  final Database _db;

  @override
  Future<Database> get database async => _db;
}
