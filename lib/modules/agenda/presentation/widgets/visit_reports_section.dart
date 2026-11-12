import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_occurrence_read_provider.dart';

import '../../domain/visit_report_line.dart';

class VisitReportQuery {
  const VisitReportQuery({
    required this.sessionId,
    this.eventFieldName,
    this.eventFarmName,
  });

  final String sessionId;
  final String? eventFieldName;
  final String? eventFarmName;

  @override
  bool operator ==(Object other) {
    return other is VisitReportQuery &&
        other.sessionId == sessionId &&
        other.eventFieldName == eventFieldName &&
        other.eventFarmName == eventFarmName;
  }

  @override
  int get hashCode => Object.hash(sessionId, eventFieldName, eventFarmName);
}

final visitReportLinesProvider =
    FutureProvider.family<List<VisitReportLine>, VisitReportQuery>((
      ref,
      query,
    ) async {
      final occurrences = await ref
          .read(occurrenceReadProvider)
          .getBySessionId(query.sessionId);
      final lines = <VisitReportLine>[];
      for (final occurrence in occurrences) {
        String? fieldName;
        String? farmName;
        final fieldId = occurrence.fieldId?.trim() ?? '';
        if (fieldId.isNotEmpty) {
          try {
            final field = await ref
                .read(iFieldLookupProvider)
                .findById(fieldId);
            fieldName = field?.name;
            final farmId = field?.farmId.trim() ?? '';
            if (farmId.isNotEmpty) {
              final farm = await ref.read(iFarmLookupProvider).findById(farmId);
              farmName = farm?.name;
            }
          } catch (_) {
            fieldName = null;
            farmName = null;
          }
        }
        lines.add(
          resolveVisitReportLine(
            resolvedFieldName: fieldName,
            resolvedFarmName: farmName,
            eventFieldName: query.eventFieldName,
            eventFarmName: query.eventFarmName,
          ),
        );
      }
      return lines;
    });

class VisitReportsSection extends ConsumerWidget {
  const VisitReportsSection({
    super.key,
    required this.sessionId,
    this.eventFieldName,
    this.eventFarmName,
  });

  final String sessionId;
  final String? eventFieldName;
  final String? eventFarmName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = VisitReportQuery(
      sessionId: sessionId,
      eventFieldName: eventFieldName,
      eventFarmName: eventFarmName,
    );
    final reports = ref.watch(visitReportLinesProvider(query));

    return reports.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 12),
        child: Text('Não foi possível listar os relatórios desta visita.'),
      ),
      data: (lines) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Relatórios desta visita',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(visitReportCountLabel(lines.length)),
            if (lines.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final line in lines)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(line.label),
                ),
            ],
          ],
        );
      },
    );
  }
}
