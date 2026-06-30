import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/event.dart';
import '../providers/agenda_export_provider.dart';
import '../providers/agenda_provider.dart';
import '../widgets/day_event_card.dart';
import '../../../../core/constants/layout_constants.dart';

/// Página de visualização dos eventos de um dia específico
class AgendaDayPage extends ConsumerStatefulWidget {
  final DateTime selectedDate;

  const AgendaDayPage({super.key, required this.selectedDate});

  @override
  ConsumerState<AgendaDayPage> createState() => _AgendaDayPageState();
}

class _AgendaDayPageState extends ConsumerState<AgendaDayPage> {
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final agendaState = ref.watch(agendaProvider);
    final events = ref
        .read(agendaProvider.notifier)
        .getEventsByDay(widget.selectedDate);

    // Ordena por horário
    final sortedEvents = [...events]
      ..sort((a, b) => a.dataInicioPlanejada.compareTo(b.dataInicioPlanejada));

    return Scaffold(
      appBar: AppBar(
        title: Text(_formatDate(widget.selectedDate)),
        automaticallyImplyLeading: false,
        actions: [
          _buildExportAction(context, sortedEvents),
          // Indicador de eventos ativos
          if (sortedEvents.any((e) => e.status.isActive))
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
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
    );
  }

  Widget _buildExportAction(BuildContext context, List<Event> events) {
    if (_isExporting) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return IconButton(
      icon: const Icon(Icons.ios_share),
      tooltip: 'Exportar agenda',
      onPressed: events.isEmpty
          ? null
          : () => _shareHtmlExport(context, events),
    );
  }

  Future<void> _shareHtmlExport(
    BuildContext context,
    List<Event> events,
  ) async {
    setState(() => _isExporting = true);

    try {
      final html = await ref.read(agendaExportProvider(events).future);
      final directory = await getTemporaryDirectory();
      final date = DateFormat('yyyyMMdd').format(widget.selectedDate);
      final file = File('${directory.path}/agenda_export_$date.html');

      await file.writeAsString(html);
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'text/html')],
        subject:
            'Agenda SoloForte - ${DateFormat('dd/MM/yyyy').format(widget.selectedDate)}',
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Erro ao exportar agenda')));
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Widget _buildEmptyState(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_available, size: 64, color: theme.disabledColor),
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
      padding: const EdgeInsets.only(top: 8, bottom: kFabSafeArea),
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
