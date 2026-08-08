/// Rascunho efêmero do formulário de criação de ocorrência no mapa.
///
/// Keyed por pin (lat/lng) — sobrevive a rebuild do sheet e retorno da câmera.
class OccurrenceFormDraft {
  final String? clientId;
  final String cultivar;
  final String? dataPlantioIso;
  final String? estadioCode;
  final String? selectedCategoryValue;
  final List<String> categoryNames;
  final String urgency;
  final String description;
  final String recomendacoes;
  final Map<String, Map<String, int>> metrics;
  final Set<String> nutrientes;
  final Map<String, List<String>> fotos;
  final Map<String, String> notas;

  const OccurrenceFormDraft({
    this.clientId,
    this.cultivar = '',
    this.dataPlantioIso,
    this.estadioCode,
    this.selectedCategoryValue,
    this.categoryNames = const [],
    this.urgency = 'Média',
    this.description = '',
    this.recomendacoes = '',
    this.metrics = const {},
    this.nutrientes = const {},
    this.fotos = const {},
    this.notas = const {},
  });

  static String pinKeyFor(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(6)}_${longitude.toStringAsFixed(6)}';

  bool get isEffectivelyEmpty {
    if (cultivar.trim().isNotEmpty) return false;
    if (dataPlantioIso != null && dataPlantioIso!.isNotEmpty) return false;
    if (estadioCode != null && estadioCode!.isNotEmpty) return false;
    if (selectedCategoryValue != null) return false;
    if (categoryNames.isNotEmpty) return false;
    if (description.trim().isNotEmpty) return false;
    if (recomendacoes.trim().isNotEmpty) return false;
    if (metrics.isNotEmpty) return false;
    if (nutrientes.isNotEmpty) return false;
    if (fotos.isNotEmpty) return false;
    if (notas.values.any((value) => value.trim().isNotEmpty)) return false;
    if (urgency != 'Média') return false;
    return true;
  }

  OccurrenceFormDraft copyWith({
    String? clientId,
    String? cultivar,
    String? dataPlantioIso,
    String? estadioCode,
    String? selectedCategoryValue,
    List<String>? categoryNames,
    String? urgency,
    String? description,
    String? recomendacoes,
    Map<String, Map<String, int>>? metrics,
    Set<String>? nutrientes,
    Map<String, List<String>>? fotos,
    Map<String, String>? notas,
  }) {
    return OccurrenceFormDraft(
      clientId: clientId ?? this.clientId,
      cultivar: cultivar ?? this.cultivar,
      dataPlantioIso: dataPlantioIso ?? this.dataPlantioIso,
      estadioCode: estadioCode ?? this.estadioCode,
      selectedCategoryValue:
          selectedCategoryValue ?? this.selectedCategoryValue,
      categoryNames: categoryNames ?? this.categoryNames,
      urgency: urgency ?? this.urgency,
      description: description ?? this.description,
      recomendacoes: recomendacoes ?? this.recomendacoes,
      metrics: metrics ?? this.metrics,
      nutrientes: nutrientes ?? this.nutrientes,
      fotos: fotos ?? this.fotos,
      notas: notas ?? this.notas,
    );
  }
}
