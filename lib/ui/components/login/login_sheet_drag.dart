/// Decisão de soltar o painel de login depois de um arraste vertical.
class LoginSheetDrag {
  const LoginSheetDrag._();

  /// Distância (px lógicos) a partir da qual soltar fecha o painel.
  static const double dismissDistance = 120;

  /// Velocidade (px/s). Positiva = dedo indo para baixo.
  static const double dismissVelocity = 700;

  /// Teto do deslocamento visual para o painel não sumir num único frame.
  static const double maxOffset = 520;

  static double clampOffset(double offset) => offset.clamp(0.0, maxOffset);

  /// Um gesto rápido para cima cancela o fechamento, mesmo com o painel longe.
  static bool shouldDismiss({
    required double offset,
    required double velocity,
  }) {
    if (velocity <= -dismissVelocity) return false;
    if (velocity >= dismissVelocity) return true;
    return offset >= dismissDistance;
  }
}
