/// Rascunho efêmero do formulário de criação de ocorrência no mapa.
///
/// Keyed por pin (lat/lng) — sobrevive a rebuild do sheet e retorno da câmera.
class OccurrenceFormDraft {
  final String? clientId;
  final String cultivar;
  final String? dataPlantioIso;
  final String? dataEmergenciaIso;
  final String cicloDias;
  final String sementesPorMetro;
  final String estandePlantas;
  final String? avaliacaoPlantio;
  final String objetivoPlantio;
  final String? estadioCode;
  final String? selectedCategoryValue;
  final List<String> categoryNames;
  final String urgency;
  final String description;
  final String recomendacoes;
  final Map<String, Map<String, int>> metrics;
  final Set<String> nutrientes;
  final Map<String, List<String>> fotos;
  final Map<String, String> photoCaptions;
  final Map<String, String> notas;
  final String? audioPath;
  final int? audioDurationSec;
  final String amostraCodigo;
  final String amostraColetor;
  final String amostraLaudo;
  final String? amostraTramiteStorage;

  const OccurrenceFormDraft({
    this.clientId,
    this.cultivar = '',
    this.dataPlantioIso,
    this.dataEmergenciaIso,
    this.cicloDias = '',
    this.sementesPorMetro = '',
    this.estandePlantas = '',
    this.avaliacaoPlantio,
    this.objetivoPlantio = '',
    this.estadioCode,
    this.selectedCategoryValue,
    this.categoryNames = const [],
    this.urgency = 'Média',
    this.description = '',
    this.recomendacoes = '',
    this.metrics = const {},
    this.nutrientes = const {},
    this.fotos = const {},
    this.photoCaptions = const {},
    this.notas = const {},
    this.audioPath,
    this.audioDurationSec,
    this.amostraCodigo = '',
    this.amostraColetor = '',
    this.amostraLaudo = '',
    this.amostraTramiteStorage,
  });

  static String pinKeyFor(double latitude, double longitude) =>
      '${latitude.toStringAsFixed(6)}_${longitude.toStringAsFixed(6)}';

  bool get isEffectivelyEmpty {
    if (cultivar.trim().isNotEmpty) return false;
    if (dataPlantioIso != null && dataPlantioIso!.isNotEmpty) return false;
    if (dataEmergenciaIso != null && dataEmergenciaIso!.isNotEmpty) {
      return false;
    }
    if (cicloDias.trim().isNotEmpty) return false;
    if (sementesPorMetro.trim().isNotEmpty) return false;
    if (estandePlantas.trim().isNotEmpty) return false;
    if (avaliacaoPlantio != null && avaliacaoPlantio!.isNotEmpty) return false;
    if (objetivoPlantio.trim().isNotEmpty) return false;
    if (estadioCode != null && estadioCode!.isNotEmpty) return false;
    if (selectedCategoryValue != null) return false;
    if (categoryNames.isNotEmpty) return false;
    if (description.trim().isNotEmpty) return false;
    if (recomendacoes.trim().isNotEmpty) return false;
    if (metrics.isNotEmpty) return false;
    if (nutrientes.isNotEmpty) return false;
    if (fotos.isNotEmpty) return false;
    if (audioPath != null && audioPath!.trim().isNotEmpty) return false;
    if (notas.values.any((value) => value.trim().isNotEmpty)) return false;
    if (amostraCodigo.trim().isNotEmpty) return false;
    if (amostraColetor.trim().isNotEmpty) return false;
    if (amostraLaudo.trim().isNotEmpty) return false;
    if (amostraTramiteStorage != null && amostraTramiteStorage!.isNotEmpty) {
      return false;
    }
    if (urgency != 'Média') return false;
    return true;
  }

  OccurrenceFormDraft copyWith({
    String? clientId,
    String? cultivar,
    String? dataPlantioIso,
    String? dataEmergenciaIso,
    String? cicloDias,
    String? sementesPorMetro,
    String? estandePlantas,
    String? avaliacaoPlantio,
    String? objetivoPlantio,
    String? estadioCode,
    String? selectedCategoryValue,
    List<String>? categoryNames,
    String? urgency,
    String? description,
    String? recomendacoes,
    Map<String, Map<String, int>>? metrics,
    Set<String>? nutrientes,
    Map<String, List<String>>? fotos,
    Map<String, String>? photoCaptions,
    Map<String, String>? notas,
    String? audioPath,
    bool clearAudioPath = false,
    int? audioDurationSec,
    bool clearAudioDurationSec = false,
    String? amostraCodigo,
    String? amostraColetor,
    String? amostraLaudo,
    String? amostraTramiteStorage,
  }) {
    return OccurrenceFormDraft(
      clientId: clientId ?? this.clientId,
      cultivar: cultivar ?? this.cultivar,
      dataPlantioIso: dataPlantioIso ?? this.dataPlantioIso,
      dataEmergenciaIso: dataEmergenciaIso ?? this.dataEmergenciaIso,
      cicloDias: cicloDias ?? this.cicloDias,
      sementesPorMetro: sementesPorMetro ?? this.sementesPorMetro,
      estandePlantas: estandePlantas ?? this.estandePlantas,
      avaliacaoPlantio: avaliacaoPlantio ?? this.avaliacaoPlantio,
      objetivoPlantio: objetivoPlantio ?? this.objetivoPlantio,
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
      photoCaptions: photoCaptions ?? this.photoCaptions,
      notas: notas ?? this.notas,
      audioPath: clearAudioPath ? null : (audioPath ?? this.audioPath),
      audioDurationSec: clearAudioDurationSec
          ? null
          : (audioDurationSec ?? this.audioDurationSec),
      amostraCodigo: amostraCodigo ?? this.amostraCodigo,
      amostraColetor: amostraColetor ?? this.amostraColetor,
      amostraLaudo: amostraLaudo ?? this.amostraLaudo,
      amostraTramiteStorage:
          amostraTramiteStorage ?? this.amostraTramiteStorage,
    );
  }
}
