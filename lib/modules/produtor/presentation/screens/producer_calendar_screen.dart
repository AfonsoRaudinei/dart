import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:soloforte_app/core/constants/layout_constants.dart';
import 'package:soloforte_app/core/contracts/i_producer_visit_calendar.dart';
import 'package:soloforte_app/core/contracts/i_producer_visit_calendar_provider.dart';

final producerCalendarProvider =
    FutureProvider.autoDispose<List<ProducerVisitCalendarEntry>>((ref) {
      return ref.read(producerVisitCalendarProvider).listForProducer();
    });

class ProducerCalendarScreen extends ConsumerWidget {
  const ProducerCalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendar = ref.watch(producerCalendarProvider);
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      appBar: AppBar(title: const Text('Calendário')),
      body: calendar.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
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
            separatorBuilder: (_, __) => const SizedBox(height: 12),
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
      ),
    );
  }
}
