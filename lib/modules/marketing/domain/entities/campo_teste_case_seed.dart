/// Dados do polígono `tipo = teste` que a ficha de Resultado ou Avaliação
/// recebe ao reabrir. O host do mapa monta este objeto; marketing não lê
/// `drawings`.
class CampoTesteCaseSeed {
  const CampoTesteCaseSeed({
    required this.drawingId,
    required this.nome,
    required this.areaHa,
    this.clienteId,
    this.fazendaNome,
    this.photoPath,
  });

  final String drawingId;
  final String nome;
  final double areaHa;
  final String? clienteId;
  final String? fazendaNome;
  final String? photoPath;

  /// Texto aceito por `double.tryParse` (ponto decimal, sem zeros à direita).
  String get areaHaText {
    var text = areaHa.toStringAsFixed(2);
    text = text.replaceFirst(RegExp(r'0+$'), '');
    text = text.replaceFirst(RegExp(r'\.$'), '');
    return text;
  }

  String get resumo {
    final nomeTexto = nome.trim().isEmpty ? 'Teste' : nome.trim();
    return '$nomeTexto · $areaHaText ha';
  }
}
