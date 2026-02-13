import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../domain/entities/event.dart';
import '../../domain/enums/event_status.dart';
import '../providers/agenda_provider.dart';
import '../widgets/status_badge.dart';
import '../widgets/event_type_badge.dart';

/// Página de detalhes expandida de um evento
class AgendaEventDetailPage extends ConsumerWidget {
  final String eventId;

  const AgendaEventDetailPage({
    super.key,
    required this.eventId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaState = ref.watch(agendaProvider);
    final event = agendaState.events.where((e) => e.id == eventId).firstOrNull;

    if (event == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Evento não encontrado')),
        body: const Center(
          child: Text('Evento não encontrado'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Evento'),
        actions: [
          if (!event.status.isFinished)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, ref, event),
              tooltip: 'Editar evento',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            _buildHeader(event, context),
            const SizedBox(height: 24),

            // Informações principais
            _buildInfoSection('Informações Gerais', [
              _buildInfoRow(Icons.title, 'Título', event.titulo),
              _buildInfoRow(Icons.category, 'Tipo', event.tipo.label),
              _buildInfoRow(
                Icons.access_time,
                'Horário',
                '${_formatTime(event.dataInicioPlanejada)} - ${_formatTime(event.dataFimPlanejada)}',
              ),
              _buildInfoRow(
                Icons.timelapse,
                'Duração',
                '${event.duracaoPlanejadaMin} minutos',
              ),
            ]),
            const SizedBox(height: 24),

            // Cliente/Fazenda/Talhão
            _buildInfoSection('Localização', [
              _buildInfoRow(Icons.person, 'Cliente', event.clienteId),
              if (event.fazendaId != null)
                _buildInfoRow(Icons.agriculture, 'Fazenda', event.fazendaId!),
              if (event.talhaoId != null)
                _buildInfoRow(Icons.landscape, 'Talhão', event.talhaoId!),
            ]),
            const SizedBox(height: 24),

            // Sessão de visita
            if (event.visitSessionId != null) ...[
              _buildSessionInfo(ref, event),
              const SizedBox(height: 24),
            ],

            // Informações técnicas
            _buildInfoSection('Informações Técnicas', [
              _buildInfoRow(Icons.fingerprint, 'ID', event.id),
              _buildInfoRow(
                Icons.calendar_today,
                'Criado em',
                _formatDateTime(event.createdAt),
              ),
              _buildInfoRow(
                Icons.update,
                'Atualizado em',
                _formatDateTime(event.updatedAt),
              ),
              _buildInfoRow(
                Icons.sync,
                'Status Sync',
                event.syncStatus,
              ),
            ]),
            const SizedBox(height: 24),

            // Ações
            if (!event.status.isFinished) _buildActions(context, ref, event),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(Event event, BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.primaryColor.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          EventTypeBadge(type: event.tipo, size: 64),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.titulo,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                StatusBadge(status: event.status),
                const SizedBox(height: 4),
                Text(
                  _formatDate(event.dataInicioPlanejada),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              for (int i = 0; i < children.length; i++) ...[
                children[i],
                if (i < children.length - 1) const Divider(height: 1),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w600),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionInfo(WidgetRef ref, Event event) {
    final session = ref
        .watch(agendaProvider)
        .sessions
        .where((s) => s.id == event.visitSessionId)
        .firstOrNull;

    if (session == null) return const SizedBox.shrink();

    return _buildInfoSection('Sessão de Visita', [
      _buildInfoRow(
        Icons.play_arrow,
        'Início Real',
        _formatDateTime(session.startAtReal),
      ),
      if (session.endAtReal != null)
        _buildInfoRow(
          Icons.stop,
          'Fim Real',
          _formatDateTime(session.endAtReal!),
        ),
      _buildInfoRow(
        Icons.timer,
        'Duração',
        '${session.currentDurationMin} minutos',
      ),
      if (session.notasFinais != null)
        _buildInfoRow(
          Icons.notes,
          'Notas',
          session.notasFinais!,
        ),
    ]);
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Ações',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (event.status == EventStatus.agendado)
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await ref.read(agendaProvider.notifier).startEvent(
                      event.id,
                      'user-current',
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Evento iniciado!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Evento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if (event.status == EventStatus.emAndamento)
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await ref.read(agendaProvider.notifier).finalizeEvent(event.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Evento em finalização!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.stop),
            label: const Text('Finalizar Evento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        if (event.status == EventStatus.finalizando)
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await ref.read(agendaProvider.notifier).completeEvent(event.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Evento concluído!')),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Concluir Evento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Cancelar Evento'),
                content: const Text('Deseja realmente cancelar este evento?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Não'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Sim, cancelar'),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              try {
                await ref.read(agendaProvider.notifier).cancelEvent(event.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Evento cancelado!')),
                  );
                  context.pop();
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erro: $e')),
                  );
                }
              }
            }
          },
          icon: const Icon(Icons.cancel),
          label: const Text('Cancelar Evento'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ],
    );
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Event event) {
    // TODO: Implementar edição completa
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edição em desenvolvimento')),
    );
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Fev',
      'Mar',
      'Abr',
      'Mai',
      'Jun',
      'Jul',
      'Ago',
      'Set',
      'Out',
      'Nov',
      'Dez',
    ];
    return '${date.day} de ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  String _formatDateTime(DateTime dateTime) {
    return '${_formatDate(dateTime)} às ${_formatTime(dateTime)}';
  }
}
