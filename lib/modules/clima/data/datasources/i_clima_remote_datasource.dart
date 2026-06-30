import '../../domain/entities/clima_atual.dart';
import '../../domain/entities/previsao_horaria.dart';
import '../../domain/entities/previsao_diaria.dart';
import '../../domain/entities/alerta_meteorologico.dart';

/// Contrato para o datasource remoto (API meteorológica).
/// A implementação concreta será vinculada ao provedor escolhido
/// (OpenWeather, Tomorrow.io, etc.) na camada data/.
abstract class IClimaRemoteDatasource {
  Future<ClimaAtual> fetchClimaAtual({
    required double lat,
    required double lon,
  });

  Future<List<PrevisaoHoraria>> fetchPrevisaoHoraria({
    required double lat,
    required double lon,
    required int horas,
  });

  Future<List<PrevisaoDiaria>> fetchPrevisaoSemanal({
    required double lat,
    required double lon,
    required int dias,
  });

  Future<List<AlertaMeteorologico>> fetchAlertas({
    required double lat,
    required double lon,
  });
}
