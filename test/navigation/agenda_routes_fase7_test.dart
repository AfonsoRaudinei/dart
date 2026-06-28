import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

void main() {
  group('AppRoutes agenda helpers (Fase 7)', () {
    test('agendaDay inclui ISO8601 na query', () {
      final date = DateTime(2026, 6, 15, 10, 30);
      expect(
        AppRoutes.agendaDay(date),
        '${AppRoutes.agenda}/day?date=${date.toIso8601String()}',
      );
    });

    test('agendaEvent monta path canônico', () {
      expect(AppRoutes.agendaEvent('evt-1'), '${AppRoutes.agenda}/event/evt-1');
    });

    test('sub-rotas agenda classificadas como L2+', () {
      expect(
        AppRoutes.getLevel(AppRoutes.agendaDay(DateTime(2026, 1, 1))),
        RouteLevel.l2Plus,
      );
      expect(
        AppRoutes.getLevel(AppRoutes.agendaEvent('abc')),
        RouteLevel.l2Plus,
      );
      expect(AppRoutes.getLevel(AppRoutes.agenda), RouteLevel.l1);
    });
  });
}
