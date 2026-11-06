import 'package:soloforte_app/core/services/notification_service.dart';

import '../domain/visit_route_notification.dart';

/// Porta da notificação da próxima parada. Testes injetam um fake.
///
/// `show*` retornam `false` quando o aviso não foi publicado (sem permissão).
abstract class VisitRouteNotificationPort {
  Future<bool> ensurePermission();

  Future<bool> showNextStop({
    required int index,
    required int total,
    required String payload,
  });

  Future<bool> showRouteCompleted({required int total});
}

class NotificationServiceVisitRoutePort implements VisitRouteNotificationPort {
  NotificationServiceVisitRoutePort([NotificationService? service])
    : _service = service ?? NotificationService();

  final NotificationService _service;

  @override
  Future<bool> ensurePermission() => _service.ensureNotificationPermission();

  @override
  Future<bool> showNextStop({
    required int index,
    required int total,
    required String payload,
  }) {
    return _service.showVisitRouteNotification(
      id: visitRouteNextStopNotificationId(index),
      title: 'Próxima parada',
      body: 'Parada $index de $total. Toque para abrir o mapa.',
      payload: payload,
    );
  }

  @override
  Future<bool> showRouteCompleted({required int total}) {
    return _service.showVisitRouteNotification(
      id: visitRouteCompletedNotificationId,
      title: 'Rota concluída',
      body: 'Todas as $total paradas desta visita foram registradas.',
    );
  }
}
