/// Representa o estado do GPS do dispositivo
enum LocationState {
  /// GPS disponível e pronto para uso
  available,

  /// Permissão de localização negada pelo usuário
  permissionDenied,

  /// Serviço de GPS está desabilitado no dispositivo
  serviceDisabled,

  /// Verificação em andamento
  checking,
}
