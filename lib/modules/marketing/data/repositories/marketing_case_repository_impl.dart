import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/marketing_case.dart';
import '../../domain/enums/marketing_case_status.dart';
import 'i_marketing_case_repository.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

class MarketingCaseRepositoryImpl implements IMarketingCaseRepository {
  final SupabaseClient _supabase;
  Database? _db;

  MarketingCaseRepositoryImpl(this._supabase);

  String _scopedUserId() => LocalSessionIdentity.resolveUserId();

  Future<Database> get _database async {
    if (_db != null) return _db!;
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'marketing_cases.db');

    _db = await openDatabase(
      path,
      version: 3,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE marketing_cases_cache (
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL DEFAULT '',
            data TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 3) {
          // DROP+CREATE — nunca usar ALTER TABLE (regra do projeto)
          // Corrige "duplicate column name: user_id" introduzido na v2 via ALTER TABLE
          await db.execute('DROP TABLE IF EXISTS marketing_cases_cache');
          await db.execute('''
            CREATE TABLE marketing_cases_cache (
              id TEXT PRIMARY KEY,
              user_id TEXT NOT NULL DEFAULT '',
              data TEXT
            )
          ''');
        }
      },
    );
    return _db!;
  }

  @override
  Future<List<MarketingCase>> fetchMarketingCases() async {
    try {
      final cases = await _fetchRemoteCases();

      // 🛡 Não sobrescrever cache local com lista remota vazia se ainda há
      // cases locais (pending/local) — evita “sumiço” após login sem sync.
      if (cases.isEmpty) {
        final local = await getLocalCases();
        if (local.isNotEmpty) {
          AppLogger.warning(
            'Remoto vazio; preservando ${local.length} case(s) locais',
            tag: 'MarketingRepo',
          );
          return local;
        }
      }

      await saveToCache(cases);
      return cases;
    } on PostgrestException catch (e) {
      // Schema legado: tenta combinações compatíveis sem filtros opcionais.
      if (e.message.contains('marketing_cases.ativo') ||
          e.message.contains('marketing_cases.deletado_em')) {
        try {
          final fallbackCases = await _fetchRemoteCasesCompatible();
          if (fallbackCases.isEmpty) {
            final local = await getLocalCases();
            if (local.isNotEmpty) return local;
          }
          await saveToCache(fallbackCases);
          return fallbackCases;
        } on PostgrestException catch (fallbackError) {
          AppLogger.error(
            'Erro remoto (fallback), servindo cache',
            tag: 'MarketingRepo',
            error: fallbackError,
          );
          return getLocalCases();
        }
      }

      // Coluna ausente ou erro de schema → serve cache local
      AppLogger.error(
        'Erro remoto, servindo cache',
        tag: 'MarketingRepo',
        error: e,
      );
      return getLocalCases();
    } catch (e) {
      // Erro de rede ou timeout → serve cache local
      AppLogger.error('Erro inesperado, servindo cache', tag: 'MarketingRepo', error: e);
      return getLocalCases();
    }
  }

  Future<List<MarketingCase>> _fetchRemoteCases({
    bool filterActive = true,
    bool filterDeleted = true,
  }) async {
    var query = _supabase.from('marketing_cases').select('''
            *,
            marketing_avaliacoes (*)
          ''');

    if (filterDeleted) {
      query = query.isFilter('deletado_em', null);
    }

    final response = filterActive ? await query.eq('ativo', true) : await query;

    return (response as List).map((json) {
      // O join vem como 'marketing_avaliacoes', passamos para 'avaliacoes'
      // que é a chave esperada pelo fromJson na entidade de Domínio
      if (json['marketing_avaliacoes'] != null) {
        json['avaliacoes'] = json['marketing_avaliacoes'];
      }
      return MarketingCase.fromJson(json);
    }).toList();
  }

  Future<List<MarketingCase>> _fetchRemoteCasesCompatible() async {
    final strategies = <({bool filterActive, bool filterDeleted})>[
      (filterActive: false, filterDeleted: true),
      (filterActive: true, filterDeleted: false),
      (filterActive: false, filterDeleted: false),
    ];

    PostgrestException? lastError;
    for (final s in strategies) {
      try {
        return await _fetchRemoteCases(
          filterActive: s.filterActive,
          filterDeleted: s.filterDeleted,
        );
      } on PostgrestException catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) throw lastError;
    throw const PostgrestException(message: 'Falha ao buscar marketing_cases');
  }

  @override
  Future<List<MarketingCase>> getLocalCases() async {
    final db = await _database;
    final userId = _scopedUserId();
    // Sem user_id resolvido: não varrer o cache inteiro (evita vazamento e
    // também evita “lista vazia” falsa quando o filtro seria impossível).
    if (userId.isEmpty) {
      AppLogger.warning(
        'getLocalCases sem user_id — retornando vazio sem apagar cache',
        tag: 'MarketingRepo',
      );
      return const [];
    }
    final List<Map<String, dynamic>> maps = await db.query(
      'marketing_cases_cache',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    return maps.map((map) {
      final data = jsonDecode(map['data'] as String);
      return MarketingCase.fromJson(data);
    }).toList();
  }

  @override
  Future<void> saveToCache(List<MarketingCase> cases) async {
    final db = await _database;
    final userId = _scopedUserId();

    // 🛡 Nunca delete-all sem user_id — isso apagava o cache de todos no device.
    if (userId.isEmpty) {
      AppLogger.warning(
        'saveToCache ignorado: user_id vazio (bootstrap/logout)',
        tag: 'MarketingRepo',
      );
      return;
    }

    final Batch batch = db.batch();
    batch.delete(
      'marketing_cases_cache',
      where: 'user_id = ?',
      whereArgs: [userId],
    );

    for (final mc in cases) {
      batch.insert('marketing_cases_cache', {
        'id': mc.id,
        'user_id': userId,
        'data': jsonEncode(mc.toJson()),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit(noResult: true);
  }

  @override
  Future<MarketingCase> getById(String id) async {
    final db = await _database;
    final userId = _scopedUserId();
    final maps = userId.isEmpty
        ? await db.query(
            'marketing_cases_cache',
            where: 'id = ?',
            whereArgs: [id],
          )
        : await db.query(
            'marketing_cases_cache',
            where: 'id = ? AND user_id = ?',
            whereArgs: [id, userId],
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
    final userId = _scopedUserId();
    if (userId.isEmpty) {
      AppLogger.warning(
        'saveSingleToCache ignorado: user_id vazio',
        tag: 'MarketingRepo',
      );
      return;
    }
    await db.insert('marketing_cases_cache', {
      'id': marketingCase.id,
      'user_id': userId,
      'data': jsonEncode(marketingCase.toJson()),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  @override
  Future<MarketingCase> saveCase(MarketingCase marketingCase) async {
    final userId = _scopedUserId();
    if (userId.isEmpty) {
      throw StateError('Usuario nao autenticado.');
    }

    // 0. Persistir localmente como pending_sync ANTES de ir ao Supabase
    //    Garante que o case nao seja perdido se o app morrer durante o upload
    final pendingCase = MarketingCase.fromJson({
      ...marketingCase.toJson(),
      'user_id': userId,
      'sync_status': 'pending_sync',
    });
    await saveSingleToCache(pendingCase);

    // 1. Dados do case principal (exclui avaliacoes — tabela separada)
    final caseJson = marketingCase.toJson()
      ..remove('avaliacoes'); // Não existe na tabela principal

    // Campos ROI ficam no próprio registro (já estão em toJson via spread de roi)
    // atualizado_em é o momento local — o DB tem default now() mas podemos forçar
    caseJson['user_id'] = userId;
    caseJson['atualizado_em'] = DateTime.now().toIso8601String();
    caseJson['sync_status'] = 'synced';

    // 2. Upsert do case principal
    final response = await _supabase
        .from('marketing_cases')
        .upsert(caseJson)
        .select()
        .single();

    // Garantir que ativo está presente na resposta (pode ser null em schemas antigos)
    final responseWithDefaults = {'ativo': true, ...response};
    final savedCase = MarketingCase.fromJson(responseWithDefaults);

    // 3. Salva cada avaliação na tabela filha
    if (marketingCase.avaliacoes.isNotEmpty) {
      final avaliacoesBatch = marketingCase.avaliacoes.map((av) {
        return {
          'id': av.id,
          'case_id': savedCase.id,
          'user_id': userId,
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
    final userId = _scopedUserId();
    // Rascunho: salva apenas localmente, com status=draft e syncStatus=local_only
    final draftCase = MarketingCase.fromJson({
      ...marketingCase.toJson(),
      if (userId.isNotEmpty) 'user_id': userId,
      'status': MarketingCaseStatus.draft.toValue(),
      'sync_status': 'local_only',
      'atualizado_em': DateTime.now().toIso8601String(),
    });

    // Persiste no cache local
    await saveSingleToCache(draftCase);

    return draftCase;
  }
}
