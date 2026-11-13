import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/layout_constants.dart';
import '../../../../core/contracts/i_producer_visit_calendar.dart';
import '../../../../core/contracts/i_producer_visit_calendar_provider.dart';
import 'producer_calendar_estadios.dart';
import 'producer_calendar_plantios.dart';

enum ProducerCalendarSegment { visitas, plantios, estadios }

final producerCalendarProvider =
    FutureProvider.autoDispose<List<ProducerVisitCalendarEntry>>((ref) {
      return ref.read(producerVisitCalendarProvider).listForProducer();
    });

class ProducerCalendarScreen extends ConsumerStatefulWidget {
  const ProducerCalendarScreen({super.key});

  @override
  ConsumerState<ProducerCalendarScreen> createState() =>
      _ProducerCalendarScreenState();
}

class _ProducerCalendarScreenState
    extends ConsumerState<ProducerCalendarScreen> {
  ProducerCalendarSegment _segment = ProducerCalendarSegment.visitas;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Calendário')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedButton<ProducerCalendarSegment>(
              key: const Key('producer-calendar-segment'),
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                  value: ProducerCalendarSegment.visitas,
                  label: Text('Visitas'),
                ),
                ButtonSegment(
                  value: ProducerCalendarSegment.plantios,
                  label: Text('Plantios'),
                ),
                ButtonSegment(
                  value: ProducerCalendarSegment.estadios,
                  label: Text('Estádios'),
                ),
              ],
              selected: {_segment},
              onSelectionChanged: (next) {
                setState(() => _segment = next.first);
              },
            ),
          ),
          Expanded(child: _segmentBody()),
        ],
      ),
    );
  }

  Widget _segmentBody() {
    switch (_segment) {
      case ProducerCalendarSegment.visitas:
        return const _ProducerVisitsBody();
      case ProducerCalendarSegment.plantios:
        return const ProducerCalendarPlantios();
      case ProducerCalendarSegment.estadios:
        return const ProducerCalendarEstadios();
    }
  }
}

class _ProducerVisitsBody extends ConsumerWidget {
  const _ProducerVisitsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendar = ref.watch(producerCalendarProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return calendar.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, _) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Não foi possível carregar as visitas confirmadas.'),
        ),
      ),
      data: (entries) {
        if (entries.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'Nenhuma visita confirmada pelo consultor.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, kFabSafeArea),
          itemCount: entries.length,
          separatorBuilder: (_, _) => const SizedBox(height: 12),
          itemBuilder: (context, index) {
            final entry = entries[index];
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dateFormat.format(entry.visitedAt),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text('${entry.fieldName} · ${entry.farmName}'),
                    const SizedBox(height: 12),
                    Text(
                      entry.occurrences.isEmpty
                          ? 'Nenhuma ocorrência nesta visita.'
                          : entry.occurrences.length == 1
                          ? '1 ocorrência'
                          : '${entry.occurrences.length} ocorrências',
                    ),
                    for (final occurrence in entry.occurrences)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(occurrence.label),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
