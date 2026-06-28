class ProducerInviteData {
  const ProducerInviteData({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;
}

/// Contrato neutro para criação de convites de vínculo com produtores.
abstract interface class IProducerInviteWriter {
  Future<ProducerInviteData> createInvite(String clientId);
}
