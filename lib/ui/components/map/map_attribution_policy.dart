/// Duração do popup automático de atribuição do mapa privado.
///
/// Deve permanecer [Duration.zero]: qualquer duração > 0 abre um retângulo
/// preto semi-transparente na entrada do mapa (parece "sombra"/bug).
/// A atribuição continua acessível pelo botão info do [RichAttributionWidget].
const Duration kMapAttributionPopupInitialDuration = Duration.zero;
