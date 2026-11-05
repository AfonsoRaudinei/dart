import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

import '../../domain/occurrence_soy_age.dart';

/// Dados do talhão ativo sob o ponto, usados só na criação da ocorrência.
class OccurrenceTalhaoPrefill {
  final String fieldId;
  final String talhaoNome;
  final String clientId;
  final String? cultivar;
  final String? dataPlantio;
  final String? dataEmergencia;
  final int? cicloDias;

  const OccurrenceTalhaoPrefill({
    required this.fieldId,
    required this.talhaoNome,
    required this.clientId,
    this.cultivar,
    this.dataPlantio,
    this.dataEmergencia,
    this.cicloDias,
  });
}

/// Só quando o desenho está ativo e tem cliente e fazenda.
OccurrenceTalhaoPrefill? occurrenceTalhaoPrefillIfEligible({
  required bool ativo,
  required String fieldId,
  required String nome,
  required String? clienteId,
  required String? fazendaId,
  String? material,
  String? dataPlantio,
  String? dataEmergencia,
  int? cicloDias,
}) {
  if (!ativo) return null;
  final client = clienteId?.trim() ?? '';
  final farm = fazendaId?.trim() ?? '';
  if (client.isEmpty || farm.isEmpty) return null;
  return OccurrenceTalhaoPrefill(
    fieldId: fieldId,
    talhaoNome: nome,
    clientId: client,
    cultivar: _blankToNull(material),
    dataPlantio: _blankToNull(dataPlantio),
    dataEmergencia: _blankToNull(dataEmergencia),
    cicloDias: cicloDias,
  );
}

/// O que o formulário de criação deve preencher.
///
/// Null num campo = não alterar o que o rascunho ou a edição já têm.
class TalhaoPrefillPatch {
  final String? cultivar;
  final String? dataPlantio;
  final String? dataEmergencia;
  final String? cicloDias;
  final bool applyClient;

  const TalhaoPrefillPatch({
    this.cultivar,
    this.dataPlantio,
    this.dataEmergencia,
    this.cicloDias,
    this.applyClient = false,
  });

  static const none = TalhaoPrefillPatch();
}

/// Rascunho vence. Edição (`isEditing`) não aplica. Campo vazio recebe o talhão.
TalhaoPrefillPatch applyTalhaoPrefill({
  required OccurrenceTalhaoPrefill? prefill,
  required bool isEditing,
  required String currentCultivar,
  required String? currentDataPlantio,
  required String? currentDataEmergencia,
  required String currentCicloDias,
  required bool draftHasClient,
}) {
  if (isEditing || prefill == null) return TalhaoPrefillPatch.none;
  return TalhaoPrefillPatch(
    cultivar: _fillIfEmpty(currentCultivar, prefill.cultivar),
    dataPlantio: _fillIfEmpty(currentDataPlantio ?? '', prefill.dataPlantio),
    dataEmergencia: _fillIfEmpty(
      currentDataEmergencia ?? '',
      prefill.dataEmergencia,
    ),
    cicloDias: _fillIfEmpty(currentCicloDias, prefill.cicloDias?.toString()),
    applyClient: !draftHasClient && prefill.clientId.trim().isNotEmpty,
  );
}

/// Grava no talhão só o que estava vazio e agora tem valor no formulário.
///
/// Cultura, material, safra e campos que o talhão já tinha vão null
/// (o contrato mantém o atual). Falha não desfaz a ocorrência.
Future<void> writeBackTalhaoPlantioIfEmpty({
  required IDrawingFieldWriter writer,
  required OccurrenceTalhaoPrefill prefill,
  required String? formDataPlantio,
  required String? formDataEmergencia,
  required String formCicloDias,
}) async {
  final dataPlantio = _valueToWrite(prefill.dataPlantio, formDataPlantio);
  final dataEmergencia = _valueToWrite(
    prefill.dataEmergencia,
    formDataEmergencia,
  );
  final ciclo = prefill.cicloDias != null
      ? null
      : parseOccurrenceCicloDias(formCicloDias)?.toString();
  if (dataPlantio == null && dataEmergencia == null && ciclo == null) return;

  try {
    await writer.updateFieldMetadata(
      fieldId: prefill.fieldId,
      dataPlantio: dataPlantio,
      dataEmergencia: dataEmergencia,
      cicloDias: ciclo,
    );
  } catch (error, stackTrace) {
    AppLogger.error(
      'write-back do plantio do talhão falhou',
      tag: 'Occurrence',
      error: error,
      stackTrace: stackTrace,
    );
  }
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim();
  if (trimmed == null || trimmed.isEmpty) return null;
  return trimmed;
}

String? _fillIfEmpty(String current, String? incoming) {
  if (current.trim().isNotEmpty) return null;
  return _blankToNull(incoming);
}

String? _valueToWrite(String? stored, String? formValue) {
  if (stored != null && stored.trim().isNotEmpty) return null;
  return _blankToNull(formValue);
}
