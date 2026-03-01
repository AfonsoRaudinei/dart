enum CaseTipo {
  resultado,
  antesDepois,
  avaliacao;

  factory CaseTipo.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'resultado':
        return CaseTipo.resultado;
      case 'antes_depois':
        return CaseTipo.antesDepois;
      case 'avaliacao':
        return CaseTipo.avaliacao;
      default:
        throw ArgumentError('CaseTipo desconhecido: $value');
    }
  }

  String toValue() {
    switch (this) {
      case CaseTipo.resultado:
        return 'resultado';
      case CaseTipo.antesDepois:
        return 'antes_depois';
      case CaseTipo.avaliacao:
        return 'avaliacao';
    }
  }
}
