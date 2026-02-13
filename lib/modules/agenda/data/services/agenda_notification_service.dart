import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../domain/entities/event.dart';
import '../../domain/enums/event_status.dart';

/// Serviço de notificações locais para eventos da agenda
class AgendaNotificationService {
  static final AgendaNotificationService _instance =
      AgendaNotificationService._internal();

  factory AgendaNotificationService() => _instance;

  AgendaNotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  /// Inicializa o serviço de notificações
  Future<void> initialize() async {
    if (_initialized) return;

    // Inicializa timezone
    tz.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('America/Sao_Paulo'));

    // Configuração Android
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');

    // Configuração iOS
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    // Inicializa plugin
    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Solicita permissões (iOS e Android 13+)
    await _requestPermissions();

    _initialized = true;
  }

  /// Solicita permissões
  Future<void> _requestPermissions() async {
    // Android 13+
    await _notifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();

    // iOS
    await _notifications
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Callback quando notificação é tocada
  void _onNotificationTapped(NotificationResponse response) {
    // TODO: Navegar para o evento
    final eventId = response.payload;
    if (eventId != null) {
      // Implementar navegação via GoRouter
      // context.push('/agenda/event/$eventId');
    }
  }

  /// Agenda notificações para um evento
  Future<void> scheduleEventNotifications(Event event) async {
    if (!_initialized) await initialize();

    // Só agenda para eventos futuros e não cancelados
    if (event.status == EventStatus.cancelado ||
        event.dataInicioPlanejada.isBefore(DateTime.now())) {
      return;
    }

    // 1. Notificação 30 minutos antes
    await _scheduleReminderNotification(event);

    // 2. Notificação quando evento inicia
    await _scheduleStartNotification(event);
  }

  /// Notificação de lembrete (30min antes)
  Future<void> _scheduleReminderNotification(Event event) async {
    final reminderTime = event.dataInicioPlanejada.subtract(
      const Duration(minutes: 30),
    );

    // Só agenda se for no futuro
    if (reminderTime.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'agenda_reminders',
      'Lembretes de Eventos',
      channelDescription: 'Notificações 30 minutos antes dos eventos',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id: _getReminderNotificationId(event.id),
      title: '${event.tipo.icon} Lembrete: ${event.titulo}',
      body: 'Seu evento começa em 30 minutos',
      scheduledDate: tz.TZDateTime.from(reminderTime, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: event.id,
    );
  }

  /// Notificação de início do evento
  Future<void> _scheduleStartNotification(Event event) async {
    // Só agenda se for no futuro
    if (event.dataInicioPlanejada.isBefore(DateTime.now())) return;

    const androidDetails = AndroidNotificationDetails(
      'agenda_start',
      'Início de Eventos',
      channelDescription: 'Notificações quando eventos começam',
      importance: Importance.max,
      priority: Priority.max,
      icon: '@mipmap/ic_launcher',
      fullScreenIntent: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.zonedSchedule(
      id: _getStartNotificationId(event.id),
      title: '${event.tipo.icon} ${event.titulo}',
      body: 'Seu evento começou agora!',
      scheduledDate: tz.TZDateTime.from(event.dataInicioPlanejada, tz.local),
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: event.id,
    );
  }

  /// Cancela notificações de um evento
  Future<void> cancelEventNotifications(String eventId) async {
    if (!_initialized) await initialize();

    await _notifications.cancel(id: _getReminderNotificationId(eventId));
    await _notifications.cancel(id: _getStartNotificationId(eventId));
  }

  /// Cancela todas as notificações
  Future<void> cancelAllNotifications() async {
    if (!_initialized) await initialize();
    await _notifications.cancelAll();
  }

  /// ID único para notificação de lembrete
  int _getReminderNotificationId(String eventId) {
    return eventId.hashCode;
  }

  /// ID único para notificação de início
  int _getStartNotificationId(String eventId) {
    return eventId.hashCode + 1000000;
  }

  /// Mostra notificação imediata (debug/testes)
  Future<void> showImmediateNotification(Event event) async {
    if (!_initialized) await initialize();

    const androidDetails = AndroidNotificationDetails(
      'agenda_immediate',
      'Notificações Imediatas',
      channelDescription: 'Notificações de teste',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: '${event.tipo.icon} ${event.titulo}',
      body: 'Evento agendado para ${_formatDateTime(event.dataInicioPlanejada)}',
      notificationDetails: details,
      payload: event.id,
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')} '
        'às ${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }
}
