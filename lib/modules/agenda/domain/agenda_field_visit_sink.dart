import 'entities/event.dart';
import 'entities/visit_session.dart';

/// Atualiza o estado em memória da agenda depois de persistir a visita de campo.
///
/// O observer de relatório só vê a transição se a sessão entrar no notifier,
/// não só no SQLite. ADR-060.
abstract class AgendaFieldVisitSink {
  void upsertFieldVisit({required Event event, required VisitSession session});
}
