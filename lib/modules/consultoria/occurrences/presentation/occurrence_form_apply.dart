import '../domain/occurrence.dart';
import 'widgets/occurrence_creation_sheet.dart';

/// Aplica [OccurrenceFormData] sobre uma ocorrência existente (edição).
Occurrence occurrenceWithFormData(Occurrence occurrence, OccurrenceFormData data) {
  final clearAudio =
      data.audioPath == null && occurrence.audioPath?.trim().isNotEmpty == true;
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
  );
}
