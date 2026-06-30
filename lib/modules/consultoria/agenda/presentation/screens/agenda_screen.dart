import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../ui/theme/soloforte_theme.dart';
import '../../domain/models/agenda_event.dart';
import '../../data/repositories/agenda_repository.dart';
import '../controllers/agenda_controller.dart';

final allAgendaEventsProvider = FutureProvider.autoDispose<List<AgendaEvent>>((
  ref,
) async {
  return ref.watch(agendaRepositoryProvider).getAllEvents();
});

class AgendaScreen extends ConsumerWidget {
  const AgendaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(allAgendaEventsProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Agenda', style: SoloTextStyles.headingLarge),
            ),
            Expanded(
              child: eventsAsync.when(
                data: (events) {
                  if (events.isEmpty) {
                    return Center(
                      child: Text(
                        'Nenhum evento agendado.',
                        style: SoloTextStyles.body,
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: events.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final dateFmt = DateFormat('dd/MM/yyyy HH:mm');
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          event.activityType,
                          style: SoloTextStyles.body.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${dateFmt.format(event.scheduledDate)}\n'
                          '${event.description ?? 'Sem descrição'}',
                        ),
                        trailing: Chip(
                          label: Text(
                            event.status.name,
                            style: const TextStyle(fontSize: 11),
                          ),
                        ),
                        onTap: () => _showEditEventDialog(context, ref, event),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Erro: $e')),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showCreateEventDialog(BuildContext context, WidgetRef ref) async {
    final activityCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    DateTime selectedDate = DateTime.now().add(const Duration(hours: 1));

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo evento'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: activityCtrl,
              decoration: const InputDecoration(labelText: 'Atividade'),
            ),
            TextField(
              controller: descCtrl,
              decoration: const InputDecoration(labelText: 'Descrição'),
            ),
            const SizedBox(height: 12),
            Text(
              'Data: ${DateFormat('dd/MM/yyyy HH:mm').format(selectedDate)}',
              style: SoloTextStyles.label,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (activityCtrl.text.trim().isEmpty) return;
              final repo = ref.read(agendaRepositoryProvider);
              await repo.saveEvent(
                AgendaEvent(
                  id: const Uuid().v4(),
                  producerId: 'local',
                  areaId: 'local',
                  activityType: activityCtrl.text.trim(),
                  scheduledDate: selectedDate,
                  description: descCtrl.text.trim().isEmpty
                      ? null
                      : descCtrl.text.trim(),
                  createdAt: DateTime.now(),
                ),
              );
              ref.invalidate(allAgendaEventsProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditEventDialog(
    BuildContext context,
    WidgetRef ref,
    AgendaEvent event,
  ) async {
    final descCtrl = TextEditingController(text: event.description ?? '');
    var status = event.status;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Editar evento'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(event.activityType, style: SoloTextStyles.headingMedium),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: 'Descrição'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<AgendaStatus>(
                value: status,
                items: AgendaStatus.values
                    .map(
                      (s) => DropdownMenuItem(value: s, child: Text(s.name)),
                    )
                    .toList(),
                onChanged: (v) => setState(() => status = v ?? status),
                decoration: const InputDecoration(labelText: 'Status'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final repo = ref.read(agendaRepositoryProvider);
                await repo.updateEvent(
                  event.copyWith(
                    description: descCtrl.text.trim(),
                    status: status,
                  ),
                );
                ref.invalidate(allAgendaEventsProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }
}
