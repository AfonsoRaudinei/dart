/// Severidade de um alerta meteorológico — ordena notificações por prioridade.
enum SeveridadeAlerta { baixa, media, alta, extrema }

/// Tipos de alerta previstos para o contexto agronômico.
enum TipoAlerta {
  tempestade,
  geada,
  chuvaIntensa,
  ventoForte,
  temperaturaExtrema,
}

/// Representa um alerta meteorológico emitido para uma localização.
class AlertaMeteorologico {
  final String id;
  final String titulo;
  final String descricao;
  final SeveridadeAlerta severidade;
  final TipoAlerta tipo;
  final DateTime inicio;
  final DateTime fim;

  const AlertaMeteorologico({
    required this.id,
    required this.titulo,
    required this.descricao,
    required this.severidade,
    required this.tipo,
    required this.inicio,
    required this.fim,
  });

  bool get ativo => DateTime.now().isBefore(fim);
}
