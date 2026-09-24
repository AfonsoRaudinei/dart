import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';

/// Dica operacional derivada da previsão semanal.
class ClimaDicaAgronomica {
  final String emoji;
  final String texto;

  const ClimaDicaAgronomica(this.emoji, this.texto);

  String get linhaCampo => 'Campo: $texto';
}

/// Gera dicas a partir das mesmas regras do card na tela de clima.
List<ClimaDicaAgronomica> gerarDicasAgronomicas(List<PrevisaoDiaria> previsoes) {
  if (previsoes.isEmpty) return [];

  final dicas = <ClimaDicaAgronomica>[];
  final proximos2 = previsoes.take(2).toList();
  final proximos7 = previsoes.take(7).toList();

  final chuvaIntensa = proximos2.any((d) => d.precipitacao > 5);
  if (chuvaIntensa) {
    dicas.add(const ClimaDicaAgronomica(
      '🌧️',
      'Chuva prevista nos próximos 2 dias — evite aplicações fitossanitárias e adubações de cobertura.',
    ));
  }

  final seco = proximos7.every((d) => d.precipitacao < 1);
  if (seco) {
    dicas.add(const ClimaDicaAgronomica(
      '🏜️',
      'Período seco prolongado — monitore a umidade do solo e avalie irrigação suplementar.',
    ));
  }

  final ventoForte = proximos2.any((d) => d.ventoMedio > 20);
  if (ventoForte) {
    dicas.add(const ClimaDicaAgronomica(
      '💨',
      'Ventos fortes previstos — evite pulverizações e operações com pó nos próximos 2 dias.',
    ));
  }

  final temAlerta = proximos7.any((d) => d.temAlerta);
  if (temAlerta) {
    dicas.add(const ClimaDicaAgronomica(
      '⚠️',
      'Alerta meteorológico previsto para os próximos dias — fique atento antes de iniciar operações de campo.',
    ));
  }

  if (!chuvaIntensa && !seco && !ventoForte && !temAlerta) {
    dicas.add(const ClimaDicaAgronomica(
      '✅',
      'Condições favoráveis nos próximos dias — bom período para colheita e operações de campo.',
    ));
  }

  return dicas;
}

String? primeiraLinhaCampoCompartilhamento(List<PrevisaoDiaria> previsoes) {
  final dicas = gerarDicasAgronomicas(previsoes);
  if (dicas.isEmpty) return null;
  return dicas.first.linhaCampo;
}
