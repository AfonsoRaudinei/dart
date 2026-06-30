import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/domain/entities/alerta_meteorologico.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/domain/repositories/i_clima_repository.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';

void main() {
  group('climaAtualProvider', () {
    test(
      'repository fake via override retorna ClimaAtual preenchido',
      () async {
        final expected = fakeClimaAtual();
        final repository = FakeClimaRepository(result: expected);
        final container = ProviderContainer(
          overrides: [climaRepositoryProvider.overrideWithValue(repository)],
        );
        addTearDown(container.dispose);

        expect(container.read(climaRepositoryProvider), same(repository));
        expect(
          await container
              .read(climaRepositoryProvider)
              .getClimaAtual(lat: -10.18, lon: -48.33),
          same(expected),
        );
      },
    );

    test('falha técnica expõe mensagem sanitizada', () async {
      final container = ProviderContainer(
        overrides: [
          climaLocationProvider.overrideWith(
            (ref) async => (lat: -10.18, lon: -48.33),
          ),
          climaRepositoryProvider.overrideWithValue(
            FakeClimaRepository(error: Exception('falha técnica')),
          ),
        ],
      );
      addTearDown(container.dispose);

      await expectLater(
        container.read(climaAtualProvider.future),
        throwsA(
          predicate(
            (e) =>
                e is ClimaForecastUnavailableException &&
                e.toString() == 'Previsão indisponível. Verifique sua conexão.',
          ),
        ),
      );
    });
  });
}

class FakeClimaRepository implements IClimaRepository {
  FakeClimaRepository({this.result, this.error});

  final ClimaAtual? result;
  final Object? error;

  @override
  Future<ClimaAtual> getClimaAtual({
    required double lat,
    required double lon,
  }) async {
    if (error != null) throw error!;
    return result!;
  }

  @override
  Future<List<AlertaMeteorologico>> getAlertas({
    required double lat,
    required double lon,
  }) async => [];

  @override
  Future<List<PrevisaoHoraria>> getPrevisaoHoraria({
    required double lat,
    required double lon,
    int horas = 48,
  }) async => [];

  @override
  Future<List<PrevisaoDiaria>> getPrevisaoSemanal({
    required double lat,
    required double lon,
    int dias = 7,
  }) async => [];
}

ClimaAtual fakeClimaAtual() {
  final now = DateTime(2026, 5, 31, 12);
  return ClimaAtual(
    temperatura: 28,
    sensacaoTermica: 30,
    condicao: 'céu limpo',
    condicaoCodigo: '01d',
    ventoVelocidade: 12,
    ventoDirecao: 'NE',
    umidade: 55,
    precipitacao: 0,
    pressao: 1012,
    visibilidade: 10,
    coberturaNuvens: 5,
    indiceUV: 7,
    nascerSol: DateTime(2026, 5, 31, 6),
    porSol: DateTime(2026, 5, 31, 18),
    latitude: -10.18,
    longitude: -48.33,
    cidade: 'Palmas',
    atualizadoEm: now,
  );
}
