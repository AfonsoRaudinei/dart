import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

import 'package:soloforte_app/core/database/database_helper.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_lancamento.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_meta.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_safra.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/categoria_global.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/cliente_categoria.dart';
import 'package:soloforte_app/modules/carteira/domain/repositories/i_carteira_repository.dart';

class CarteiraRepositoryImpl implements ICarteiraRepository {
  CarteiraRepositoryImpl({DatabaseHelper? dbHelper})
    : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  final DatabaseHelper _dbHelper;
  static const Uuid _uuid = Uuid();

  static const List<({String nome, String cor})> _categoriasIniciais = [
    (nome: 'Nutrição / Fertilidade', cor: '#4ADE80'),
    (nome: 'Sementes de Soja', cor: '#FBBF24'),
    (nome: 'Defensivos / Químico', cor: '#F87171'),
    (nome: 'Biotecnologia', cor: '#60A5FA'),
    (nome: 'Sementes de Milho', cor: '#A78BFA'),
    (nome: 'Outros', cor: '#9CA3AF'),
  ];

  @override
  Future<List<CategoriaGlobal>> getCategorias(String userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'carteira_categorias',
      where: 'user_id = ? AND ativo = 1',
      whereArgs: [userId],
      orderBy: 'ordem ASC',
    );
    return rows.map(_categoriaFromMap).toList(growable: false);
  }

  @override
  Future<void> saveCategoria(CategoriaGlobal categoria) async {
    final db = await _dbHelper.database;
    await db.insert(
      'carteira_categorias',
      _categoriaToMap(categoria),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateCategoria(CategoriaGlobal categoria) async {
    final db = await _dbHelper.database;
    await db.update(
      'carteira_categorias',
      _categoriaToMap(categoria),
      where: 'id = ?',
      whereArgs: [categoria.id],
    );
  }

  @override
  Future<void> desativarCategoria(String id) async {
    final db = await _dbHelper.database;
    await db.update(
      'carteira_categorias',
      {'ativo': 0, 'updated_at': DateTime.now().toIso8601String()},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  @override
  Future<List<ClienteCategoria>> getCategoriasDoCliente(
    String userId,
    String clienteId,
  ) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'carteira_cliente_categorias',
      where: 'user_id = ? AND cliente_id = ?',
      whereArgs: [userId, clienteId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_clienteCategoriaFromMap).toList(growable: false);
  }

  @override
  Future<List<ClienteCategoria>> getTodosRegistros(String userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'carteira_cliente_categorias',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'updated_at DESC',
    );
    return rows.map(_clienteCategoriaFromMap).toList(growable: false);
  }

  @override
  Future<void> upsertClienteCategoria(ClienteCategoria registro) async {
    if (registro.percentualFechado < 0 || registro.percentualFechado > 100) {
      throw ArgumentError.value(
        registro.percentualFechado,
        'percentualFechado',
        'percentualFechado deve estar entre 0 e 100',
      );
    }

    final db = await _dbHelper.database;
    await db.insert(
      'carteira_cliente_categorias',
      _clienteCategoriaToMap(registro),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> seedCategoriasIniciais(String userId) async {
    final db = await _dbHelper.database;
    final existing = Sqflite.firstIntValue(
      await db.rawQuery(
        'SELECT COUNT(1) FROM carteira_categorias WHERE user_id = ?',
        [userId],
      ),
    );

    if ((existing ?? 0) > 0) {
      return;
    }

    final now = DateTime.now().toIso8601String();
    final batch = db.batch();
    for (var i = 0; i < _categoriasIniciais.length; i++) {
      final categoria = _categoriasIniciais[i];
      batch.insert('carteira_categorias', {
        'id': _uuid.v4(),
        'user_id': userId,
        'nome': categoria.nome,
        'cor': categoria.cor,
        'ativo': 1,
        'ordem': i,
        'created_at': now,
        'updated_at': now,
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    await batch.commit(noResult: true);
  }

  // ── Config global ───────────────────────────────────────────────

  @override
  Future<double> getValorGrao(String userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'carteira_config',
      where: 'user_id = ?',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return 0.0;
    return (rows.first['valor_grao'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<void> setValorGrao(String userId, double valor) async {
    final db = await _dbHelper.database;
    await db.insert('carteira_config', {
      'user_id': userId,
      'valor_grao': valor,
      'updated_at': DateTime.now().toIso8601String(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // ── Safras ──────────────────────────────────────────────────────

  @override
  Future<List<CarteiraSafra>> getSafras(String userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'carteira_safras',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'data_inicio DESC',
    );
    return rows.map(CarteiraSafra.fromMap).toList();
  }

  @override
  Future<CarteiraSafra?> getSafraAtiva(String userId) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'carteira_safras',
      where: 'user_id = ? AND ativa = 1',
      whereArgs: [userId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return CarteiraSafra.fromMap(rows.first);
  }

  @override
  Future<void> saveSafra(CarteiraSafra safra) async {
    final db = await _dbHelper.database;
    await db.insert(
      'carteira_safras',
      safra.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> ativarSafra(String safraId, String userId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      // Desativa todas as safras do usuário
      await txn.update(
        'carteira_safras',
        {'ativa': 0, 'updated_at': DateTime.now().toIso8601String()},
        where: 'user_id = ?',
        whereArgs: [userId],
      );
      // Ativa a safra selecionada
      await txn.update(
        'carteira_safras',
        {'ativa': 1, 'updated_at': DateTime.now().toIso8601String()},
        where: 'id = ? AND user_id = ?',
        whereArgs: [safraId, userId],
      );
    });
  }

  // ── Metas ───────────────────────────────────────────────────────

  @override
  Future<List<CarteiraMeta>> getMetasBySafra(
    String safraId,
    String userId,
  ) async {
    final db = await _dbHelper.database;
    final rows = await db.query(
      'carteira_metas',
      where: 'safra_id = ? AND user_id = ?',
      whereArgs: [safraId, userId],
    );
    return rows.map(CarteiraMeta.fromMap).toList();
  }

  @override
  Future<void> saveMeta(CarteiraMeta meta) async {
    final db = await _dbHelper.database;
    await db.insert(
      'carteira_metas',
      meta.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> updateMeta(CarteiraMeta meta) async {
    final db = await _dbHelper.database;
    await db.update(
      'carteira_metas',
      meta.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [meta.id, meta.userId],
    );
  }

  // ── Lançamentos ─────────────────────────────────────────────────

  @override
  Future<List<CarteiraLancamento>> getLancamentos({
    required String userId,
    required String safraId,
    String? categoriaId,
    String? clienteId,
  }) async {
    final db = await _dbHelper.database;
    final where = StringBuffer('user_id = ? AND safra_id = ?');
    final args = <dynamic>[userId, safraId];
    if (categoriaId != null) {
      where.write(' AND categoria_id = ?');
      args.add(categoriaId);
    }
    if (clienteId != null) {
      where.write(' AND cliente_id = ?');
      args.add(clienteId);
    }
    final rows = await db.query(
      'carteira_lancamentos',
      where: where.toString(),
      whereArgs: args,
      orderBy: 'data_lancamento DESC',
    );
    return rows.map(CarteiraLancamento.fromMap).toList();
  }

  @override
  Future<void> saveLancamento(CarteiraLancamento lancamento) async {
    final db = await _dbHelper.database;
    await db.insert(
      'carteira_lancamentos',
      lancamento.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> deleteLancamento(String id, String userId) async {
    final db = await _dbHelper.database;
    await db.delete(
      'carteira_lancamentos',
      where: 'id = ? AND user_id = ?',
      whereArgs: [id, userId],
    );
  }

  // ── Cálculos ────────────────────────────────────────────────────

  @override
  Future<double> getRealizadoBySafraCategoria(
    String safraId,
    String categoriaId,
    String userId,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(quantidade), 0.0) AS total '
      'FROM carteira_lancamentos '
      'WHERE safra_id = ? AND categoria_id = ? AND user_id = ?',
      [safraId, categoriaId, userId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  @override
  Future<double> getRealizadoByClienteCategoriaSafra(
    String clienteId,
    String categoriaId,
    String safraId,
    String userId,
  ) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery(
      'SELECT COALESCE(SUM(quantidade), 0.0) AS total '
      'FROM carteira_lancamentos '
      'WHERE cliente_id = ? AND categoria_id = ? '
      'AND safra_id = ? AND user_id = ?',
      [clienteId, categoriaId, safraId, userId],
    );
    return (result.first['total'] as num?)?.toDouble() ?? 0.0;
  }

  Map<String, Object?> _categoriaToMap(CategoriaGlobal categoria) {
    return {
      'id': categoria.id,
      'user_id': categoria.userId,
      'nome': categoria.nome,
      'cor': categoria.cor,
      'ativo': categoria.ativo ? 1 : 0,
      'ordem': categoria.ordem,
      'unidade': categoria.unidade.dbValue,
      'valor_referencia': categoria.valorReferencia,
      'valor_real': categoria.valorReal,
      'valor_dolar': categoria.valorDolar,
      'sacas_por_ha': categoria.sacasPorHa,
      'created_at': categoria.createdAt.toIso8601String(),
      'updated_at': categoria.updatedAt.toIso8601String(),
    };
  }

  CategoriaGlobal _categoriaFromMap(Map<String, Object?> map) {
    return CategoriaGlobal(
      id: (map['id'] ?? '') as String,
      userId: (map['user_id'] ?? '') as String,
      nome: (map['nome'] ?? '') as String,
      cor: (map['cor'] ?? '#4ADE80') as String,
      ativo: ((map['ativo'] ?? 1) as int) == 1,
      ordem: (map['ordem'] ?? 0) as int,
      unidade: CategoriaGlobal.fromMap(map).unidade,
      valorReferencia: (map['valor_referencia'] as num?)?.toDouble(),
      valorReal: (map['valor_real'] as num?)?.toDouble(),
      valorDolar: (map['valor_dolar'] as num?)?.toDouble(),
      sacasPorHa: (map['sacas_por_ha'] as num?)?.toDouble(),
      createdAt: DateTime.parse((map['created_at'] ?? '') as String),
      updatedAt: DateTime.parse((map['updated_at'] ?? '') as String),
    );
  }

  Map<String, Object?> _clienteCategoriaToMap(ClienteCategoria registro) {
    return {
      'id': registro.id,
      'user_id': registro.userId,
      'cliente_id': registro.clienteId,
      'categoria_id': registro.categoriaId,
      'percentual_fechado': registro.percentualFechado,
      'observacao': registro.observacao,
      'updated_at': registro.updatedAt.toIso8601String(),
    };
  }

  ClienteCategoria _clienteCategoriaFromMap(Map<String, Object?> map) {
    return ClienteCategoria(
      id: (map['id'] ?? '') as String,
      userId: (map['user_id'] ?? '') as String,
      clienteId: (map['cliente_id'] ?? '') as String,
      categoriaId: (map['categoria_id'] ?? '') as String,
      percentualFechado: (map['percentual_fechado'] ?? 0) as int,
      observacao: map['observacao'] as String?,
      updatedAt: DateTime.parse((map['updated_at'] ?? '') as String),
    );
  }
}
