import '../domain/occurrence.dart';
import 'widgets/occurrence_creation_sheet.dart';

String? _trimOrNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}

/// Aplica [OccurrenceFormData] sobre uma ocorrência existente (edição).
Occurrence occurrenceWithFormData(
  Occurrence occurrence,
  OccurrenceFormData data,
) {
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
    clearCultivar: data.cultivar == null,
    dataPlantio: data.dataPlantio,
    clearDataPlantio: data.dataPlantio == null,
    estadioFenologico: data.estadioFenologico,
    tipoOcorrencia: data.tipoOcorrencia,
    amostraSolo: data.amostraSolo,
    metricasJson: data.metricasJson,
    nutrientesJson: data.nutrientesJson,
    categoriasJson: data.categoriasJson,
    notasCategoriasJson: data.notasCategoriasJson,
    fotosCategoriasJson: data.fotosCategoriasJson,
    dataEmergencia: data.dataEmergencia,
    clearDataEmergencia: data.dataEmergencia == null,
    sementesPorMetro: data.sementesPorMetro,
    clearSementesPorMetro: data.sementesPorMetro == null,
    estandePlantas: data.estandePlantas,
    clearEstandePlantas: data.estandePlantas == null,
    avaliacaoPlantio: data.avaliacaoPlantio,
    clearAvaliacaoPlantio: data.avaliacaoPlantio == null,
    objetivoPlantio: data.objetivoPlantio,
    clearObjetivoPlantio: data.objetivoPlantio == null,
    dataFimPlantio: data.dataFimPlantio,
    clearDataFimPlantio: data.dataFimPlantio == null,
    cicloDias: data.cicloDias,
    clearCicloDias: data.cicloDias == null,
    cultura: _trimOrNull(data.cultura),
    clearCultura: _trimOrNull(data.cultura) == null,
    safra: _trimOrNull(data.safra),
    clearSafra: _trimOrNull(data.safra) == null,
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
  ).applyRecomendacaoOrdem(
    acao: data.recomendacaoAcao,
    dose: data.recomendacaoDose,
    quando: data.recomendacaoQuando,
  );
}
