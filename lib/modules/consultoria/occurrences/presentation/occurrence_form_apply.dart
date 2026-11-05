import '../domain/occurrence.dart';
import 'widgets/occurrence_creation_sheet.dart';

String? _trimOrNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// Aplica [OccurrenceFormData] sobre uma ocorrência existente (edição).
Occurrence occurrenceWithFormData(Occurrence occurrence, OccurrenceFormData data) {
  final clearAudio =
      data.audioPath == null && occurrence.audioPath?.trim().isNotEmpty == true;
  final amostraCodigo = _trimOrNull(data.amostraCodigo);
  final amostraColetor = _trimOrNull(data.amostraColetor);
  final amostraTramite = _trimOrNull(data.amostraTramite);
  final amostraLaudoTexto = _trimOrNull(data.amostraLaudoTexto);
  return occurrence.copyWith(
    type: data.type,
    description: data.description,
    clientId: data.clientId,
    photoPath: data.photoPath,
    category: data.category,
    cultivar: data.cultivar,
    dataPlantio: data.dataPlantio,
    estadioFenologico: data.estadioFenologico,
    tipoOcorrencia: data.tipoOcorrencia,
    amostraSolo: data.amostraSolo,
    recomendacoes: data.recomendacoes,
    metricasJson: data.metricasJson,
    nutrientesJson: data.nutrientesJson,
    categoriasJson: data.categoriasJson,
    notasCategoriasJson: data.notasCategoriasJson,
    fotosCategoriasJson: data.fotosCategoriasJson,
    dataEmergencia: data.dataEmergencia,
    sementesPorMetro: data.sementesPorMetro,
    estandePlantas: data.estandePlantas,
    avaliacaoPlantio: data.avaliacaoPlantio,
    objetivoPlantio: data.objetivoPlantio,
    audioPath: data.audioPath,
    clearAudioPath: clearAudio,
    audioDurationSec: data.audioDurationSec,
    clearAudioDurationSec: clearAudio,
    amostraCodigo: amostraCodigo,
    clearAmostraCodigo: amostraCodigo == null,
    amostraColetor: amostraColetor,
    clearAmostraColetor: amostraColetor == null,
    amostraTramite: amostraTramite,
    clearAmostraTramite: amostraTramite == null,
    amostraLaudoTexto: amostraLaudoTexto,
    clearAmostraLaudoTexto: amostraLaudoTexto == null,
  );
}
