import 'package:soloforte_app/modules/agenda/domain/entities/event.dart';
import 'package:soloforte_app/modules/agenda/domain/services/i_agenda_notification_service.dart';

/// Implementação fake de [IAgendaNotificationService] para testes.
///
/// Rastreia quais eventos tiveram notificações agendadas e canceladas,
/// sem precisar de plataforma real (sem FlutterLocalNotificationsPlugin).
class FakeAgendaNotificationService implements IAgendaNotificationService {
  final List<String> scheduledIds = [];
  final List<String> cancelledIds = [];

  @override
  Future<void> scheduleEventNotifications(Event event) async {
    scheduledIds.add(event.id);
  }

  @override
  Future<void> cancelEventNotifications(String eventId) async {
    cancelledIds.add(eventId);
  }

  /// Resets para usar o mesmo fake entre testes.
  void reset() {
    scheduledIds.clear();
    cancelledIds.clear();
  }
}
