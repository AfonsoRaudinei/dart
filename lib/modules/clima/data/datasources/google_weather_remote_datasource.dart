import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../../../core/config/clima_config.dart';
import '../../../../core/network/network_policy.dart';
import '../../domain/entities/alerta_meteorologico.dart';
import '../../domain/entities/clima_atual.dart';
import '../../domain/entities/previsao_diaria.dart';
import '../../domain/entities/previsao_horaria.dart';
import '../services/reverse_geocoder.dart';
import '../datasources/i_clima_remote_datasource.dart';

/// Implementação principal usando Google Maps Platform Weather API.
///
/// Endpoints:
/// - /v1/currentConditions:lookup
/// - /v1/forecast/hours:lookup
/// - /v1/forecast/days:lookup
/// - /v1/publicAlerts:lookup
///
/// Se falhar e houver fallback configurado, delega para o datasource fallback.
class GoogleWeatherRemoteDatasource implements IClimaRemoteDatasource {
  final http.Client _client;
  final IClimaRemoteDatasource? _fallback;

  GoogleWeatherRemoteDatasource({
    http.Client? client,
    IClimaRemoteDatasource? fallback,
  })  : _client = client ?? http.Client(),
        _fallback = fallback;

  @override
  Future<ClimaAtual> fetchClimaAtual({
    required double lat,
    required double lon,
  }) async {
    return _withFallback(
      () async {
        final current = await _fetchCurrent(lat, lon);
        final day = await _fetchFirstForecastDay(lat, lon);

        final weather = _map(current['weatherCondition']);
        final wind = _map(current['wind']);
        final windDirection = _map(wind['direction']);
        final windSpeed = _map(wind['speed']);
        final precipitation = _map(current['precipitation']);
        final qpf = _map(precipitation['qpf']);
        final airPressure = _map(current['airPressure']);
        final visibility = _map(current['visibility']);
        final sunEvents = _map(day['sunEvents']);

        final isDaytime = current['isDaytime'] == true;
        final condType = _readString(weather['type']);

        final cidade = await ReverseGeocoder.instance.resolveCityLabel(
          latitude: lat,
          longitude: lon,
        );

        return ClimaAtual(
          temperatura: _readDegrees(current['temperature']),
          sensacaoTermica: _readDegrees(current['feelsLikeTemperature']),
          condicao: _readLocalizedText(weather['description'], fallback: condType),
          condicaoCodigo: _googleTypeToOwmIcon(condType, isDaytime),
          ventoVelocidade: _readNum(windSpeed['value']), // km/h (metric)
          ventoDirecao: _readCardinalOrDegrees(windDirection),
          umidade: _readInt(current['relativeHumidity']),
          precipitacao: _readNum(qpf['quantity']), // mm
          pressao: _readNum(airPressure['meanSeaLevelMillibars']),
          visibilidade: _readNum(visibility['distance']), // km
          coberturaNuvens: _readInt(current['cloudCover']),
          indiceUV: _readInt(current['uvIndex']),
          nascerSol: _parseDateTime(sunEvents['sunriseTime']) ?? DateTime.now(),
          porSol: _parseDateTime(sunEvents['sunsetTime']) ?? DateTime.now(),
          latitude: lat,
          longitude: lon,
          cidade: cidade,
          atualizadoEm: _parseDateTime(current['currentTime']) ?? DateTime.now(),
        );
      },
      fallback: () => _fallback?.fetchClimaAtual(lat: lat, lon: lon),
    );
  }

  @override
  Future<List<PrevisaoHoraria>> fetchPrevisaoHoraria({
    required double lat,
    required double lon,
    required int horas,
  }) async {
    return _withFallback(
      () async {
        final data = await _get(
          '/v1/forecast/hours:lookup',
          params: {
            'location.latitude': lat.toStringAsFixed(6),
            'location.longitude': lon.toStringAsFixed(6),
            'hours': horas.toString(),
            'unitsSystem': 'METRIC',
            'languageCode': 'pt-BR',
          },
        );

        final list = _list(data['forecastHours']);
        return list
            .map((e) => _parsePrevisaoHoraria(_map(e)))
            .take(horas)
            .toList();
      },
      fallback: () => _fallback?.fetchPrevisaoHoraria(
        lat: lat,
        lon: lon,
        horas: horas,
      ),
    );
  }

  @override
  Future<List<PrevisaoDiaria>> fetchPrevisaoSemanal({
    required double lat,
    required double lon,
    required int dias,
  }) async {
    return _withFallback(
      () async {
        final data = await _get(
          '/v1/forecast/days:lookup',
          params: {
            'location.latitude': lat.toStringAsFixed(6),
            'location.longitude': lon.toStringAsFixed(6),
            'days': dias.toString(),
            'unitsSystem': 'METRIC',
            'languageCode': 'pt-BR',
          },
        );

        final list = _list(data['forecastDays']);
        return list
            .map((e) => _parsePrevisaoDiaria(_map(e)))
            .take(dias)
            .toList();
      },
      fallback: () => _fallback?.fetchPrevisaoSemanal(
        lat: lat,
        lon: lon,
        dias: dias,
      ),
    );
  }

  @override
  Future<List<AlertaMeteorologico>> fetchAlertas({
    required double lat,
    required double lon,
  }) async {
    return _withFallback(
      () async {
        final data = await _get(
          '/v1/publicAlerts:lookup',
          params: {
            'location.latitude': lat.toStringAsFixed(6),
            'location.longitude': lon.toStringAsFixed(6),
            'languageCode': 'pt-BR',
          },
        );

        final list = _list(data['weatherAlerts']);
        return list.map((e) => _parseAlerta(_map(e))).toList();
      },
      fallback: () => _fallback?.fetchAlertas(lat: lat, lon: lon),
    );
  }

  // ─────────────────────────── HTTP ──────────────────────────────────────────

  Future<Map<String, dynamic>> _get(
    String path, {
    required Map<String, String> params,
  }) async {
    final apiKey = ClimaConfig.googleWeatherApiKey;
    if (apiKey.isEmpty) {
      debugPrint(
        '[Clima] GOOGLE_WEATHER_API_KEY ausente. Tentando OpenWeather...',
      );
      throw Exception(
        '[GoogleWeather] GOOGLE_WEATHER_API_KEY não configurada via --dart-define.',
      );
    }

    final uri = Uri.parse('${ClimaConfig.googleWeatherBaseUrl}$path').replace(
      queryParameters: {'key': apiKey, ...params},
    );

    final response = await NetworkPolicy.withRetry(() => _client.get(uri));

    if (response.statusCode != 200) {
      throw Exception(
        '[GoogleWeather] HTTP ${response.statusCode}: ${response.body}',
      );
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> _fetchCurrent(double lat, double lon) {
    return _get(
      '/v1/currentConditions:lookup',
      params: {
        'location.latitude': lat.toStringAsFixed(6),
        'location.longitude': lon.toStringAsFixed(6),
        'unitsSystem': 'METRIC',
        'languageCode': 'pt-BR',
      },
    );
  }

  Future<Map<String, dynamic>> _fetchFirstForecastDay(double lat, double lon) async {
    final data = await _get(
      '/v1/forecast/days:lookup',
      params: {
        'location.latitude': lat.toStringAsFixed(6),
        'location.longitude': lon.toStringAsFixed(6),
        'days': '1',
        'unitsSystem': 'METRIC',
        'languageCode': 'pt-BR',
      },
    );

    final list = _list(data['forecastDays']);
    if (list.isEmpty) return <String, dynamic>{};
    return _map(list.first);
  }

  // ─────────────────────────── Parse ─────────────────────────────────────────

  PrevisaoHoraria _parsePrevisaoHoraria(Map<String, dynamic> h) {
    final weather = _map(h['weatherCondition']);
    final precipitation = _map(h['precipitation']);
    final probability = _map(precipitation['probability']);
    final qpf = _map(precipitation['qpf']);

    final condType = _readString(weather['type']);
    final isDaytime = h['isDaytime'] == true;

    return PrevisaoHoraria(
      hora: _parseDateTime(_map(h['interval'])['startTime']) ?? DateTime.now(),
      temperatura: _readDegrees(h['temperature']),
      precipitacao: _readNum(qpf['quantity']),
      probabilidadeChuva: _readInt(probability['percent']),
      condicao: _readLocalizedText(weather['description'], fallback: condType),
      condicaoCodigo: _googleTypeToOwmIcon(condType, isDaytime),
    );
  }

  PrevisaoDiaria _parsePrevisaoDiaria(Map<String, dynamic> d) {
    final daytime = _map(d['daytimeForecast']);
    final nighttime = _map(d['nighttimeForecast']);

    final dayWeather = _map(daytime['weatherCondition']);
    final nightWeather = _map(nighttime['weatherCondition']);
    final dayPrecip = _map(_map(daytime['precipitation'])['qpf']);
    final nightPrecip = _map(_map(nighttime['precipitation'])['qpf']);

    final dayWindSpeed = _readNum(_map(_map(daytime['wind'])['speed'])['value']);
    final nightWindSpeed = _readNum(_map(_map(nighttime['wind'])['speed'])['value']);

    final condType = _readString(dayWeather['type']).isNotEmpty
        ? _readString(dayWeather['type'])
        : _readString(nightWeather['type']);

    final condText = _readLocalizedText(
      dayWeather['description'],
      fallback: _readLocalizedText(nightWeather['description'], fallback: condType),
    );

    return PrevisaoDiaria(
      data: _parseDateTime(_map(d['interval'])['startTime']) ?? DateTime.now(),
      tempMin: _readDegrees(d['minTemperature']),
      tempMax: _readDegrees(d['maxTemperature']),
      precipitacao: _readNum(dayPrecip['quantity']) + _readNum(nightPrecip['quantity']),
      ventoMedio: _avg([dayWindSpeed, nightWindSpeed]),
      condicao: condText,
      condicaoCodigo: _googleTypeToOwmIcon(condType, true),
      temAlerta: false,
    );
  }

  AlertaMeteorologico _parseAlerta(Map<String, dynamic> a) {
    final titulo = _readLocalizedText(a['alertTitle'], fallback: 'Alerta meteorológico');
    final eventType = _readString(a['eventType']).toLowerCase();

    return AlertaMeteorologico(
      id: _readString(a['alertId']).isNotEmpty
          ? _readString(a['alertId'])
          : '${titulo}_${a['startTime']}',
      titulo: titulo,
      descricao: _readString(a['description']).isNotEmpty
          ? _readString(a['description'])
          : 'Sem descrição detalhada.',
      severidade: _parseSeveridade(_readString(a['severity'])),
      tipo: _parseTipo(eventType),
      inicio: _parseDateTime(a['startTime']) ?? DateTime.now(),
      fim: _parseDateTime(a['expirationTime']) ?? DateTime.now().add(const Duration(hours: 6)),
    );
  }

  // ─────────────────────────── Helpers ───────────────────────────────────────

  Future<T> _withFallback<T>(
    Future<T> Function() primary, {
    required Future<T>? Function() fallback,
  }) async {
    try {
      return await primary();
    } catch (_) {
      final fb = fallback();
      if (fb != null) return await fb;
      rethrow;
    }
  }

  Map<String, dynamic> _map(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((k, v) => MapEntry(k.toString(), v));
    }
    return <String, dynamic>{};
  }

  List<dynamic> _list(dynamic value) => value is List ? value : const [];

  double _readNum(dynamic value, {double fallback = 0}) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  int _readInt(dynamic value, {int fallback = 0}) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) return int.tryParse(value) ?? fallback;
    return fallback;
  }

  String _readString(dynamic value, {String fallback = ''}) {
    if (value is String) return value;
    return fallback;
  }

  String _readLocalizedText(dynamic value, {String fallback = ''}) {
    if (value is String) return value;
    final map = _map(value);
    final text = map['text'];
    return text is String && text.isNotEmpty ? text : fallback;
  }

  double _readDegrees(dynamic metricObj) {
    final map = _map(metricObj);
    return _readNum(map['degrees']);
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value is! String || value.isEmpty) return null;
    return DateTime.tryParse(value)?.toLocal();
  }

  double _avg(List<double> values) {
    final valid = values.where((v) => v > 0).toList();
    if (valid.isEmpty) return 0;
    return valid.reduce((a, b) => a + b) / valid.length;
  }

  String _readCardinalOrDegrees(Map<String, dynamic> direction) {
    final cardinal = _readString(direction['cardinal']);
    if (cardinal.isNotEmpty) return _cardinalToPt(cardinal);

    final deg = _readInt(direction['degrees']);
    return _grauParaDirecao(deg);
  }

  String _cardinalToPt(String cardinal) {
    return switch (cardinal) {
      'NORTH' => 'N',
      'NORTHEAST' => 'NE',
      'EAST' => 'L',
      'SOUTHEAST' => 'SE',
      'SOUTH' => 'S',
      'SOUTHWEST' => 'SO',
      'WEST' => 'O',
      'NORTHWEST' => 'NO',
      'NORTH_NORTHEAST' => 'NNE',
      'EAST_NORTHEAST' => 'ENE',
      'EAST_SOUTHEAST' => 'ESE',
      'SOUTH_SOUTHEAST' => 'SSE',
      'SOUTH_SOUTHWEST' => 'SSO',
      'WEST_SOUTHWEST' => 'OSO',
      'WEST_NORTHWEST' => 'ONO',
      'NORTH_NORTHWEST' => 'NNO',
      _ => cardinal,
    };
  }

  static String _grauParaDirecao(int grau) {
    const direcoes = ['N', 'NE', 'L', 'SE', 'S', 'SO', 'O', 'NO'];
    return direcoes[((grau + 22) / 45).floor() % 8];
  }

  SeveridadeAlerta _parseSeveridade(String severity) {
    return switch (severity.toUpperCase()) {
      'EXTREME' => SeveridadeAlerta.extrema,
      'SEVERE' => SeveridadeAlerta.alta,
      'MODERATE' => SeveridadeAlerta.media,
      'MINOR' => SeveridadeAlerta.baixa,
      _ => SeveridadeAlerta.media,
    };
  }

  TipoAlerta _parseTipo(String eventType) {
    if (eventType.contains('storm') ||
        eventType.contains('thunder') ||
        eventType.contains('cyclone') ||
        eventType.contains('tornado')) {
      return TipoAlerta.tempestade;
    }

    if (eventType.contains('frost') ||
        eventType.contains('freez') ||
        eventType.contains('cold')) {
      return TipoAlerta.geada;
    }

    if (eventType.contains('rain') ||
        eventType.contains('flood') ||
        eventType.contains('hail') ||
        eventType.contains('snow')) {
      return TipoAlerta.chuvaIntensa;
    }

    if (eventType.contains('wind') || eventType.contains('gale')) {
      return TipoAlerta.ventoForte;
    }

    return TipoAlerta.temperaturaExtrema;
  }

  /// Mapeia tipos da Google Weather para códigos de ícone OpenWeather (`01d` etc)
  /// para manter compatibilidade visual da UI atual.
  String _googleTypeToOwmIcon(String type, bool isDaytime) {
    final suffix = isDaytime ? 'd' : 'n';
    final t = type.toUpperCase();

    if (t.contains('THUNDER') || t.contains('STORM') || t.contains('TORNADO')) {
      return '11$suffix';
    }
    if (t.contains('SNOW') || t.contains('BLIZZARD') || t.contains('FREEZ')) {
      return '13$suffix';
    }
    if (t.contains('DRIZZLE') || t.contains('SHOWERS')) {
      return '09$suffix';
    }
    if (t.contains('RAIN') || t.contains('MONSOON')) {
      return '10$suffix';
    }
    if (t.contains('FOG') || t.contains('HAZE') || t.contains('MIST')) {
      return '50$suffix';
    }
    if (t.contains('CLOUDY') || t.contains('OVERCAST')) {
      return '04$suffix';
    }
    if (t.contains('PARTLY') || t.contains('SCATTERED')) {
      return '02$suffix';
    }
    if (t.contains('CLEAR') || t.contains('SUNNY')) {
      return '01$suffix';
    }

    return '01$suffix';
  }
}
