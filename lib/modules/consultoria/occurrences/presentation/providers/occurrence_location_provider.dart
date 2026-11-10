import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup_provider.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

import '../../domain/occurrence_point_in_field.dart';

/// Fazenda e talhão onde o ponto da ocorrência está.
class OccurrenceLocationLabel {
  final String fieldId;
  final String? farmName;
  final String fieldName;

  const OccurrenceLocationLabel({
    required this.fieldId,
    required this.fieldName,
    this.farmName,
  });

  String get farmDisplay => _withPrefix('Fazenda', farmName ?? '');

  String get fieldDisplay => _withPrefix('Talhão', fieldName);

  /// `Fazenda X · Talhão Y`, ou só `Talhão Y` sem fazenda.
  String get display {
    final farm = farmName?.trim() ?? '';
    if (farm.isEmpty) return fieldDisplay;
    return '$farmDisplay · $fieldDisplay';
  }

  static String _withPrefix(String prefix, String name) {
    final trimmed = name.trim();
    if (trimmed.toLowerCase().startsWith(prefix.toLowerCase())) return trimmed;
    return '$prefix $trimmed';
  }
}

/// O que se sabe do ponto: talhão já vinculado (ou do prefill) e o pin.
typedef OccurrenceLocationQuery = ({
  String? fieldId,
  String? fazendaId,
  String? talhaoNome,
  double lat,
  double lng,
});

/// Com `fieldId` busca o talhão; sem ele, o primeiro talhão que contém o pin.
/// Falha de lookup → null (a linha some, o formulário segue).
final occurrenceLocationProvider = FutureProvider.autoDispose
    .family<OccurrenceLocationLabel?, OccurrenceLocationQuery>((
      ref,
      query,
    ) async {
      try {
        final fields = ref.read(iFieldLookupProvider);
        final fieldId = query.fieldId?.trim() ?? '';
        FieldSummary? field;
        if (fieldId.isNotEmpty) {
          field = await fields.findById(fieldId);
        } else {
          final all = await fields.listAll();
          field = all
              .where(
                (candidate) => occurrencePointInFieldGeometry(
                  candidate.geometry,
                  lat: query.lat,
                  lng: query.lng,
                ),
              )
              .firstOrNull;
        }

        final resolvedId = field?.id ?? fieldId;
        final fieldName = _firstNonBlank(field?.name, query.talhaoNome);
        if (resolvedId.isEmpty || fieldName == null) return null;

        final farmId = _firstNonBlank(field?.farmId, query.fazendaId);
        final farm = farmId == null
            ? null
            : await ref.read(iFarmLookupProvider).findById(farmId);
        return OccurrenceLocationLabel(
          fieldId: resolvedId,
          fieldName: fieldName,
          farmName: _firstNonBlank(farm?.name, null),
        );
      } catch (error) {
        AppLogger.warning(
          'local da ocorrência não resolvido',
          tag: 'Occurrence',
          error: error,
        );
        return null;
      }
    });

String? _firstNonBlank(String? a, String? b) {
  for (final value in [a, b]) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isNotEmpty) return trimmed;
  }
  return null;
}
