import 'package:flutter/material.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';

import '../../domain/occurrence_plantio_context.dart';
import '../../domain/occurrence_soy_age.dart';
import 'occurrence_date_field.dart';

/// Dados do plantio do talhão, somente leitura (ADR-059).
///
/// DAP/DAE contados até [referenceDate] (data da ocorrência; agora se null).
class OccurrencePlantioSummaryCard extends StatelessWidget {
  final OccurrencePlantioContext plantio;
  final DateTime? referenceDate;

  const OccurrencePlantioSummaryCard({
    super.key,
    required this.plantio,
    this.referenceDate,
  });

  List<({String label, String value, String? detail})> _rows() {
    final today = referenceDate ?? DateTime.now();
    final inicio = parseOccurrenceIsoDate(plantio.dataPlantio);
    final termino = parseOccurrenceIsoDate(plantio.dataFimPlantio);
    final emergencia = parseOccurrenceIsoDate(plantio.dataEmergencia);
    final culturaSafra = [
      plantio.cultura,
      plantio.safra,
    ].whereType<String>().join(' · ');
    final culturaSafraLabel = plantio.cultura == null
        ? 'Safra'
        : (plantio.safra == null ? 'Cultura' : 'Cultura · Safra');
    return [
      if (culturaSafra.isNotEmpty)
        (label: culturaSafraLabel, value: culturaSafra, detail: null),
      if (plantio.cultivar case final cultivar?)
        (label: 'Cultivar', value: cultivar, detail: null),
      if (inicio != null)
        (
          label: 'Início do plantio',
          value: OccurrenceDateField.format(inicio),
          detail: occurrenceDapLabel(inicio, today: today),
        ),
      if (termino != null)
        (
          label: 'Término do plantio',
          value: OccurrenceDateField.format(termino),
          detail: null,
        ),
      if (emergencia != null)
        (
          label: 'Emergência',
          value: OccurrenceDateField.format(emergencia),
          detail: occurrenceSoyAgeLabel(emergencia, today: today),
        ),
      if (occurrenceCicloLabel(plantio.cicloDias) case final ciclo?)
        (label: 'Ciclo', value: ciclo, detail: null),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    final rows = _rows();
    return Column(
      key: const Key('occurrence_plantio_summary_card'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dados do plantio',
          style: TextStyle(
            color: v.onSheetPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            letterSpacing: .4,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: v.cardBackground,
            borderRadius: BorderRadius.circular(v.cardRadius),
            border: Border.all(color: v.cardBorder),
          ),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) Divider(height: 1, color: v.rowDivider),
                _SummaryRow(
                  label: rows[i].label,
                  value: rows[i].value,
                  detail: rows[i].detail,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Para corrigir, edite a ocorrência de Plantio.',
          style: TextStyle(color: v.subtitleColor, fontSize: 12),
        ),
      ],
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final String? detail;

  const _SummaryRow({required this.label, required this.value, this.detail});

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: v.subtitleColor, fontSize: 13),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: v.onSheetPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (detail case final text?)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      text,
                      textAlign: TextAlign.end,
                      style: TextStyle(color: v.subtitleColor, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
