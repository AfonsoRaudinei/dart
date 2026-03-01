enum AvaliacaoLayout {
  duasFotos,
  umaFoto;

  factory AvaliacaoLayout.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'duas_fotos':
        return AvaliacaoLayout.duasFotos;
      case 'uma_foto':
        return AvaliacaoLayout.umaFoto;
      default:
        throw ArgumentError('AvaliacaoLayout desconhecido: $value');
    }
  }

  String toValue() {
    switch (this) {
      case AvaliacaoLayout.duasFotos:
        return 'duas_fotos';
      case AvaliacaoLayout.umaFoto:
        return 'uma_foto';
    }
  }
}
