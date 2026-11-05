import 'dart:ui';

/// Andamento operacional da ocorrência (acompanhamento produtor/consultor).
///
/// Distinto de [OccurrenceStatus] (`draft` / `confirmed`) — registro no campo.
enum OccurrenceAndamento {
  aberta('aberta', 'Aberta'),
  emAtendimento('em_atendimento', 'Em atendimento'),
  resolvida('resolvida', 'Resolvida');

  final String storageValue;
  final String label;

  const OccurrenceAndamento(this.storageValue, this.label);

  static OccurrenceAndamento fromStorage(String? value) {
    final normalized = value?.trim().toLowerCase() ?? '';
    for (final item in OccurrenceAndamento.values) {
      if (item.storageValue == normalized) return item;
    }
    return OccurrenceAndamento.aberta;
  }

  static String? normalizeStorage(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return fromStorage(value).storageValue;
  }
}

Color occurrenceAndamentoChipColor(OccurrenceAndamento value) {
  switch (value) {
    case OccurrenceAndamento.aberta:
      return const Color(0xFFFF9500);
    case OccurrenceAndamento.emAtendimento:
      return const Color(0xFF007AFF);
    case OccurrenceAndamento.resolvida:
      return const Color(0xFF34C759);
  }
}
