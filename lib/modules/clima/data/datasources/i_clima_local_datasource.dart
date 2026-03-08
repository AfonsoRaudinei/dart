import '../../domain/entities/clima_atual.dart';
import '../../domain/entities/previsao_horaria.dart';
import '../../domain/entities/previsao_diaria.dart';

/// Contrato para o datasource local (cache SQLite — offline-first).
/// Garante que o usuário acesse os últimos dados mesmo sem conectividade.
abstract class IClimaLocalDatasource {
  /// Persiste o clima atual em cache local.
  Future<void> saveClimaAtual(ClimaAtual clima);

  /// Retorna o último clima salvo para as coordenadas, ou null se não houver cache.
  Future<ClimaAtual?> getCachedClimaAtual({
    required double lat,
    required double lon,
  });

  /// Persiste a previsão horária em cache local.
  Future<void> savePrevisaoHoraria(List<PrevisaoHoraria> previsoes);

  /// Retorna a previsão horária em cache, ou lista vazia se não houver.
  Future<List<PrevisaoHoraria>> getCachedPrevisaoHoraria({
    required double lat,
    required double lon,
  });

  /// Persiste a previsão semanal em cache local.
  Future<void> savePrevisaoSemanal(List<PrevisaoDiaria> previsoes);

  /// Retorna a previsão semanal em cache, ou lista vazia se não houver.
  Future<List<PrevisaoDiaria>> getCachedPrevisaoSemanal({
    required double lat,
    required double lon,
  });

  /// Remove dados de clima expirados (TTL: 15 minutos).
  Future<void> evictExpired();
}
