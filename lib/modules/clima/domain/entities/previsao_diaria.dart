/// Representa a previsão climática resumida de um dia inteiro.
class PrevisaoDiaria {
  final DateTime data;
  final double tempMin;
  final double tempMax;
  final double precipitacao; // mm acumulado no dia
  final double ventoMedio; // km/h
  final String condicao;
  final String condicaoCodigo;
  final bool temAlerta;

  const PrevisaoDiaria({
    required this.data,
    required this.tempMin,
    required this.tempMax,
    required this.precipitacao,
    required this.ventoMedio,
    required this.condicao,
    required this.condicaoCodigo,
    required this.temAlerta,
  });
}
