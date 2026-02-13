import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/event.dart';
import '../../domain/enums/event_status.dart';
import '../providers/agenda_provider.dart';
import 'event_type_badge.dart';
import 'status_badge.dart';

/// Card de evento para visualização no dia
class DayEventCard extends ConsumerWidget {
  final Event event;
  final VoidCallback? onTap;

  const DayEventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dismissible(
      key: Key(event.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Swipe direita → concluir
          if (event.status == EventStatus.finalizando) {
            await ref.read(agendaProvider.notifier).completeEvent(event.id);
            return true;
          }
        } else if (direction == DismissDirection.endToStart) {
          // Swipe esquerda → cancelar
          final confirm = await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Cancelar Evento'),
              content: Text('Deseja cancelar "${event.titulo}"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Não'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Sim'),
                ),
              ],
            ),
          );

          if (confirm == true) {
            await ref.read(agendaProvider.notifier).cancelEvent(event.id);
            return true;
          }
        }
        return false;
      },
      background: Container(
        color: Colors.green,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.check, color: Colors.white, size: 32),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.close, color: Colors.white, size: 32),
      ),
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.2),
          ),
        ),
        child: InkWell(
          onTap: () {
            // Navegar para detalhes do evento
            context.push('/agenda/event/${event.id}');
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Ícone tipo
                EventTypeBadge(type: event.tipo, size: 48),
                const SizedBox(width: 12),

                // Info principal
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.titulo,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${_formatTime(event.dataInicioPlanejada)} - ${_formatTime(event.dataFimPlanejada)}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        event.tipo.label,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ),

                // Status + Ações
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusBadge(status: event.status, compact: true),
                    const SizedBox(height: 8),
                    _buildActionButton(context, ref),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    switch (event.status) {
      case EventStatus.agendado:
        return ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(agendaProvider.notifier).startEvent(
                    event.id,
                    'user-current', // TODO: pegar usuário real
                  );
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(80, 32),
          ),
          child: const Text('Iniciar', style: TextStyle(fontSize: 12)),
        );

      case EventStatus.emAndamento:
        return ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(agendaProvider.notifier).finalizeEvent(event.id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.amber,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(80, 32),
          ),
          child: const Text('Finalizar', style: TextStyle(fontSize: 12)),
        );

      case EventStatus.finalizando:
        return ElevatedButton(
          onPressed: () async {
            try {
              await ref.read(agendaProvider.notifier).completeEvent(event.id);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Erro: $e')),
                );
              }
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(80, 32),
          ),
          child: const Text('Concluir', style: TextStyle(fontSize: 12)),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
