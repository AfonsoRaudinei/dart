import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/marketing_case_status.dart';
import 'i_marketing_case_repository.dart';

class MarketingCaseRepositoryImpl implements IMarketingCaseRepository {
  final SupabaseClient _supabase;
  Database? _db;

  MarketingCaseRepositoryImpl(this._supabase);

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'marketing_cases.db');

    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE marketing_cases_cache (
            id TEXT PRIMARY KEY,
            data TEXT
          )
        ''');
      },
    );
    return _db!;
  }

  @override
  Future<List<MarketingCase>> fetchMarketingCases() async {
    // A query carrega o case e aninha seus blocos de avaliação
    final response = await _supabase
        .from('marketing_cases')
        .select('''
          *,
          marketing_avaliacoes (*)
        ''')
        .eq('ativo', true)
        .isFilter('deletado_em', null);

    final cases = (response as List).map((json) {
      // O join vem como 'marketing_avaliacoes', passamos para 'avaliacoes'
      // que é a chave esperada pelo fromJson na memoria/entidade de Dominio
      if (json['marketing_avaliacoes'] != null) {
        json['avaliacoes'] = json['marketing_avaliacoes'];
      }
      return MarketingCase.fromJson(json);
    }).toList();

    return cases;
  }

  @override
  Future<List<MarketingCase>> getLocalCases() async {
    final db = await _database;
    final List<Map<String, dynamic>> maps = await db.query(
      'marketing_cases_cache',
    );

    return maps.map((map) {
      final data = jsonDecode(map['data'] as String);
      return MarketingCase.fromJson(data);
    }).toList();
  }

  @override
  Future<void> saveToCache(List<MarketingCase> cases) async {
    final db = await _database;
    Batch batch = db.batch();

    // Deleta cache antigo e atualiza (Offline-first / TTL)
    batch.delete('marketing_cases_cache');

    for (var mc in cases) {
      batch.insert('marketing_cases_cache', {
        'id': mc.id,
        'data': jsonEncode(mc.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<MarketingCase> getById(String id) async {
    final db = await _database;
    final maps = await db.query(
      'marketing_cases_cache',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isNotEmpty) {
      final data = jsonDecode(maps.first['data'] as String);
      return MarketingCase.fromJson(data);
    }
    throw Exception('Case não encontrado no repositório');
  }

  @override
  Future<void> saveSingleToCache(MarketingCase marketingCase) async {
    final db = await _database;
    await db.insert('marketing_cases_cache', {
      'id': marketingCase.id,
      'data': jsonEncode(marketingCase.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async {
    // 1. Dados do case principal (exclui avaliacoes — tabela separada)
    final caseJson = marketingCase.toJson()
      ..remove('avaliacoes'); // Não existe na tabela principal

    // Campos ROI ficam no próprio registro (já estão em toJson via spread de roi)
    // atualizado_em é o momento local — o DB tem default now() mas podemos forçar
    caseJson['atualizado_em'] = DateTime.now().toIso8601String();
    caseJson['sync_status'] = 'synced';

    // 2. Upsert do case principal
    final response = await _supabase
        .from('marketing_cases')
        .upsert(caseJson)
        .select()
        .single();

    final savedCase = MarketingCase.fromJson(response);

    // 3. Salva cada avaliação na tabela filha
    if (marketingCase.avaliacoes.isNotEmpty) {
      final avaliacoesBatch = marketingCase.avaliacoes.map((av) {
        return {
          'id': av.id,
          'case_id': savedCase.id,
          'ordem': av.ordem,
          'layout': av.layout.toValue(),
          'colapsado': av.colapsado,
          'lado_a_label': av.ladoA.label,
          'lado_a_foto_url': av.ladoA.fotoUrl,
          'lado_a_cultura': av.ladoA.tipoCultura,
          'lado_a_obs': av.ladoA.observacoes,
          'lado_b_label': av.ladoB.label,
          'lado_b_foto_url': av.ladoB.fotoUrl,
          'lado_b_cultura': av.ladoB.tipoCultura,
          'lado_b_obs': av.ladoB.observacoes,
        };
      }).toList();

      await _supabase.from('marketing_avaliacoes').upsert(avaliacoesBatch);
    }

    // 4. Persistir no cache local (offline-first)
    final syncedCase = MarketingCase.fromJson({
      ...savedCase.toJson(),
      'sync_status': 'synced',
      'avaliacoes': marketingCase.avaliacoes.map((av) => av.toJson()).toList(),
    });
    await saveSingleToCache(syncedCase);

    return syncedCase;
  }

  @override
  Future<MarketingCase> saveAsDraft(MarketingCase marketingCase) async {
    // Rascunho: salva apenas localmente, com status=draft e syncStatus=local_only
    final draftCase = MarketingCase.fromJson({
      ...marketingCase.toJson(),
      'status': MarketingCaseStatus.draft.toValue(),
      'sync_status': 'local_only',
      'atualizado_em': DateTime.now().toIso8601String(),
    });

    // Persiste no cache local
    await saveSingleToCache(draftCase);

    return draftCase;
  }
}
