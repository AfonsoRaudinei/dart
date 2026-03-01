enum ProdutividadeUnidade {
  scHa,
  tonHa,
  kgHa;

  factory ProdutividadeUnidade.fromString(String value) {
    switch (value.toLowerCase()) {
      case 'sc/ha':
      case 'scha':
        return ProdutividadeUnidade.scHa;
      case 'ton/ha':
      case 'tonha':
        return ProdutividadeUnidade.tonHa;
      case 'kg/ha':
      case 'kgha':
        return ProdutividadeUnidade.kgHa;
      default:
        throw ArgumentError('ProdutividadeUnidade desconhecida: $value');
    }
  }

  String toValue() {
    switch (this) {
      case ProdutividadeUnidade.scHa:
        return 'sc/ha';
      case ProdutividadeUnidade.tonHa:
        return 'ton/ha';
      case ProdutividadeUnidade.kgHa:
        return 'kg/ha';
    }
  }
}
