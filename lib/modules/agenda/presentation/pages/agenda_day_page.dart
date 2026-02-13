import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/event.dart';
import '../providers/agenda_provider.dart';
import '../widgets/day_event_card.dart';
import '../widgets/create_event_dialog.dart';

/// Página de visualização dos eventos de um dia específico
class AgendaDayPage extends ConsumerWidget {
  final DateTime selectedDate;

  const AgendaDayPage({
    super.key,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaState = ref.watch(agendaProvider);
    final events = ref.read(agendaProvider.notifier).getEventsByDay(selectedDate);

    // Ordena por horário
    final sortedEvents = [...events]
      ..sort((a, b) => a.dataInicioPlanejada.compareTo(b.dataInicioPlanejada));

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(selectedDate)),
        actions: [
          // Indicador de eventos ativos
          if (sortedEvents.any((e) => e.status.isActive))
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ATIVO',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: agendaState.isLoading
          ? const Center(child: CircularProgressIndicator())
          : sortedEvents.isEmpty
              ? _buildEmptyState(context)
              : _buildEventList(sortedEvents),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateEventDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.event_available,
            size: 64,
            color: theme.disabledColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Nenhum evento agendado',
            style: theme.textTheme.titleMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Toque no + para criar um evento',
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventList(List<Event> events) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return DayEventCard(
          event: event,
          onTap: () {
            // TODO: abrir detalhes do evento
          },
        );
      },
    );
  }

  void _showCreateEventDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CreateEventDialog(
        initialDate: selectedDate,
      ),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ];

    return '${date.day} de ${months[date.month - 1]} ${date.year}';
  }
}
