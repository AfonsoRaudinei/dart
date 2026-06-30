import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../../../../core/config/clima_config.dart';
import '../../../../core/database/database_helper.dart';
import '../../domain/entities/clima_atual.dart';
import '../../domain/entities/previsao_horaria.dart';
import '../../domain/entities/previsao_diaria.dart';
import '../datasources/i_clima_local_datasource.dart';

/// Implementação do datasource local de clima usando SQLite.
///
/// Tabelas gerenciadas (criadas na migração V20):
///   - [clima_atual_cache]      → última condição atual por coordenada
///   - [clima_horaria_cache]    → previsão horária (lista JSON)
///   - [clima_diaria_cache]     → previsão semanal (lista JSON)
///
/// TTL definido em [ClimaConfig.cacheTtl] (15 minutos).
/// Registros expirados são removidos por [evictExpired].
class ClimaLocalDatasource implements IClimaLocalDatasource {
  Future<Database> get _db async => DatabaseHelper.instance.database;

  // ─── Chave de cache por coordenada (arredondada a 2 decimais = ~1km) ────────

  static String _key(double lat, double lon) =>
      '${lat.toStringAsFixed(2)},${lon.toStringAsFixed(2)}';

  // ─── Clima Atual ─────────────────────────────────────────────────────────────

  @override
  Future<void> saveClimaAtual(ClimaAtual clima) async {
    final db = await _db;
    await db.insert(
      'clima_atual_cache',
      {
        'cache_key': _key(clima.latitude, clima.longitude),
        'temperatura': clima.temperatura,
        'sensacao_termica': clima.sensacaoTermica,
        'condicao': clima.condicao,
        'condicao_codigo': clima.condicaoCodigo,
        'vento_velocidade': clima.ventoVelocidade,
        'vento_direcao': clima.ventoDirecao,
        'umidade': clima.umidade,
        'precipitacao': clima.precipitacao,
        'pressao': clima.pressao,
        'visibilidade': clima.visibilidade,
        'cobertura_nuvens': clima.coberturaNuvens,
        'indice_uv': clima.indiceUV,
        'nascer_sol': clima.nascerSol.toIso8601String(),
        'por_sol': clima.porSol.toIso8601String(),
        'latitude': clima.latitude,
        'longitude': clima.longitude,
        'cidade': clima.cidade,
        'atualizado_em': clima.atualizadoEm.toIso8601String(),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<ClimaAtual?> getCachedClimaAtual({
    required double lat,
    required double lon,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'clima_atual_cache',
      where: 'cache_key = ?',
      whereArgs: [_key(lat, lon)],
      limit: 1,
    );

    if (rows.isEmpty) return null;
    final row = rows.first;

    if (_isExpired(row['cached_at'] as String)) {
      await db.delete(
        'clima_atual_cache',
        where: 'cache_key = ?',
        whereArgs: [_key(lat, lon)],
      );
      return null;
    }

    return ClimaAtual(
      temperatura: (row['temperatura'] as num).toDouble(),
      sensacaoTermica: (row['sensacao_termica'] as num).toDouble(),
      condicao: row['condicao'] as String,
      condicaoCodigo: row['condicao_codigo'] as String,
      ventoVelocidade: (row['vento_velocidade'] as num).toDouble(),
      ventoDirecao: row['vento_direcao'] as String,
      umidade: row['umidade'] as int,
      precipitacao: (row['precipitacao'] as num).toDouble(),
      pressao: (row['pressao'] as num).toDouble(),
      visibilidade: (row['visibilidade'] as num).toDouble(),
      coberturaNuvens: row['cobertura_nuvens'] as int,
      indiceUV: row['indice_uv'] as int,
      nascerSol: DateTime.parse(row['nascer_sol'] as String),
      porSol: DateTime.parse(row['por_sol'] as String),
      latitude: (row['latitude'] as num).toDouble(),
      longitude: (row['longitude'] as num).toDouble(),
      cidade: row['cidade'] as String,
      atualizadoEm: DateTime.parse(row['atualizado_em'] as String),
    );
  }

  // ─── Previsão Horária ─────────────────────────────────────────────────────────

  @override
  Future<void> savePrevisaoHoraria(List<PrevisaoHoraria> previsoes) async {
    if (previsoes.isEmpty) return;
    final db = await _db;
    // Usa lat/lon do primeiro item não disponível — chave genérica via JSON
    await db.insert(
      'clima_horaria_cache',
      {
        'cache_key': 'horaria', // refinado com lat/lon nos próximos steps
        'payload': jsonEncode(previsoes.map(_horariaToJson).toList()),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<PrevisaoHoraria>> getCachedPrevisaoHoraria({
    required double lat,
    required double lon,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'clima_horaria_cache',
      where: 'cache_key = ?',
      whereArgs: ['horaria'],
      limit: 1,
    );

    if (rows.isEmpty) return [];
    final row = rows.first;
    if (_isExpired(row['cached_at'] as String)) return [];

    final list = jsonDecode(row['payload'] as String) as List<dynamic>;
    return list.map((j) => _horariaFromJson(j as Map<String, dynamic>)).toList();
  }

  // ─── Previsão Diária ─────────────────────────────────────────────────────────

  @override
  Future<void> savePrevisaoSemanal(List<PrevisaoDiaria> previsoes) async {
    if (previsoes.isEmpty) return;
    final db = await _db;
    await db.insert(
      'clima_diaria_cache',
      {
        'cache_key': 'diaria',
        'payload': jsonEncode(previsoes.map(_diariaToJson).toList()),
        'cached_at': DateTime.now().toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<PrevisaoDiaria>> getCachedPrevisaoSemanal({
    required double lat,
    required double lon,
  }) async {
    final db = await _db;
    final rows = await db.query(
      'clima_diaria_cache',
      where: 'cache_key = ?',
      whereArgs: ['diaria'],
      limit: 1,
    );

    if (rows.isEmpty) return [];
    final row = rows.first;
    if (_isExpired(row['cached_at'] as String)) return [];

    final list = jsonDecode(row['payload'] as String) as List<dynamic>;
    return list.map((j) => _diariaFromJson(j as Map<String, dynamic>)).toList();
  }

  // ─── Evict ───────────────────────────────────────────────────────────────────

  @override
  Future<void> evictExpired() async {
    final db = await _db;
    final cutoff = DateTime.now()
        .subtract(ClimaConfig.cacheTtl)
        .toIso8601String();

    await Future.wait([
      db.delete('clima_atual_cache', where: 'cached_at < ?', whereArgs: [cutoff]),
      db.delete('clima_horaria_cache', where: 'cached_at < ?', whereArgs: [cutoff]),
      db.delete('clima_diaria_cache', where: 'cached_at < ?', whereArgs: [cutoff]),
    ]);
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  bool _isExpired(String cachedAt) {
    final age = DateTime.now().difference(DateTime.parse(cachedAt));
    return age > ClimaConfig.cacheTtl;
  }

  Map<String, dynamic> _horariaToJson(PrevisaoHoraria h) => {
        'hora': h.hora.toIso8601String(),
        'temperatura': h.temperatura,
        'precipitacao': h.precipitacao,
        'probabilidade_chuva': h.probabilidadeChuva,
        'condicao': h.condicao,
        'condicao_codigo': h.condicaoCodigo,
      };

  PrevisaoHoraria _horariaFromJson(Map<String, dynamic> j) => PrevisaoHoraria(
        hora: DateTime.parse(j['hora'] as String),
        temperatura: (j['temperatura'] as num).toDouble(),
        precipitacao: (j['precipitacao'] as num).toDouble(),
        probabilidadeChuva: j['probabilidade_chuva'] as int,
        condicao: j['condicao'] as String,
        condicaoCodigo: j['condicao_codigo'] as String,
      );

  Map<String, dynamic> _diariaToJson(PrevisaoDiaria d) => {
        'data': d.data.toIso8601String(),
        'temp_min': d.tempMin,
        'temp_max': d.tempMax,
        'precipitacao': d.precipitacao,
        'vento_medio': d.ventoMedio,
        'condicao': d.condicao,
        'condicao_codigo': d.condicaoCodigo,
        'tem_alerta': d.temAlerta,
      };

  PrevisaoDiaria _diariaFromJson(Map<String, dynamic> j) => PrevisaoDiaria(
        data: DateTime.parse(j['data'] as String),
        tempMin: (j['temp_min'] as num).toDouble(),
        tempMax: (j['temp_max'] as num).toDouble(),
        precipitacao: (j['precipitacao'] as num).toDouble(),
        ventoMedio: (j['vento_medio'] as num).toDouble(),
        condicao: j['condicao'] as String,
        condicaoCodigo: j['condicao_codigo'] as String,
        temAlerta: j['tem_alerta'] as bool,
      );
}
