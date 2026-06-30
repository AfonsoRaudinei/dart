import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/config/clima_config.dart';
import 'package:soloforte_app/modules/clima/data/datasources/google_weather_remote_datasource.dart';
import 'package:soloforte_app/modules/clima/data/datasources/i_clima_local_datasource.dart';
import 'package:soloforte_app/modules/clima/data/datasources/i_clima_remote_datasource.dart';
import 'package:soloforte_app/modules/clima/data/repositories/clima_repository_impl.dart';
import 'package:soloforte_app/modules/clima/domain/entities/alerta_meteorologico.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';

import 'clima_atual_test.dart' show fakeClimaAtual;

void main() {
  group('fallback remoto', () {
    // Depende de GOOGLE_WEATHER_API_KEY ausente no ambiente de teste.
    // Em CI com key configurada, este cenário não cobre o fallback via provider.
    test(
      'Google falha e chama fallback OpenWeather fake',
      () async {
        final expected = fakeClimaAtual();
        final fallback = FakeRemoteDatasource(result: expected);
        final google = GoogleWeatherRemoteDatasource(fallback: fallback);

        expect(
          await google.fetchClimaAtual(lat: -10.18, lon: -48.33),
          same(expected),
        );
        expect(fallback.climaAtualCalls, 1);
      },
      skip: ClimaConfig.googleWeatherApiKey.isNotEmpty
          ? 'GOOGLE_WEATHER_API_KEY configurada no ambiente de teste.'
          : false,
    );

    test('ambas as fontes falham e provider emite erro sanitizado', () async {
      final container = ProviderContainer(
        overrides: [
          climaLocationProvider.overrideWith(
            (ref) async => (lat: -10.18, lon: -48.33),
          ),
          climaRepositoryProvider.overrideWithValue(
            ClimaRepositoryImpl(
              remote: FakeRemoteDatasource(error: Exception('Google falhou')),
              local: FakeLocalDatasource(),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(climaAtualProvider.future),
        throwsA(isA<ClimaForecastUnavailableException>()),
      );
    });

    test(
      'cache existente é retornado quando repository local tem dado',
      () async {
        final cached = fakeClimaAtual();
        final repository = ClimaRepositoryImpl(
          remote: FakeRemoteDatasource(error: Exception('offline')),
          local: FakeLocalDatasource(cachedClimaAtual: cached),
        );

        expect(
          await repository.getClimaAtual(lat: -10.18, lon: -48.33),
          same(cached),
        );
      },
    );
  });
}

class FakeRemoteDatasource implements IClimaRemoteDatasource {
  FakeRemoteDatasource({this.result, this.error});

  final ClimaAtual? result;
  final Object? error;
  int climaAtualCalls = 0;

  @override
  Future<ClimaAtual> fetchClimaAtual({
    required double lat,
    required double lon,
  }) async {
    climaAtualCalls++;
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<List<AlertaMeteorologico>> fetchAlertas({
    required double lat,
    required double lon,
  }) async => [];

  @override
  Future<List<PrevisaoHoraria>> fetchPrevisaoHoraria({
    required double lat,
    required double lon,
    required int horas,
  }) async => [];

  @override
  Future<List<PrevisaoDiaria>> fetchPrevisaoSemanal({
    required double lat,
    required double lon,
    required int dias,
  }) async => [];
}

class FakeLocalDatasource implements IClimaLocalDatasource {
  FakeLocalDatasource({this.cachedClimaAtual});

  final ClimaAtual? cachedClimaAtual;

  @override
  Future<void> evictExpired() async {}

  @override
  Future<ClimaAtual?> getCachedClimaAtual({
    required double lat,
    required double lon,
  }) async => cachedClimaAtual;

  @override
  Future<List<PrevisaoHoraria>> getCachedPrevisaoHoraria({
    required double lat,
    required double lon,
  }) async => [];

  @override
  Future<List<PrevisaoDiaria>> getCachedPrevisaoSemanal({
    required double lat,
    required double lon,
  }) async => [];

  @override
  Future<void> saveClimaAtual(ClimaAtual clima) async {}

  @override
  Future<void> savePrevisaoHoraria(List<PrevisaoHoraria> previsoes) async {}

  @override
  Future<void> savePrevisaoSemanal(List<PrevisaoDiaria> previsoes) async {}
}
