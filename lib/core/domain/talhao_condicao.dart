/// Condição agronômica pintada no polígono do talhão.
///
/// O valor gravado é o ARGB fixo em `DrawingProperties.cor`. Cor fora desta
/// paleta (paleta livre antiga) é lida como [bom] e não é regravada sozinha.
enum TalhaoCondicao {
  bom(0xFF34C759, 'Bom'),
  atencao(0xFFFFCC00, 'Atenção'),
  alerta(0xFFFF9500, 'Alerta'),
  ruim(0xFFFF3B30, 'Ruim');

  const TalhaoCondicao(this.argb, this.label);

  /// Verde de marca (`PremiumTokens.brandGreen`).
  final int argb;
  final String label;

  static TalhaoCondicao? fromArgb(int? value) {
    if (value == null) return null;
    for (final condicao in values) {
      if (condicao.argb == value) return condicao;
    }
    return null;
  }

  /// Sem condição salva, ou cor livre antiga, aparece como [bom].
  static TalhaoCondicao resolve(int? cor) => fromArgb(cor) ?? bom;
}
