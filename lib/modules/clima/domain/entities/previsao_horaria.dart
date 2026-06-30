/// Representa a previsão climática para uma hora específica.
class PrevisaoHoraria {
  final DateTime hora;
  final double temperatura;
  final double precipitacao; // mm
  final int probabilidadeChuva; // %
  final String condicao;
  final String condicaoCodigo;

  const PrevisaoHoraria({
    required this.hora,
    required this.temperatura,
    required this.precipitacao,
    required this.probabilidadeChuva,
    required this.condicao,
    required this.condicaoCodigo,
  });
}
