import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup.dart';
import 'package:soloforte_app/core/contracts/i_farm_lookup_provider.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

import '../../domain/entities/event.dart';
import '../services/agenda_visit_share.dart';

final _historyClientProvider = FutureProvider.autoDispose
    .family<ClientSummary?, String>(
      (ref, id) => ref.watch(clientLookupProvider).findById(id),
    );

final _historyFarmProvider = FutureProvider.autoDispose
    .family<FarmSummary?, String>(
      (ref, id) => ref.watch(iFarmLookupProvider).findById(id),
    );

/// Lista as visitas realizadas do mês exibido no calendário.
class AgendaVisitHistorySection extends StatelessWidget {
  const AgendaVisitHistorySection({super.key, required this.events});

  final List<Event> events;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Visitas realizadas',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        for (final event in events) ...[
          _VisitHistoryTile(event: event),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _VisitHistoryTile extends ConsumerWidget {
  const _VisitHistoryTile({required this.event});

  final Event event;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final clientAsync = ref.watch(_historyClientProvider(event.clienteId));
    final clientNome = clientAsync.when(
      data: (client) => client?.name ?? 'Cliente não encontrado',
      loading: () => '…',
      error: (_, __) => 'Cliente não encontrado',
    );
    final farmId = event.fazendaId?.trim() ?? '';
    final farmAsync = farmId.isEmpty
        ? null
        : ref.watch(_historyFarmProvider(farmId));
    final farmNome = farmAsync?.when(
      data: (farm) => farm?.name,
      loading: () => '…',
      error: (_, __) => null,
    );

    final subtitle = farmNome == null || farmNome.isEmpty
        ? clientNome
        : '$clientNome · $farmNome';

    return Material(
      color: theme.cardColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.push(AppRoutes.agendaEvent(event.id)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: theme.brightness == Brightness.dark
                  ? const Color(0xFF2A3136)
                  : const Color(0xFFE5E7EB),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatWhen(event.dataInicioPlanejada),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      event.titulo,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () =>
                    openAgendaVisitShare(context, ref, event: event),
                child: const Text('Enviar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatWhen(DateTime date) {
    const months = [
      'jan',
      'fev',
      'mar',
      'abr',
      'mai',
      'jun',
      'jul',
      'ago',
      'set',
      'out',
      'nov',
      'dez',
    ];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${months[date.month - 1]} · $hour:$minute';
  }
}
