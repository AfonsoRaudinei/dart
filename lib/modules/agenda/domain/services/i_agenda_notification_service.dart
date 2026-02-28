import '../entities/event.dart';

/// Contrato para o serviço de notificações da Agenda.
///
/// Separa o domínio (use cases) da implementação de plataforma
/// (FlutterLocalNotificationsPlugin), permitindo injeção de fakes em testes.
abstract interface class IAgendaNotificationService {
  Future<void> scheduleEventNotifications(Event event);
  Future<void> cancelEventNotifications(String eventId);
}
