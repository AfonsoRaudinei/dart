import 'package:soloforte_app/core/contracts/i_drawing_field_writer.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

/// Dados do talhão ativo sob o ponto, usados só na criação da ocorrência.
class OccurrenceTalhaoPrefill {
  final String fieldId;
  final String talhaoNome;
  final String clientId;
  final String? fazendaId;
  final String? cultura;
  final String? cultivar;
  final String? dataPlantio;
  final String? dataEmergencia;
  final int? cicloDias;

  const OccurrenceTalhaoPrefill({
    required this.fieldId,
    required this.talhaoNome,
    required this.clientId,
    this.fazendaId,
    this.cultura,
    this.cultivar,
    this.dataPlantio,
    this.dataEmergencia,
    this.cicloDias,
  });
}

/// Só quando o desenho está ativo e tem cliente. Fazenda é opcional.
OccurrenceTalhaoPrefill? occurrenceTalhaoPrefillIfEligible({
  required bool ativo,
  required String fieldId,
  required String nome,
  required String? clienteId,
  required String? fazendaId,
  String? cultura,
  String? material,
  String? dataPlantio,
  String? dataEmergencia,
  int? cicloDias,
}) {
  if (!ativo) return null;
  final client = clienteId?.trim() ?? '';
  if (client.isEmpty) return null;
  return OccurrenceTalhaoPrefill(
    fieldId: fieldId,
    talhaoNome: nome,
    clientId: client,
    fazendaId: _blankToNull(fazendaId),
    cultura: _blankToNull(cultura),
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
  final String? cultura;
  final String? cultivar;
  final String? dataPlantio;
  final String? dataEmergencia;
  final String? cicloDias;
  final bool applyClient;

  const TalhaoPrefillPatch({
    this.cultura,
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
  String currentCultura = '',
}) {
  if (isEditing || prefill == null) return TalhaoPrefillPatch.none;
  return TalhaoPrefillPatch(
    cultura: _fillIfEmpty(currentCultura, prefill.cultura),
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

/// Plantio salvo vira o plantio atual do talhão (replantio/correção).
///
/// Só a categoria Plantio grava. Campo vazio vai null (o contrato mantém o
/// atual); término do plantio não vai para o talhão. Falha não desfaz a
/// ocorrência.
Future<void> writeBackTalhaoPlantio({
  required IDrawingFieldWriter writer,
  required String fieldId,
  required String? category,
  String? cultura,
  String? cultivar,
  String? safra,
  String? dataPlantio,
  String? dataEmergencia,
  int? cicloDias,
}) async {
  if (category?.trim().toLowerCase() != 'plantio') return;
  final id = fieldId.trim();
  if (id.isEmpty) return;
  final values = (
    cultura: _blankToNull(cultura),
    material: _blankToNull(cultivar),
    safra: _blankToNull(safra),
    dataPlantio: _blankToNull(dataPlantio),
    dataEmergencia: _blankToNull(dataEmergencia),
    cicloDias: cicloDias?.toString(),
  );
  if (values.cultura == null &&
      values.material == null &&
      values.safra == null &&
      values.dataPlantio == null &&
      values.dataEmergencia == null &&
      values.cicloDias == null) {
    return;
  }

  try {
    await writer.updateFieldMetadata(
      fieldId: id,
      cultura: values.cultura,
      material: values.material,
      safra: values.safra,
      dataPlantio: values.dataPlantio,
      dataEmergencia: values.dataEmergencia,
      cicloDias: values.cicloDias,
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

