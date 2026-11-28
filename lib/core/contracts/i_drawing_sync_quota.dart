/// Contrato neutro: teto de talhões do Desenho na nuvem (ADR-066).
///
/// Isenções e ocupação ficam em `drawing/` — não neste contrato.
abstract interface class IDrawingSyncQuota {
  /// `null` = ilimitado (Ouro ou admin). Grátis/expirado = 0.
  int? get cloudTalhaoLimit;
}