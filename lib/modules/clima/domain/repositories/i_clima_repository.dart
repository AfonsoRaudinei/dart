import '../entities/clima_atual.dart';
import '../entities/previsao_horaria.dart';
import '../entities/previsao_diaria.dart';
import '../entities/alerta_meteorologico.dart';

/// Contrato do repositório de clima.
/// A implementação concreta fica em data/repositories/.
abstract class IClimaRepository {
  /// Retorna o clima atual para a coordenada informada.
  Future<ClimaAtual> getClimaAtual({
    required double lat,
    required double lon,
  });

  /// Retorna previsão horária para as próximas [horas] horas (padrão 48h).
  Future<List<PrevisaoHoraria>> getPrevisaoHoraria({
    required double lat,
    required double lon,
    int horas = 48,
  });

  /// Retorna previsão diária para os próximos [dias] dias (padrão 7 dias).
  Future<List<PrevisaoDiaria>> getPrevisaoSemanal({
    required double lat,
    required double lon,
    int dias = 7,
  });

  /// Retorna alertas meteorológicos ativos para a coordenada informada.
  Future<List<AlertaMeteorologico>> getAlertas({
    required double lat,
    required double lon,
  });
}
