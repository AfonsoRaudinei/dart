import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/clima_config.dart';
import '../../../../core/network/network_policy.dart';
import '../../domain/entities/clima_atual.dart';
import '../../domain/entities/previsao_horaria.dart';
import '../../domain/entities/previsao_diaria.dart';
import '../../domain/entities/alerta_meteorologico.dart';
import '../datasources/i_clima_remote_datasource.dart';

/// Implementação do datasource remoto usando OpenWeatherMap One Call API 3.0.
///
/// Um único request à One Call API retorna:
///   - `current`  → clima atual
///   - `hourly`   → próximas 48 horas
///   - `daily`    → próximos 8 dias
///   - `alerts`   → alertas meteorológicos ativos
///
/// Docs: https://openweathermap.org/api/one-call-3
class OpenWeatherRemoteDatasource implements IClimaRemoteDatasource {
  final http.Client _client;

  OpenWeatherRemoteDatasource({http.Client? client})
      : _client = client ?? http.Client();

  // ─── URL builder ────────────────────────────────────────────────────────────

  Uri _buildUri(double lat, double lon) {
    return Uri.parse(ClimaConfig.openWeatherBaseUrl).replace(
      queryParameters: {
        'lat': lat.toStringAsFixed(6),
        'lon': lon.toStringAsFixed(6),
        'appid': ClimaConfig.openWeatherApiKey,
        'units': 'metric', // Celsius, km/h, mm
        'lang': 'pt_br',
        'exclude': 'minutely', // exclui dados por minuto (não usados)
      },
    );
  }

  // ─── Fetch único (cache de resposta interna) ────────────────────────────────

  Future<Map<String, dynamic>> _fetchRaw(double lat, double lon) async {
    final response = await NetworkPolicy.withRetry(
      () => _client.get(_buildUri(lat, lon)),
    );

    if (response.statusCode != 200) {
      throw Exception(
        '[OpenWeather] HTTP ${response.statusCode}: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  // ─── Interface ────────────────────────────────────────────────────────────

  @override
  Future<ClimaAtual> fetchClimaAtual({
    required double lat,
    required double lon,
  }) async {
    final data = await _fetchRaw(lat, lon);
    return _parseClimaAtual(data, lat, lon);
  }

  @override
  Future<List<PrevisaoHoraria>> fetchPrevisaoHoraria({
    required double lat,
    required double lon,
    required int horas,
  }) async {
    final data = await _fetchRaw(lat, lon);
    final hourly = data['hourly'] as List<dynamic>;
    return hourly
        .take(horas)
        .map((h) => _parsePrevisaoHoraria(h as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<PrevisaoDiaria>> fetchPrevisaoSemanal({
    required double lat,
    required double lon,
    required int dias,
  }) async {
    final data = await _fetchRaw(lat, lon);
    final daily = data['daily'] as List<dynamic>;
    return daily
        .take(dias)
        .map((d) => _parsePrevisaoDiaria(d as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<List<AlertaMeteorologico>> fetchAlertas({
    required double lat,
    required double lon,
  }) async {
    final data = await _fetchRaw(lat, lon);
    final alerts = data['alerts'] as List<dynamic>? ?? [];
    return alerts
        .map((a) => _parseAlerta(a as Map<String, dynamic>))
        .toList();
  }

  // ─── Parsers ────────────────────────────────────────────────────────────────

  ClimaAtual _parseClimaAtual(
    Map<String, dynamic> data,
    double lat,
    double lon,
  ) {
    final current = data['current'] as Map<String, dynamic>;
    final weather =
        (current['weather'] as List<dynamic>).first as Map<String, dynamic>;

    return ClimaAtual(
      temperatura: (current['temp'] as num).toDouble(),
      sensacaoTermica: (current['feels_like'] as num).toDouble(),
      condicao: weather['description'] as String,
      condicaoCodigo: weather['icon'] as String,
      ventoVelocidade: ((current['wind_speed'] as num) * 3.6).toDouble(), // m/s → km/h
      ventoDirecao: _grauParaDirecao(current['wind_deg'] as int),
      umidade: current['humidity'] as int,
      precipitacao: (((current['rain'] as Map<String, dynamic>?)?['1h']) as num? ?? 0).toDouble(),
      pressao: (current['pressure'] as num).toDouble(),
      visibilidade: ((current['visibility'] as num) / 1000).toDouble(), // m → km
      coberturaNuvens: current['clouds'] as int,
      indiceUV: (current['uvi'] as num).round(),
      nascerSol: DateTime.fromMillisecondsSinceEpoch(
        (current['sunrise'] as int) * 1000,
      ),
      porSol: DateTime.fromMillisecondsSinceEpoch(
        (current['sunset'] as int) * 1000,
      ),
      latitude: lat,
      longitude: lon,
      cidade: (data['timezone'] as String).split('/').last.replaceAll('_', ' '),
      atualizadoEm: DateTime.fromMillisecondsSinceEpoch(
        (current['dt'] as int) * 1000,
      ),
    );
  }

  PrevisaoHoraria _parsePrevisaoHoraria(Map<String, dynamic> h) {
    final weather =
        (h['weather'] as List<dynamic>).first as Map<String, dynamic>;

    return PrevisaoHoraria(
      hora: DateTime.fromMillisecondsSinceEpoch((h['dt'] as int) * 1000),
      temperatura: (h['temp'] as num).toDouble(),
      precipitacao: (((h['rain'] as Map<String, dynamic>?)?['1h']) as num? ?? 0).toDouble(),
      probabilidadeChuva: ((h['pop'] as num) * 100).round(),
      condicao: weather['description'] as String,
      condicaoCodigo: weather['icon'] as String,
    );
  }

  PrevisaoDiaria _parsePrevisaoDiaria(Map<String, dynamic> d) {
    final weather =
        (d['weather'] as List<dynamic>).first as Map<String, dynamic>;
    final temp = d['temp'] as Map<String, dynamic>;
    final hasAlert = ((d['alerts'] as List?)?.isNotEmpty) ?? false;

    return PrevisaoDiaria(
      data: DateTime.fromMillisecondsSinceEpoch((d['dt'] as int) * 1000),
      tempMin: (temp['min'] as num).toDouble(),
      tempMax: (temp['max'] as num).toDouble(),
      precipitacao: ((d['rain'] as num?) ?? 0).toDouble(),
      ventoMedio: ((d['wind_speed'] as num) * 3.6).toDouble(), // m/s → km/h
      condicao: weather['description'] as String,
      condicaoCodigo: weather['icon'] as String,
      temAlerta: hasAlert,
    );
  }

  AlertaMeteorologico _parseAlerta(Map<String, dynamic> a) {
    final evento = (a['event'] as String).toLowerCase();

    TipoAlerta tipo;
    if (evento.contains('tempest') || evento.contains('storm') || evento.contains('thunder')) {
      tipo = TipoAlerta.tempestade;
    } else if (evento.contains('geada') || evento.contains('frost') || evento.contains('freeze')) {
      tipo = TipoAlerta.geada;
    } else if (evento.contains('chuva') || evento.contains('rain') || evento.contains('flood')) {
      tipo = TipoAlerta.chuvaIntensa;
    } else if (evento.contains('vento') || evento.contains('wind')) {
      tipo = TipoAlerta.ventoForte;
    } else {
      tipo = TipoAlerta.temperaturaExtrema;
    }

    return AlertaMeteorologico(
      id: '${a['sender_name']}_${a['start']}',
      titulo: a['event'] as String,
      descricao: a['description'] as String,
      severidade: SeveridadeAlerta.alta, // OWM não retorna severidade estruturada
      tipo: tipo,
      inicio: DateTime.fromMillisecondsSinceEpoch((a['start'] as int) * 1000),
      fim: DateTime.fromMillisecondsSinceEpoch((a['end'] as int) * 1000),
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  /// Converte graus de vento (0–360°) para ponto cardeal (8 direções).
  static String _grauParaDirecao(int grau) {
    const direcoes = ['N', 'NE', 'L', 'SE', 'S', 'SO', 'O', 'NO'];
    return direcoes[((grau + 22) / 45).floor() % 8];
  }
}
