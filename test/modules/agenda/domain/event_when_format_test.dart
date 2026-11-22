import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/visit_session.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/domain/event_when_format.dart';

void main() {
  final event = Event(
    id: 'event-1',
    tipo: EventType.visitaTecnica,
    clienteId: 'cliente-1',
    titulo: 'Monitoramento',
    dataInicioPlanejada: DateTime(2026, 11, 9, 6, 8),
    dataFimPlanejada: DateTime(2026, 11, 9, 6, 13),
    status: EventStatus.concluido,
    createdAt: DateTime(2026, 11, 9),
    updatedAt: DateTime(2026, 11, 9),
  );

  VisitSession session({DateTime? end}) {
    return VisitSession(
      id: 'sessao-9',
      eventoId: 'event-1',
      startAtReal: DateTime(2026, 11, 9, 6, 8),
      endAtReal: end,
      createdBy: 'user-1',
      createdAt: DateTime(2026, 11, 9),
    );
  }

  test('dia, horário e duração ficam numa linha só', () {
    expect(eventWhenLine(event), '9 nov 2026 · 06:08 – 06:13 · 5 min');
  });

  test('visita encerrada mostra o horário real', () {
    final line = eventWhenLine(
      event,
      session(end: DateTime(2026, 11, 9, 6, 40)),
    );

    expect(line, '9 nov 2026 · 06:08 – 06:40 · 32 min');
  });

  test('sessão em andamento mantém o horário planejado', () {
    expect(
      eventWhenLine(event, session()),
      '9 nov 2026 · 06:08 – 06:13 · 5 min',
    );
  });

  test('duração curta e longa', () {
    expect(formatEventDuration(0), '<1 min');
    expect(formatEventDuration(59), '59 min');
    expect(formatEventDuration(60), '1h');
    expect(formatEventDuration(80), '1h 20min');
  });
}
