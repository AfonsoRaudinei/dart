// Exemplo documental: não faz parte do bundle nem da análise do aplicativo.
// ════════════════════════════════════════════════════════════════════════════
// EXEMPLO DE USO - VISIT (EVENT) COMO ENTIDADE ÚNICA
// ════════════════════════════════════════════════════════════════════════════
//
// Este arquivo demonstra como usar Event/Visit como entidade única
// para planejamento, execução e conclusão de visitas.
//
// ════════════════════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/visit.dart'; // Visit = Event (alias)
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/presentation/providers/agenda_provider.dart';

// ────────────────────────────────────────────────────────────────────────────
// EXEMPLO 1: Criar visita (planejamento)
// ────────────────────────────────────────────────────────────────────────────

class ExemploCriarVisita extends ConsumerWidget {
  final String clienteId;
  final String? fazendaId;
  final DateTime data;

  const ExemploCriarVisita({
    super.key,
    required this.clienteId,
    this.fazendaId,
    required this.data,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton(
      onPressed: () async {
        try {
          // ✅ Verificar conflito ANTES de criar
          final hasConflict = ref
              .read(agendaProvider.notifier)
              .hasTimeConflict(data, data.add(const Duration(hours: 2)));

          if (hasConflict) {
            // ⚠️ Alertar conflito (não bloquear)
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Conflito de Horário'),
                content: const Text(
                  'Já existe uma visita agendada neste horário. Deseja continuar mesmo assim?',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _createVisit(ref);
                    },
                    child: const Text('Continuar'),
                  ),
                ],
              ),
            );
            return;
          }

          await _createVisit(ref);
        } catch (e) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Erro ao criar visita: $e')));
        }
      },
      child: const Text('Criar Visita'),
    );
  }

  Future<void> _createVisit(WidgetRef ref) async {
    // ✅ Criar visita (usa Event internamente)
    final visit = await ref
        .read(agendaProvider.notifier)
        .createEvent(
          tipo: EventType.visitaTecnica,
          clienteId: clienteId,
          fazendaId: fazendaId,
          titulo: 'Visita Técnica',
          dataInicioPlanejada: data,
          dataFimPlanejada: data.add(const Duration(hours: 2)),
        );

    print('Visita criada: ${visit.id}');
    print('Status: ${visit.visitStatus.label}');
  }
}

// ────────────────────────────────────────────────────────────────────────────
// EXEMPLO 2: Iniciar visita (planejamento → execução)
// ────────────────────────────────────────────────────────────────────────────

class ExemploIniciarVisita extends ConsumerWidget {
  final String visitId;
  final String userId;

  const ExemploIniciarVisita({
    super.key,
    required this.visitId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaState = ref.watch(agendaProvider);
    final visit = agendaState.events.firstWhere((e) => e.id == visitId);

    return ElevatedButton(
      onPressed: visit.canStart
          ? () async {
              try {
                // ✅ Verificar se já existe visita em andamento
                if (ref.read(agendaProvider.notifier).hasActiveVisit()) {
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Visita em Andamento'),
                      content: const Text(
                        'Já existe uma visita em andamento. Finalize-a antes de iniciar outra.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('OK'),
                        ),
                      ],
                    ),
                  );
                  return;
                }

                // ✅ Iniciar visita
                final session = await ref
                    .read(agendaProvider.notifier)
                    .startEvent(visitId, userId);

                print('Visita iniciada!');
                print('Session ID: ${session.id}');
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erro: $e')));
              }
            }
          : null,
      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF4ADE80)),
      child: const Text('Iniciar Visita'),
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// EXEMPLO 3: Encerrar visita (execução → conclusão)
// ────────────────────────────────────────────────────────────────────────────

class ExemploEncerrarVisita extends ConsumerWidget {
  final String visitId;

  const ExemploEncerrarVisita({super.key, required this.visitId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaState = ref.watch(agendaProvider);
    final visit = agendaState.events.firstWhere((e) => e.id == visitId);

    return Column(
      children: [
        // Botão Finalizar (em andamento → finalizando)
        if (visit.canFinish)
          ElevatedButton(
            onPressed: () async {
              try {
                await ref.read(agendaProvider.notifier).finalizeEvent(visitId);
                print('Visita finalizada (aguardando conclusão)');
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erro: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFBBF24),
            ),
            child: const Text('Finalizar Visita'),
          ),

        // Botão Concluir (finalizando → concluído)
        if (visit.status.name == 'finalizando')
          ElevatedButton(
            onPressed: () async {
              try {
                await ref
                    .read(agendaProvider.notifier)
                    .completeEvent(visitId, notasFinais: 'Visita concluída');

                print('Visita concluída!');
              } catch (e) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text('Erro: $e')));
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4ADE80),
            ),
            child: const Text('Concluir Visita'),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// EXEMPLO 4: Listar visitas por status
// ────────────────────────────────────────────────────────────────────────────

class ExemploListarVisitas extends ConsumerWidget {
  const ExemploListarVisitas({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agendaNotifier = ref.read(agendaProvider.notifier);

    return Column(
      children: [
        // Visitas planejadas
        Text('Planejadas: ${agendaNotifier.getPlannedVisits().length}'),

        // Visitas em andamento
        Text('Em andamento: ${agendaNotifier.getOngoingVisits().length}'),

        // Visitas concluídas
        Text('Concluídas: ${agendaNotifier.getCompletedVisits().length}'),

        // Visita ativa (se houver)
        if (agendaNotifier.hasActiveVisit())
          Card(
            color: const Color(0xFFFBBF24).withValues(alpha: 0.1),
            child: ListTile(
              leading: const Icon(Icons.access_time, color: Color(0xFFFBBF24)),
              title: Text(agendaNotifier.getActiveVisit()!.titulo),
              subtitle: const Text('Em andamento'),
            ),
          ),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────────────────────
// EXEMPLO 5: Card de visita com status
// ────────────────────────────────────────────────────────────────────────────

class VisitCard extends StatelessWidget {
  final Visit visit; // Visit = Event

  const VisitCard({super.key, required this.visit});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 4,
          decoration: BoxDecoration(
            color: Color(visit.statusColor),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        title: Text(visit.titulo),
        subtitle: Text(visit.visitStatus.label),
        trailing: Text(visit.statusIcon),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// FLUXO COMPLETO
// ════════════════════════════════════════════════════════════════════════════
//
// 1. CRIAR VISITA
//    → createEvent() → status = agendado
//    → Verificar conflito (alerta, não bloqueia)
//
// 2. INICIAR VISITA
//    → startEvent() → status = emAndamento
//    → Cria visitSessionId
//    → Apenas uma visita em andamento por vez
//
// 3. FINALIZAR VISITA
//    → finishEvent() → status = finalizando
//    → Aguarda confirmação final
//
// 4. CONCLUIR VISITA
//    → completeEvent() → status = concluido
//    → Fecha sessão
//    → Salva notas finais
//
// ════════════════════════════════════════════════════════════════════════════
