import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

// ════════════════════════════════════════════════════════════════════
// TESTE 1 — Gate ADR-007: Snapshot de Nível (Map-First / L0-only)
//
// O que garante:
//   - Qualquer path sob /map (incluindo /map/publicacao/edit) é L0.
//   - Falha se alguém mover a rota para L1/L2 ou alterar a política.
//   - CI bloqueia merge se getLevel() mudar.
// ════════════════════════════════════════════════════════════════════

void main() {
  group('ADR-007 | Map-First level classification', () {
    test('"/map" and subpaths are always L0', () {
      expect(AppRoutes.getLevel('/map'), RouteLevel.l0);
      expect(AppRoutes.getLevel('/map/publicacao/edit'), RouteLevel.l0);
      // Query params não alteram classificação — getLevel opera no path
      expect(AppRoutes.getLevel('/map/publicacao/edit?id=123'), RouteLevel.l0);
    });

    test('No Publicacao path resolves to L1 or L2+', () {
      final samples = <String>[
        '/map/publicacao/edit',
        '/map/publicacao/edit?id=abc',
        '/map/publicacao',
      ];

      for (final p in samples) {
        expect(
          AppRoutes.getLevel(p),
          isNot(RouteLevel.l1),
          reason: '"$p" não deve ser L1',
        );
        expect(
          AppRoutes.getLevel(p),
          isNot(RouteLevel.l2Plus),
          reason: '"$p" não deve ser L2+',
        );
      }
    });

    test('Hypothetical /publicacao outside /map would NOT be L0', () {
      // Guard: se alguém criar rota /publicacao fora do /map,
      // o getLevel() NÃO a classifica como L0.
      expect(AppRoutes.getLevel('/publicacao'), isNot(RouteLevel.l0));
      expect(AppRoutes.getLevel('/publicacao/edit'), isNot(RouteLevel.l0));
    });

    test('Map-First contract: /map is always L0, never public/l1/l2+', () {
      expect(AppRoutes.getLevel('/map'), RouteLevel.l0);
      expect(AppRoutes.getLevel('/map'), isNot(RouteLevel.public));
      expect(AppRoutes.getLevel('/map'), isNot(RouteLevel.l1));
      expect(AppRoutes.getLevel('/map'), isNot(RouteLevel.l2Plus));
    });

    test('Future subpaths under /map/ remain L0 (expansion guard)', () {
      // Qualquer sub-rota futura sob /map/ deve ser L0
      expect(AppRoutes.getLevel('/map/qualquer-coisa'), RouteLevel.l0);
      expect(AppRoutes.getLevel('/map/nova-feature/sub'), RouteLevel.l0);
    });
  });
}
