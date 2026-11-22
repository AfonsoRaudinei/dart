import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/domain/visit_history.dart';

void main() {
  final month = DateTime(2026, 11);

  Event event({
    required String id,
    required DateTime start,
    required EventStatus status,
    String? visitSessionId,
  }) {
    return Event(
      id: id,
      tipo: EventType.visitaTecnica,
      clienteId: 'cliente-1',
      titulo: 'Monitoramento',
      dataInicioPlanejada: start,
      dataFimPlanejada: start.add(const Duration(minutes: 5)),
      status: status,
      visitSessionId: visitSessionId,
      createdAt: start,
      updatedAt: start,
    );
  }

  test('lista do mês só inclui visita com sessão', () {
    final events = [
      event(
        id: 'com-sessao',
        start: DateTime(2026, 11, 9, 6, 8),
        status: EventStatus.concluido,
        visitSessionId: 'sessao-9',
      ),
      event(
        id: 'em-andamento',
        start: DateTime(2026, 11, 21, 8),
        status: EventStatus.emAndamento,
        visitSessionId: 'sessao-21',
      ),
      event(
        id: 'sem-sessao',
        start: DateTime(2026, 11, 12, 9),
        status: EventStatus.concluido,
      ),
      event(
        id: 'so-agendada',
        start: DateTime(2026, 11, 4, 9),
        status: EventStatus.agendado,
        visitSessionId: 'sessao-4',
      ),
      event(
        id: 'cancelada',
        start: DateTime(2026, 11, 1, 9),
        status: EventStatus.cancelado,
        visitSessionId: 'sessao-1',
      ),
      event(
        id: 'outro-mes',
        start: DateTime(2026, 10, 30, 9),
        status: EventStatus.concluido,
        visitSessionId: 'sessao-out',
      ),
      event(
        id: 'sessao-vazia',
        start: DateTime(2026, 11, 11, 9),
        status: EventStatus.concluido,
        visitSessionId: '   ',
      ),
    ];

    final history = visitasRealizadasNoMes(events, month);

    expect(history.map((item) => item.id), ['em-andamento', 'com-sessao']);
  });
}
