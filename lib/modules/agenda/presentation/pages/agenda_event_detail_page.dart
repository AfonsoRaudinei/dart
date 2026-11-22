import 'package:flutter/material.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:soloforte_app/core/ui/field_feedback.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/extensions/context_extensions.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup.dart';
import 'package:soloforte_app/core/contracts/i_field_lookup_provider.dart';
import '../../domain/entities/event.dart';
import '../../domain/entities/visit_session.dart';
import '../../domain/enums/event_status.dart';
import '../../domain/event_when_format.dart';
import '../providers/agenda_provider.dart';
import '../services/agenda_visit_share.dart';
import '../widgets/status_badge.dart';
import '../widgets/event_type_badge.dart';
import '../widgets/visit_edit_dialog.dart';
import '../widgets/visit_reports_section.dart';
import '../widgets/confirm_visit_for_producer_button.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

/// Página de detalhes expandida de um evento
class AgendaEventDetailPage extends ConsumerWidget {
  final String eventId;

  const AgendaEventDetailPage({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaState = ref.watch(agendaProvider);
    final event = agendaState.events.where((e) => e.id == eventId).firstOrNull;

    if (event == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Evento não encontrado'),
          automaticallyImplyLeading: false,
        ),
        body: const Center(child: Text('Evento não encontrado')),
      );
    }

    // Resolve nome do cliente via IClientLookup (ADR-015) — nunca exibe UUID bruto
    final clientAsync = ref.watch(_clientByIdProvider(event.clienteId));
    final clientNome = clientAsync.when(
      data: (c) => c?.name ?? 'Cliente não encontrado',
      loading: () => '…',
      error: (_, __) => 'Cliente não encontrado',
    );

    final farmAsync = event.fazendaId == null
        ? null
        : ref.watch(_farmByIdProvider(event.fazendaId!));
    final farmNome = farmAsync?.when(
      data: (f) => f?.name ?? 'Fazenda não encontrada',
      loading: () => '…',
      error: (_, __) => 'Fazenda não encontrada',
    );

    final fieldAsync = event.talhaoId == null
        ? null
        : ref.watch(_fieldByIdProvider(event.talhaoId!));
    final fieldNome = fieldAsync?.when(
      data: (f) => f?.name ?? 'Talhão não encontrado',
      loading: () => '…',
      error: (_, __) => 'Talhão não encontrado',
    );

    final sessionId = event.visitSessionId;
    final session = sessionId == null
        ? null
        : agendaState.sessions.where((s) => s.id == sessionId).firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Evento'),
        automaticallyImplyLeading: false,
        actions: [
          if (event.visitSessionId?.trim().isNotEmpty ?? false)
            IconButton(
              icon: const Icon(Icons.ios_share_outlined),
              onPressed: () => openAgendaVisitShare(context, ref, event: event),
              tooltip: 'Enviar visita',
            ),
          if (!event.status.isFinished)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditDialog(context, ref, event),
              tooltip: 'Editar evento',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, context.fabSafeBottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(event, session, context),
            const SizedBox(height: 12),
            _buildCard(context, [
              _buildInfoRow('Cliente', clientNome),
              if (farmNome != null && fieldNome != null)
                _buildPairRow(('Fazenda', farmNome), ('Talhão', fieldNome))
              else if (farmNome != null)
                _buildInfoRow('Fazenda', farmNome)
              else if (fieldNome != null)
                _buildInfoRow('Talhão', fieldNome),
              if (session?.notasFinais != null)
                _buildInfoRow('Notas', session!.notasFinais!),
            ]),
            if (event.visitSessionId != null) ...[
              const SizedBox(height: 12),
              VisitReportsSection(
                sessionId: event.visitSessionId!,
                eventFieldName: fieldNome,
                eventFarmName: farmNome,
              ),
            ],
            const SizedBox(height: 12),

            // Ações
            if (!event.status.isFinished) _buildActions(context, ref, event),
            if (event.status == EventStatus.concluido &&
                event.visitSessionId != null &&
                event.clienteId.isNotEmpty) ...[
              ConfirmVisitForProducerButton(
                sessionId: event.visitSessionId!,
                clientId: event.clienteId,
                visitedAt: event.dataInicioPlanejada,
                farmName: farmNome,
                fieldName: fieldNome,
              ),
              const SizedBox(height: 12),
            ],
            if (event.status == EventStatus.concluido &&
                event.visitSessionId != null)
              _buildKeepOrDelete(context, ref, event),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(
    Event event,
    VisitSession? session,
    BuildContext context,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.primaryColor.withValues(alpha: 0.1),
            theme.primaryColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.primaryColor.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          EventTypeBadge(type: event.tipo, size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.titulo,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    StatusBadge(status: event.status, compact: true),
                    Text(event.tipo.label, style: theme.textTheme.bodySmall),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  eventWhenLine(event, session),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.textTheme.bodySmall?.color?.withValues(
                      alpha: 0.7,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
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
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
          ),
          Expanded(
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

  Widget _buildPairRow((String, String) left, (String, String) right) {
    Widget cell((String, String) item) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.$1,
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              Text(
                item.$2,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [cell(left), const VerticalDivider(width: 1), cell(right)],
      ),
    );
  }

  Widget _buildActions(BuildContext context, WidgetRef ref, Event event) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (event.status == EventStatus.agendado)
          ElevatedButton.icon(
            onPressed: () async {
              try {
                final userId = LocalSessionIdentity.resolveUserId();
                if (userId.isEmpty) {
                  throw StateError('Usuário autenticado não encontrado.');
                }

                await ref
                    .read(agendaProvider.notifier)
                    .startEvent(event.id, userId);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Evento iniciado!')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(userFacingError(e, action: 'Erro'))),
                  );
                }
              }
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Iniciar Evento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        if (event.status == EventStatus.emAndamento &&
            event.clienteId.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton.icon(
              onPressed: () => context.go(
                '${AppRoutes.map}?modo=visita&clienteId=${event.clienteId}',
              ),
              icon: const Icon(Icons.map_outlined),
              label: const Text('Ir ao mapa'),
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
                    SnackBar(content: Text(userFacingError(e, action: 'Erro'))),
                  );
                }
              }
            },
            icon: const Icon(Icons.stop),
            label: const Text('Finalizar Evento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amber,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        if (event.status == EventStatus.finalizando)
          ElevatedButton.icon(
            onPressed: () async {
              try {
                await ref.read(agendaProvider.notifier).completeEvent(event.id);
                if (context.mounted) {
                  showFieldSuccess(
                    context,
                    'Visita registrada. Bom trabalho no campo!',
                  );
                  context.go(AppRoutes.agenda);
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(userFacingError(e, action: 'Erro'))),
                  );
                }
              }
            },
            icon: const Icon(Icons.check),
            label: const Text('Concluir Evento'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Excluir evento?'),
                content: const Text(
                  'O evento sai da agenda. Os relatórios feitos na visita continuam em Relatórios.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: TextButton.styleFrom(foregroundColor: Colors.red),
                    child: const Text('Excluir'),
                  ),
                ],
              ),
            );

            if (confirm == true && context.mounted) {
              try {
                await ref.read(agendaProvider.notifier).deleteEvent(event.id);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Evento excluído.')),
                  );
                  context.go(AppRoutes.agendaDay(event.dataInicioPlanejada));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        userFacingError(e, action: 'Erro ao excluir'),
                      ),
                    ),
                  );
                }
              }
            }
          },
          icon: const Icon(Icons.delete_outline),
          label: const Text('Excluir Evento'),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildKeepOrDelete(BuildContext context, WidgetRef ref, Event event) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Visita mantida na agenda.')),
              );
            },
            child: const Text('Manter'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _confirmDelete(
              context,
              ref,
              event,
              title: 'Excluir da agenda?',
              message:
                  'A visita sai da agenda. Os relatórios feitos no talhão continuam em Relatórios.',
              success: 'Visita excluída da agenda.',
            ),
            style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ),
      ],
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Event event, {
    required String title,
    required String message,
    required String success,
  }) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;
    try {
      await ref.read(agendaProvider.notifier).deleteEvent(event.id);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(success)));
        context.go(AppRoutes.agendaDay(event.dataInicioPlanejada));
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(userFacingError(e, action: 'Erro ao excluir')),
          ),
        );
      }
    }
  }

  void _showEditDialog(BuildContext context, WidgetRef ref, Event event) {
    showDialog<void>(
      context: context,
      builder: (_) => VisitEditDialog(event: event),
    );
  }
}

/// Provider privado — resolve ClientSummary por ID via IClientLookup (ADR-015).
/// Padrão idêntico ao adotado em client_selector_dropdown.dart.
final _clientByIdProvider = FutureProvider.autoDispose
    .family<ClientSummary?, String>(
      (ref, id) => ref.watch(clientLookupProvider).findById(id),
    );

final _farmByIdProvider = FutureProvider.autoDispose
    .family<FarmSummary?, String>(
      (ref, id) => ref.watch(iFarmLookupProvider).findById(id),
    );

final _fieldByIdProvider = FutureProvider.autoDispose
    .family<FieldSummary?, String>(
      (ref, id) => ref.watch(iFieldLookupProvider).findById(id),
    );
