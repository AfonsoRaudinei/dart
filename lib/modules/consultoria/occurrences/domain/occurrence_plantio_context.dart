import '../../../../core/services/sync_status_contract.dart';
import 'occurrence.dart';

/// Safra agrícola de julho/AAAA a junho/AAAA+1 → `'AAAA/AAAA+1'` (ADR-059).
String? safraFromPlantio(DateTime plantio) {
  final start = plantio.month >= 7 ? plantio.year : plantio.year - 1;
  return '$start/${start + 1}';
}

/// [date] cai na janela jul..jun de [safra]. Safra ilegível → false.
bool occurrenceDateInSafra(DateTime date, String safra) {
  final start = _safraStartYear(safra);
  if (start == null) return false;
  final dateStart = date.month >= 7 ? date.year : date.year - 1;
  return dateStart == start;
}

final _safraPattern = RegExp(r'^\s*(\d{4})\s*/\s*(\d{2}|\d{4})\s*$');

/// Aceita `2026/2027` e `2026/27`. Segundo ano precisa ser o seguinte.
int? _safraStartYear(String? safra) {
  final match = _safraPattern.firstMatch(safra ?? '');
  if (match == null) return null;
  final start = int.parse(match.group(1)!);
  final endRaw = match.group(2)!;
  final end = endRaw.length == 2
      ? (start ~/ 100) * 100 + int.parse(endRaw)
      : int.parse(endRaw);
  final normalizedEnd = end < start ? end + 100 : end;
  if (normalizedEnd != start + 1) return null;
  return start;
}

/// Plantio gravado no talhão (`drawings`). Datas em ISO `yyyy-MM-dd`.
class TalhaoPlantioSnapshot {
  final String? cultura;
  final String? material;
  final String? safra;
  final String? dataPlantio;
  final String? dataEmergencia;
  final int? cicloDias;

  const TalhaoPlantioSnapshot({
    this.cultura,
    this.material,
    this.safra,
    this.dataPlantio,
    this.dataEmergencia,
    this.cicloDias,
  });
}

/// Dados do plantio vigente do talhão para a safra de uma ocorrência.
class OccurrencePlantioContext {
  final String fieldId;
  final String? cultura;
  final String? safra;
  final String? cultivar;
  final String? dataPlantio;
  final String? dataFimPlantio;
  final String? dataEmergencia;
  final int? cicloDias;

  /// Ocorrência de Plantio de origem; null quando veio do talhão.
  final String? sourceOccurrenceId;

  const OccurrencePlantioContext({
    required this.fieldId,
    this.cultura,
    this.safra,
    this.cultivar,
    this.dataPlantio,
    this.dataFimPlantio,
    this.dataEmergencia,
    this.cicloDias,
    this.sourceOccurrenceId,
  });

  /// Safra sozinha não conta: ela sempre pode ser derivada da data.
  bool get isEmpty =>
      cultura == null &&
      cultivar == null &&
      dataPlantio == null &&
      dataFimPlantio == null &&
      dataEmergencia == null &&
      cicloDias == null;
}

bool isPlantioOccurrence(Occurrence occurrence) =>
    occurrence.category?.trim().toLowerCase() == 'plantio';

bool _isDeleted(Occurrence occurrence) =>
    occurrence.deletedAt != null ||
    SyncStatusContract.normalize(occurrence.syncStatus) ==
        SyncStatusContract.deletedLocal;

/// Safra salva (se legível), senão a do início do plantio, senão a da criação.
String plantioOccurrenceSafra(Occurrence occurrence) {
  final own = occurrence.safra?.trim() ?? '';
  if (_safraStartYear(own) != null) return own;
  final plantio = DateTime.tryParse(occurrence.dataPlantio?.trim() ?? '');
  return safraFromPlantio(plantio ?? occurrence.createdAt)!;
}

/// Criação mais recente primeiro; edição de um Plantio antigo não o promove.
int _compareRecency(Occurrence a, Occurrence b) {
  final created = b.createdAt.compareTo(a.createdAt);
  if (created != 0) return created;
  return b.updatedAt.compareTo(a.updatedAt);
}

List<Occurrence> _plantioCandidates(
  String fieldId,
  List<Occurrence> plantioOccurrences,
) {
  return plantioOccurrences
      .where(
        (o) =>
            isPlantioOccurrence(o) &&
            o.fieldId?.trim() == fieldId &&
            !_isDeleted(o),
      )
      .toList();
}

/// Plantio mais recente da safra de [referenceDate] (agora, se null) ou,
/// sem Plantio nessa safra, o talhão — só se a safra do talhão bater.
OccurrencePlantioContext? resolvePlantioContext({
  required String fieldId,
  required List<Occurrence> plantioOccurrences,
  required TalhaoPlantioSnapshot? talhao,
  DateTime? referenceDate,
}) {
  final id = fieldId.trim();
  if (id.isEmpty) return null;
  final reference = referenceDate ?? DateTime.now();

  final inSafra =
      _plantioCandidates(id, plantioOccurrences)
          .where(
            (o) => occurrenceDateInSafra(reference, plantioOccurrenceSafra(o)),
          )
          .toList()
        ..sort(_compareRecency);
  if (inSafra.isNotEmpty) {
    final latest = inSafra.first;
    return OccurrencePlantioContext(
      fieldId: id,
      cultura: _blankToNull(latest.cultura),
      safra: plantioOccurrenceSafra(latest),
      cultivar: _blankToNull(latest.cultivar),
      dataPlantio: _blankToNull(latest.dataPlantio),
      dataFimPlantio: _blankToNull(latest.dataFimPlantio),
      dataEmergencia: _blankToNull(latest.dataEmergencia),
      cicloDias: latest.cicloDias,
      sourceOccurrenceId: latest.id,
    );
  }

  if (talhao == null) return null;
  final talhaoSafra = _talhaoSafra(talhao);
  if (talhaoSafra == null || !occurrenceDateInSafra(reference, talhaoSafra)) {
    return null;
  }
  final context = OccurrencePlantioContext(
    fieldId: id,
    cultura: _blankToNull(talhao.cultura),
    safra: talhaoSafra,
    cultivar: _blankToNull(talhao.material),
    dataPlantio: _blankToNull(talhao.dataPlantio),
    dataEmergencia: _blankToNull(talhao.dataEmergencia),
    cicloDias: talhao.cicloDias,
  );
  return context.isEmpty ? null : context;
}

String? _talhaoSafra(TalhaoPlantioSnapshot talhao) {
  final own = talhao.safra?.trim() ?? '';
  if (_safraStartYear(own) != null) return own;
  final plantio = DateTime.tryParse(talhao.dataPlantio?.trim() ?? '');
  return plantio == null ? null : safraFromPlantio(plantio);
}

/// [plantio] (já com os valores do formulário) é o de criação mais recente
/// da sua safra entre os Plantios de [fieldId].
bool isLatestPlantioInSafra({
  required String fieldId,
  required Occurrence plantio,
  required List<Occurrence> plantioOccurrences,
}) {
  final id = fieldId.trim();
  if (id.isEmpty) return false;
  final safra = plantioOccurrenceSafra(plantio);
  final start = _safraStartYear(safra);
  return !_plantioCandidates(id, plantioOccurrences).any(
    (other) =>
        other.id != plantio.id &&
        _safraStartYear(plantioOccurrenceSafra(other)) == start &&
        _compareRecency(other, plantio) < 0,
  );
}

/// Edição: valores próprios da ocorrência primeiro; vazios vêm do contexto.
OccurrencePlantioContext mergeOccurrencePlantioContext(
  Occurrence own,
  OccurrencePlantioContext context,
) {
  return OccurrencePlantioContext(
    fieldId: context.fieldId,
    cultura: _blankToNull(own.cultura) ?? context.cultura,
    safra: _blankToNull(own.safra) ?? context.safra,
    cultivar: _blankToNull(own.cultivar) ?? context.cultivar,
    dataPlantio: _blankToNull(own.dataPlantio) ?? context.dataPlantio,
    dataFimPlantio: _blankToNull(own.dataFimPlantio) ?? context.dataFimPlantio,
    dataEmergencia: _blankToNull(own.dataEmergencia) ?? context.dataEmergencia,
    cicloDias: own.cicloDias ?? context.cicloDias,
    sourceOccurrenceId: context.sourceOccurrenceId,
  );
}

String? _blankToNull(String? value) {
  final trimmed = value?.trim() ?? '';
  return trimmed.isEmpty ? null : trimmed;
}
