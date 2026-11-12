class ProducerInviteData {
  const ProducerInviteData({required this.token, required this.expiresAt});

  final String token;
  final DateTime expiresAt;
}

/// O que o consultor libera neste convite. Tudo ligado reproduz o vínculo antigo.
class ProducerShareSelection {
  const ProducerShareSelection({
    this.farms = true,
    this.fields = true,
    this.occurrences = true,
    this.reports = true,
  });

  final bool farms;
  final bool fields;
  final bool occurrences;
  final bool reports;

  bool get hasAny => farms || fields || occurrences || reports;

  static bool readFlag(Object? value, {bool fallback = true}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value.toString().trim().toLowerCase();
    if (text == 'false' || text == '0') return false;
    if (text == 'true' || text == '1') return true;
    return fallback;
  }
}

/// Contrato neutro para criação de convites de vínculo.
abstract interface class IProducerInviteWriter {
  Future<ProducerInviteData> createInvite(
    String clientId, {
    ProducerShareSelection share = const ProducerShareSelection(),
  });
}
