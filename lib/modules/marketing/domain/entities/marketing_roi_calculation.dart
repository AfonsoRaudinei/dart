class MarketingRoiInput {
  final double prodSemProduto;
  final double prodComProduto;
  final String unidadeProdutividade;
  final double custoProdutoPorHa;
  final double valorGrao;
  final double? tamanhoHa;
  final double? areaTotal;

  const MarketingRoiInput({
    required this.prodSemProduto,
    required this.prodComProduto,
    required this.unidadeProdutividade,
    required this.custoProdutoPorHa,
    required this.valorGrao,
    this.tamanhoHa,
    this.areaTotal,
  });

  bool get isComplete =>
      prodSemProduto > 0 &&
      prodComProduto > 0 &&
      custoProdutoPorHa > 0 &&
      valorGrao > 0;
}

class MarketingRoiCalculation {
  final MarketingRoiInput input;

  const MarketingRoiCalculation(this.input);

  double get ganhoScHa => input.prodComProduto - input.prodSemProduto;

  double get receitaGanho => ganhoScHa * input.valorGrao;

  double get roiLiquidoRsHa => receitaGanho - input.custoProdutoPorHa;

  double get roiEmSacasHa =>
      input.valorGrao > 0 ? roiLiquidoRsHa / input.valorGrao : 0;

  double? get roiSacasTalhao => _positive(input.tamanhoHa) == null
      ? null
      : roiEmSacasHa * _positive(input.tamanhoHa)!;

  double? get roiReaisTalhao => _positive(input.tamanhoHa) == null
      ? null
      : roiLiquidoRsHa * _positive(input.tamanhoHa)!;

  double? get roiSacasTotal => _positive(input.areaTotal) == null
      ? null
      : roiEmSacasHa * _positive(input.areaTotal)!;

  double? get roiReaisTotal => _positive(input.areaTotal) == null
      ? null
      : roiLiquidoRsHa * _positive(input.areaTotal)!;

  static double? _positive(double? value) {
    if (value == null || value <= 0) return null;
    return value;
  }
}
