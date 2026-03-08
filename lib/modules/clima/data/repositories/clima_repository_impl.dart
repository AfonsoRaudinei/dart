import '../../domain/entities/clima_atual.dart';
import '../../domain/entities/previsao_horaria.dart';
import '../../domain/entities/previsao_diaria.dart';
import '../../domain/entities/alerta_meteorologico.dart';
import '../../domain/repositories/i_clima_repository.dart';
import '../datasources/i_clima_local_datasource.dart';
import '../datasources/i_clima_remote_datasource.dart';

/// Implementação do [IClimaRepository].
///
/// Estratégia offline-first:
/// 1. Tenta buscar da API remota e atualiza o cache local.
/// 2. Em caso de falha de rede, retorna o cache SQLite.
/// 3. Cache com TTL de 15 minutos (evictExpired no datasource local).
class ClimaRepositoryImpl implements IClimaRepository {
  final IClimaRemoteDatasource _remote;
  final IClimaLocalDatasource _local;

  const ClimaRepositoryImpl({
    required IClimaRemoteDatasource remote,
    required IClimaLocalDatasource local,
  })  : _remote = remote,
        _local = local;

  @override
  Future<ClimaAtual> getClimaAtual({
    required double lat,
    required double lon,
  }) async {
    try {
      final clima = await _remote.fetchClimaAtual(lat: lat, lon: lon);
      await _local.saveClimaAtual(clima);
      return clima;
    } catch (_) {
      final cached = await _local.getCachedClimaAtual(lat: lat, lon: lon);
      if (cached != null) return cached;
      rethrow;
    }
  }

  @override
  Future<List<PrevisaoHoraria>> getPrevisaoHoraria({
    required double lat,
    required double lon,
    int horas = 48,
  }) async {
    try {
      final previsoes = await _remote.fetchPrevisaoHoraria(
        lat: lat,
        lon: lon,
        horas: horas,
      );
      await _local.savePrevisaoHoraria(previsoes);
      return previsoes;
    } catch (_) {
      return _local.getCachedPrevisaoHoraria(lat: lat, lon: lon);
    }
  }

  @override
  Future<List<PrevisaoDiaria>> getPrevisaoSemanal({
    required double lat,
    required double lon,
    int dias = 7,
  }) async {
    try {
      final previsoes = await _remote.fetchPrevisaoSemanal(
        lat: lat,
        lon: lon,
        dias: dias,
      );
      await _local.savePrevisaoSemanal(previsoes);
      return previsoes;
    } catch (_) {
      return _local.getCachedPrevisaoSemanal(lat: lat, lon: lon);
    }
  }

  @override
  Future<List<AlertaMeteorologico>> getAlertas({
    required double lat,
    required double lon,
  }) async {
    return _remote.fetchAlertas(lat: lat, lon: lon);
  }
}
