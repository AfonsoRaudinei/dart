import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:soloforte_app/core/contracts/i_producer_visit_calendar.dart';
import 'package:soloforte_app/core/contracts/i_producer_visit_calendar_provider.dart';
import 'package:soloforte_app/core/utils/user_facing_error.dart';

final visitConfirmedForProducerProvider = FutureProvider.autoDispose
    .family<bool, String>((ref, sessionId) {
      return ref.read(producerVisitCalendarProvider).isConfirmed(sessionId);
    });

class ConfirmVisitForProducerButton extends ConsumerWidget {
  const ConfirmVisitForProducerButton({
    super.key,
    required this.sessionId,
    required this.clientId,
    required this.visitedAt,
    this.farmName,
    this.fieldName,
  });

  final String sessionId;
  final String clientId;
  final DateTime visitedAt;
  final String? farmName;
  final String? fieldName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final confirmed = ref.watch(visitConfirmedForProducerProvider(sessionId));

    return confirmed.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (isConfirmed) {
        if (isConfirmed) {
          return const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.verified_outlined),
            title: Text('Visível para o produtor'),
            subtitle: Text('A visita e as ocorrências entram no calendário dele.'),
          );
        }
        return OutlinedButton(
          onPressed: () => _confirm(context, ref),
          child: const Text('Confirmar para o produtor'),
        );
      },
    );
  }

  Future<void> _confirm(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(producerVisitCalendarProvider).confirmVisit(
        ProducerVisitConfirmationInput(
          sessionId: sessionId,
          clientId: clientId,
          visitedAt: visitedAt,
          farmName: farmName,
          fieldName: fieldName,
        ),
      );
      ref.invalidate(visitConfirmedForProducerProvider(sessionId));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Visita confirmada. O produtor já pode vê-la.'),
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(userFacingError(error, action: 'Erro ao confirmar')),
        ),
      );
    }
  }
}
