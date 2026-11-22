import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_status.dart';
import 'package:soloforte_app/modules/agenda/domain/enums/event_type.dart';
import 'package:soloforte_app/modules/agenda/presentation/services/agenda_visit_share.dart';

void main() {
  Event event({String? visitSessionId}) {
    return Event(
      id: 'event-1',
      tipo: EventType.visitaTecnica,
      clienteId: 'cliente-1',
      titulo: 'Monitoramento',
      dataInicioPlanejada: DateTime(2026, 11, 9, 6, 8),
      dataFimPlanejada: DateTime(2026, 11, 9, 6, 13),
      status: EventStatus.concluido,
      visitSessionId: visitSessionId,
      createdAt: DateTime(2026, 11, 9),
      updatedAt: DateTime(2026, 11, 9),
    );
  }

  test('helper de envio recebe evento com sessão', () {
    expect(
      requireAgendaVisitSessionId(event(visitSessionId: 'sessao-9')),
      'sessao-9',
    );
    expect(
      requireAgendaVisitSessionId(event(visitSessionId: '  sessao-9  ')),
      'sessao-9',
    );
  });

  test('helper de envio recusa evento sem sessão', () {
    expect(() => requireAgendaVisitSessionId(event()), throwsArgumentError);
    expect(
      () => requireAgendaVisitSessionId(event(visitSessionId: '   ')),
      throwsArgumentError,
    );
  });
}
