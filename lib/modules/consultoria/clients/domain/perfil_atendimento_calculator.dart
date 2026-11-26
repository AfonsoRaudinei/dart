import 'enums/perfil_atendimento_tipo.dart';

class PerfilAtendimentoPontos {
  const PerfilAtendimentoPontos({
    required this.pragmatico,
    required this.analitico,
    required this.afavel,
    required this.expressivo,
  });

  final int pragmatico;
  final int analitico;
  final int afavel;
  final int expressivo;

  int sum() => pragmatico + analitico + afavel + expressivo;

  int countFor(PerfilAtendimentoTipo tipo) {
    switch (tipo) {
      case PerfilAtendimentoTipo.pragmatico:
        return pragmatico;
      case PerfilAtendimentoTipo.analitico:
        return analitico;
      case PerfilAtendimentoTipo.afavel:
        return afavel;
      case PerfilAtendimentoTipo.expressivo:
        return expressivo;
    }
  }
}

class PerfilAtendimentoResultado {
  const PerfilAtendimentoResultado({
    required this.dominante,
    this.secundario,
    required this.pontos,
  });

  final PerfilAtendimentoTipo dominante;
  final PerfilAtendimentoTipo? secundario;
  final PerfilAtendimentoPontos pontos;
}

class PerfilAtendimentoValidationException implements Exception {
  PerfilAtendimentoValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

PerfilAtendimentoResultado calcularPerfilAtendimento(
  List<PerfilAtendimentoTipo> respostas,
) {
  if (respostas.length != 7) {
    throw PerfilAtendimentoValidationException(
      'O diagnóstico exige 7 respostas (recebidas: ${respostas.length}).',
    );
  }

  final counts = _countsFrom(respostas);
  final pontos = PerfilAtendimentoPontos(
    pragmatico: counts[PerfilAtendimentoTipo.pragmatico]!,
    analitico: counts[PerfilAtendimentoTipo.analitico]!,
    afavel: counts[PerfilAtendimentoTipo.afavel]!,
    expressivo: counts[PerfilAtendimentoTipo.expressivo]!,
  );
  if (pontos.sum() != 7) {
    throw PerfilAtendimentoValidationException(
      'Soma dos pontos deve ser 7 (atual: ${pontos.sum()}).',
    );
  }

  final maxScore = _maxScore(counts);
  final ordemNoTopo = _ordemPrimeiraAparicao(respostas, score: maxScore);
  final dominante = ordemNoTopo.first;

  if (pontos.countFor(dominante) == 7) {
    return PerfilAtendimentoResultado(
      dominante: dominante,
      secundario: null,
      pontos: pontos,
    );
  }

  final PerfilAtendimentoTipo secundario;
  if (ordemNoTopo.length >= 2) {
    secundario = ordemNoTopo[1];
  } else {
    final scores = _pontuacoesOrdenadas(counts);
    secundario = _primeiroPorOrdemResposta(respostas, score: scores[1]);
  }

  return PerfilAtendimentoResultado(
    dominante: dominante,
    secundario: secundario,
    pontos: pontos,
  );
}

Map<PerfilAtendimentoTipo, int> _countsFrom(List<PerfilAtendimentoTipo> respostas) {
  final counts = <PerfilAtendimentoTipo, int>{
    for (final t in PerfilAtendimentoTipo.values) t: 0,
  };
  for (final r in respostas) {
    counts[r] = (counts[r] ?? 0) + 1;
  }
  return counts;
}

int _maxScore(Map<PerfilAtendimentoTipo, int> counts) {
  return counts.values.fold(0, (a, b) => a > b ? a : b);
}

List<int> _pontuacoesOrdenadas(Map<PerfilAtendimentoTipo, int> counts) {
  return counts.values.toSet().toList()..sort((a, b) => b.compareTo(a));
}

/// Perfis com [score], na ordem em que aparecem nas respostas (primeira ocorrência).
List<PerfilAtendimentoTipo> _ordemPrimeiraAparicao(
  List<PerfilAtendimentoTipo> respostas, {
  required int score,
}) {
  final counts = _countsFrom(respostas);
  final vistos = <PerfilAtendimentoTipo>{};
  final ordem = <PerfilAtendimentoTipo>[];
  for (final r in respostas) {
    if (counts[r] != score) continue;
    if (vistos.add(r)) ordem.add(r);
  }
  if (ordem.isEmpty) {
    throw PerfilAtendimentoValidationException(
      'Não foi possível resolver perfis com pontuação $score.',
    );
  }
  return ordem;
}

PerfilAtendimentoTipo _primeiroPorOrdemResposta(
  List<PerfilAtendimentoTipo> respostas, {
  required int score,
}) {
  return _ordemPrimeiraAparicao(respostas, score: score).first;
}