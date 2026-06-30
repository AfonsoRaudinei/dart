/// Representa o estado climático atual de uma localização.
class ClimaAtual {
  final double temperatura;
  final double sensacaoTermica;
  final String condicao;
  final String condicaoCodigo;
  final double ventoVelocidade; // km/h
  final String ventoDirecao; // ex: "NE", "SW"
  final int umidade; // %
  final double precipitacao; // mm acumulado
  final double pressao; // hPa
  final double visibilidade; // km
  final int coberturaNuvens; // %
  final int indiceUV;
  final DateTime nascerSol;
  final DateTime porSol;
  final double latitude;
  final double longitude;
  final String cidade;
  final DateTime atualizadoEm;

  const ClimaAtual({
    required this.temperatura,
    required this.sensacaoTermica,
    required this.condicao,
    required this.condicaoCodigo,
    required this.ventoVelocidade,
    required this.ventoDirecao,
    required this.umidade,
    required this.precipitacao,
    required this.pressao,
    required this.visibilidade,
    required this.coberturaNuvens,
    required this.indiceUV,
    required this.nascerSol,
    required this.porSol,
    required this.latitude,
    required this.longitude,
    required this.cidade,
    required this.atualizadoEm,
  });
}
