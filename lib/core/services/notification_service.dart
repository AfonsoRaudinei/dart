import 'dart:io';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;
  NotificationService._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  void Function(String? payload)? _onNotificationResponse;
  String? _pendingPayload;

  bool get isInitialized => _initialized;

  /// Toque na notificação. Payload vazio não navega.
  ///
  /// Se o toque chegar antes do app registrar o handler (cold start),
  /// o payload fica pendente e dispara na atribuição.
  set onNotificationResponse(void Function(String? payload)? handler) {
    _onNotificationResponse = handler;
    final pending = _pendingPayload;
    if (handler != null && pending != null) {
      _pendingPayload = null;
      handler(pending);
    }
  }

  Future<void> init() async {
    if (_initialized) return;

    if (Platform.isAndroid) {
      await Permission.notification.request();
    }

    const androidSettings = AndroidInitializationSettings('launcher_icon');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (details) {
        _dispatchNotificationPayload(details.payload);
      },
    );

    final launch = await _localNotifications.getNotificationAppLaunchDetails();
    if (launch?.didNotificationLaunchApp == true) {
      _dispatchNotificationPayload(launch?.notificationResponse?.payload);
    }

    _initialized = true;
  }

  void _dispatchNotificationPayload(String? payload) {
    if (payload == null || payload.trim().isEmpty) return;
    final handler = _onNotificationResponse;
    if (handler == null) {
      _pendingPayload = payload;
      return;
    }
    handler(payload);
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await init();
    }

    const androidDetails = AndroidNotificationDetails(
      'geofence_channel',
      'Geofence Notifications',
      channelDescription: 'Notifications for arrival and departure suggestions',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  /// Aviso da rota sugerida. Fica na bandeja depois que a tela bloqueia.
  ///
  /// Fase 1 (ADR-057): a notificação é publicada com o app ainda aberto,
  /// no momento em que a parada é concluída. Não usa localização em
  /// background.
  Future<void> showVisitRouteNotification({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) {
      await init();
    }

    const androidDetails = AndroidNotificationDetails(
      'visit_route_channel',
      'Rota sugerida',
      channelDescription: 'Avisos da próxima parada da visita',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBanner: true,
      presentList: true,
      presentSound: true,
    );
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}
