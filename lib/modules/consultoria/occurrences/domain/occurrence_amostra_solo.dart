import 'occurrence.dart';

/// Trâmite GeoData-style (sem mapa de taxa variável).
enum OccurrenceAmostraTramite {
  coletada('coletada', 'Coletada'),
  laboratorio('laboratorio', 'No laboratório'),
  laudoPronto('laudo_pronto', 'Laudo pronto');

  final String storageValue;
  final String label;
  const OccurrenceAmostraTramite(this.storageValue, this.label);

  static OccurrenceAmostraTramite? fromStorage(String? raw) {
    final v = raw?.trim() ?? '';
    if (v.isEmpty) return null;
    for (final item in OccurrenceAmostraTramite.values) {
      if (item.storageValue == v) return item;
    }
    return null;
  }
}

bool occurrenceIsAmostraSolo(Occurrence occurrence) {
  if (occurrence.amostraSolo) return true;
  final cat = (occurrence.category ?? '').toLowerCase();
  return cat == 'amostra_solo' ||
      cat == 'amostra solo' ||
      cat == 'amostra de solo';
}

String formatAmostraTramiteLinha({
  required String? codigo,
  required String? coletor,
  required OccurrenceAmostraTramite? tramite,
  String? laudoTexto,
}) {
  final parts = <String>[];
  final code = codigo?.trim() ?? '';
  if (code.isNotEmpty) parts.add('Amostra $code');
  final collector = coletor?.trim() ?? '';
  if (collector.isNotEmpty) parts.add('Coletor: $collector');
  if (tramite != null) parts.add(tramite.label);
  final laudo = laudoTexto?.trim() ?? '';
  if (tramite == OccurrenceAmostraTramite.laudoPronto && laudo.isNotEmpty) {
    parts.add('Laudo: $laudo');
  }
  return parts.join(' · ');
}
