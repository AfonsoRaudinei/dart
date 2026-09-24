import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/data/datasources/i_clima_local_datasource.dart';
import 'package:soloforte_app/modules/clima/data/datasources/i_clima_remote_datasource.dart';
import 'package:soloforte_app/modules/clima/data/repositories/clima_repository_impl.dart';
import 'package:soloforte_app/modules/clima/domain/clima_fonte.dart';
import 'package:soloforte_app/modules/clima/domain/entities/alerta_meteorologico.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';

import 'clima_atual_test.dart' show fakeClimaAtual;

void main() {
  test('repository repassa fonte do clima atual ao cache horário', () async {
    final local = _RecordingLocal(
      climaAtual: fakeClimaAtual().copyWithFonte(ClimaFonte.googleWeather),
    );
    final repository = ClimaRepositoryImpl(
      remote: _FakeRemote(),
      local: local,
    );

    await repository.getPrevisaoHoraria(lat: -10.18, lon: -48.33, horas: 1);

    expect(local.horariaFonte, ClimaFonte.googleWeather);
  });

  test('repository repassa fonte do clima atual ao cache semanal', () async {
    final local = _RecordingLocal(
      climaAtual: fakeClimaAtual().copyWithFonte(ClimaFonte.openWeather),
    );
    final repository = ClimaRepositoryImpl(
      remote: _FakeRemote(),
      local: local,
    );

    await repository.getPrevisaoSemanal(lat: -10.18, lon: -48.33, dias: 1);

    expect(local.semanalFonte, ClimaFonte.openWeather);
  });
}

extension _ClimaAtualFonte on ClimaAtual {
  ClimaAtual copyWithFonte(ClimaFonte fonte) {
    return ClimaAtual(
      temperatura: temperatura,
      sensacaoTermica: sensacaoTermica,
      condicao: condicao,
      condicaoCodigo: condicaoCodigo,
      ventoVelocidade: ventoVelocidade,
      ventoDirecao: ventoDirecao,
      umidade: umidade,
      precipitacao: precipitacao,
      pressao: pressao,
      visibilidade: visibilidade,
      coberturaNuvens: coberturaNuvens,
      indiceUV: indiceUV,
      nascerSol: nascerSol,
      porSol: porSol,
      latitude: latitude,
      longitude: longitude,
      cidade: cidade,
      atualizadoEm: atualizadoEm,
      fonte: fonte,
    );
  }
}

class _FakeRemote implements IClimaRemoteDatasource {
  @override
  Future<ClimaAtual> fetchClimaAtual({
    required double lat,
    required double lon,
  }) async =>
      fakeClimaAtual();

  @override
  Future<List<PrevisaoHoraria>> fetchPrevisaoHoraria({
    required double lat,
    required double lon,
    required int horas,
  }) async => [
        PrevisaoHoraria(
          hora: DateTime(2026, 9, 24, 10),
          temperatura: 28,
          precipitacao: 0,
          probabilidadeChuva: 0,
          condicao: 'Ensolarado',
          condicaoCodigo: '01d',
        ),
      ];

  @override
  Future<List<PrevisaoDiaria>> fetchPrevisaoSemanal({
    required double lat,
    required double lon,
    required int dias,
  }) async => [
        PrevisaoDiaria(
          data: DateTime(2026, 9, 24),
          tempMin: 22,
          tempMax: 34,
          precipitacao: 0,
          ventoMedio: 8,
          condicao: 'Ensolarado',
          condicaoCodigo: '01d',
          temAlerta: false,
        ),
      ];

  @override
  Future<List<AlertaMeteorologico>> fetchAlertas({
    required double lat,
    required double lon,
  }) async =>
      [];
}

class _RecordingLocal implements IClimaLocalDatasource {
  _RecordingLocal({required this.climaAtual});

  final ClimaAtual climaAtual;
  ClimaFonte? horariaFonte;
  ClimaFonte? semanalFonte;

  @override
  Future<void> saveClimaAtual(ClimaAtual clima) async {}

  @override
  Future<ClimaAtual?> getCachedClimaAtual({
    required double lat,
    required double lon,
  }) async =>
      climaAtual;

  @override
  Future<void> savePrevisaoHoraria(
    List<PrevisaoHoraria> previsoes, {
    ClimaFonte fonte = ClimaFonte.desconhecida,
  }) async {
    horariaFonte = fonte;
  }

  @override
  Future<List<PrevisaoHoraria>> getCachedPrevisaoHoraria({
    required double lat,
    required double lon,
  }) async =>
      [];

  @override
  Future<void> savePrevisaoSemanal(
    List<PrevisaoDiaria> previsoes, {
    ClimaFonte fonte = ClimaFonte.desconhecida,
  }) async {
    semanalFonte = fonte;
  }

  @override
  Future<List<PrevisaoDiaria>> getCachedPrevisaoSemanal({
    required double lat,
    required double lon,
  }) async =>
      [];

  @override
  Future<void> evictExpired() async {}
}
