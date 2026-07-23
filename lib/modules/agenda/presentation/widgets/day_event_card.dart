import 'package:flutter/material.dart';
import 'package:soloforte_app/core/session/local_session_identity.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/ui/sheets/soloforte_sheet.dart';
import '../../domain/entities/event.dart';
import '../../domain/enums/event_status.dart';
import '../providers/agenda_provider.dart';
import 'event_type_badge.dart';
import 'status_badge.dart';
import 'visit_edit_dialog.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

/// Card de evento para visualização no dia
class DayEventCard extends ConsumerWidget {
  final Event event;
  final VoidCallback? onTap;
  final bool enablePlanningSwipeActions;
  final Future<void> Function(Event event)? onVisitHtml;

  const DayEventCard({
    super.key,
    required this.event,
    this.onTap,
    this.enablePlanningSwipeActions = false,
    this.onVisitHtml,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    final card = Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2)),
      ),
      child: InkWell(
        onTap: () {
          // Navegar para detalhes do evento
          context.push(AppRoutes.agendaEvent(event.id));
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
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.7,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      event.tipo.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(
                          alpha: 0.6,
                        ),
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
    );

    if (enablePlanningSwipeActions) {
      return Dismissible(
        key: ValueKey(event.id),
        direction: DismissDirection.endToStart,
        confirmDismiss: (direction) async {
          await _showSwipeActions(context, ref, event);
          return false; // nao remove visualmente; apenas aciona as opcoes
        },
        secondaryBackground: _buildSwipeBackground(),
        child: card,
      );
    }

    // Comportamento existente (outras telas): swipe direita conclui, swipe esquerda cancela.
    return Dismissible(
      key: ValueKey(event.id),
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
      child: card,
    );
  }

  Widget _buildSwipeBackground() {
    return Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.edit_outlined, color: Colors.white, size: 20),
                SizedBox(height: 2),
                Text(
                  'Editar',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_outline, color: Colors.white, size: 20),
                SizedBox(height: 2),
                Text(
                  'Excluir',
                  style: TextStyle(color: Colors.white, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showSwipeActions(
    BuildContext context,
    WidgetRef ref,
    Event event,
  ) async {
    await showSoloForteSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      showDragHandle: false,
      useSafeArea: false,
      shape: const RoundedRectangleBorder(),
      clipBehavior: Clip.none,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(ctx).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                event.titulo,
                style: Theme.of(
                  ctx,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            const Divider(height: 1),
            if (onVisitHtml != null)
              ListTile(
                leading: const Icon(
                  Icons.article_outlined,
                  color: Color(0xFF16A34A),
                ),
                title: const Text('Pré-visualizar HTML de visita'),
                onTap: () async {
                  Navigator.of(ctx).pop();
                  await onVisitHtml!(event);
                },
              ),
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: Color(0xFF3B82F6),
              ),
              title: const Text('Editar evento'),
              onTap: () {
                Navigator.of(ctx).pop();
                VisitEditDialog.show(context, event);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: Color(0xFFEF4444),
              ),
              title: const Text(
                'Excluir evento',
                style: TextStyle(color: Color(0xFFEF4444)),
              ),
              onTap: () async {
                Navigator.of(ctx).pop();
                await _confirmarExclusao(context, ref, event);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmarExclusao(
    BuildContext context,
    WidgetRef ref,
    Event event,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir evento?'),
        content: Text('Remover "${event.titulo}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmar == true && context.mounted) {
      await ref.read(agendaProvider.notifier).cancelEvent(event.id);
    }
  }

  Widget _buildActionButton(BuildContext context, WidgetRef ref) {
    switch (event.status) {
      case EventStatus.agendado:
        return ElevatedButton(
          onPressed: () async {
            try {
              final userId = LocalSessionIdentity.resolveUserId();
              if (userId.isEmpty) {
                throw StateError('Usuário autenticado não encontrado.');
              }

              await ref
                  .read(agendaProvider.notifier)
                  .startEvent(event.id, userId);
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(userFacingError(e, action: 'Erro'))));
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(userFacingError(e, action: 'Erro'))));
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
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(userFacingError(e, action: 'Erro'))));
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
