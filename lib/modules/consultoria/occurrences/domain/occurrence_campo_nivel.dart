import 'dart:convert';

import 'occurrence.dart';

/// Limite operacional (slider 0–3): acima de [kCampoNivelLimiteSlider] exibe aviso.
const kCampoNivelLimiteSlider = 2;

const _keysIncidenciaSeveridade = {'incidencia', 'severidade'};

/// Nível resumido para lista (Farmbox): Baixo · Médio · Alto.
enum OccurrenceCampoNivel {
  baixo('Baixo'),
  medio('Medio'),
  alto('Alto');

  final String label;
  const OccurrenceCampoNivel(this.label);

  /// Rótulo com acento para UI.
  String get displayLabel => switch (this) {
        OccurrenceCampoNivel.baixo => 'Baixo',
        OccurrenceCampoNivel.medio => 'Médio',
        OccurrenceCampoNivel.alto => 'Alto',
      };
}

/// Maior valor de incidência/severidade (1–3) em [metricasJson], ou null se ausente/zero.
int? maxIncidenciaSeveridadeSlider(Occurrence occurrence) {
  return maxIncidenciaSeveridadeSliderFromJson(occurrence.metricasJson);
}

int? maxIncidenciaSeveridadeSliderFromJson(String? metricasJson) {
  if (metricasJson == null || metricasJson.trim().isEmpty) return null;
  try {
    final decoded = jsonDecode(metricasJson);
    if (decoded is! Map) return null;
    var max = 0;
    for (final catValue in decoded.values) {
      if (catValue is! Map) continue;
      for (final entry in catValue.entries) {
        if (!_keysIncidenciaSeveridade.contains(entry.key.toString())) {
          continue;
        }
        final v = entry.value;
        if (v is! num) continue;
        final clamped = v.round().clamp(0, 3);
        if (clamped > max) max = clamped;
      }
    }
    return max > 0 ? max : null;
  } catch (_) {
    return null;
  }
}

OccurrenceCampoNivel? campoNivelFromSlider(int sliderIndex) {
  return switch (sliderIndex.clamp(1, 3)) {
    1 => OccurrenceCampoNivel.baixo,
    2 => OccurrenceCampoNivel.medio,
    3 => OccurrenceCampoNivel.alto,
    _ => null,
  };
}

OccurrenceCampoNivel? resolveCampoNivelLista(Occurrence occurrence) {
  final max = maxIncidenciaSeveridadeSlider(occurrence);
  if (max == null) return null;
  return campoNivelFromSlider(max);
}

bool campoNivelAcimaDoLimite(int sliderIndex) =>
    sliderIndex > kCampoNivelLimiteSlider;

bool occurrenceCampoNivelAcimaDoLimite(Occurrence occurrence) {
  final max = maxIncidenciaSeveridadeSlider(occurrence);
  if (max == null) return false;
  return campoNivelAcimaDoLimite(max);
}
