import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

void main() {
  test('artefatos Fase 7 governança existem', () {
    expect(
      File('docs/04_AUDITORIAS/FASE7_GOVERNANCE_NAVIGATION.md').existsSync(),
      isTrue,
    );
    expect(
      File('test/navigation/agenda_routes_fase7_test.dart').existsSync(),
      isTrue,
    );
  });

  test('AppRoutes expõe helpers agenda L2+', () {
    final source = File('lib/core/router/app_routes.dart').readAsStringSync();
    expect(source, contains('static String agendaDay'));
    expect(source, contains('static String agendaEvent'));
  });

  test('AppRoutes.parentFallbackRoute — pilha vazia', () {
    expect(
      AppRoutes.parentFallbackRoute('/carteira/cliente/abc'),
      AppRoutes.carteira,
    );
    expect(
      AppRoutes.parentFallbackRoute('/agenda/day?date=2026-01-01'),
      AppRoutes.agenda,
    );
    expect(
      AppRoutes.parentFallbackRoute('/consultoria/clientes/x/fazendas/y'),
      AppRoutes.clientDetail('x'),
    );
    expect(
      AppRoutes.parentFallbackRoute('/consultoria/relatorios/r1/edit'),
      AppRoutes.reportDetail('r1'),
    );
    expect(
      AppRoutes.parentFallbackRoute(AppRoutes.planosPagamento),
      AppRoutes.meuPlano,
    );
  });

  test('arch_check.sh contém REGRA-NAV-1', () {
    final source = File('tool/arch_check.sh').readAsStringSync();
    expect(source, contains('REGRA-NAV-1'));
    expect(source, contains('context\\.pop()'));
  });

  test('lib/ sem context.pop()/canPop() funcional', () {
    final violations = <String>[];
    for (final entity in Directory('lib').listSync(recursive: true)) {
      if (entity is! File || !entity.path.endsWith('.dart')) continue;
      if (entity.path.contains('smart_button.dart')) continue;
      final lines = entity.readAsLinesSync();
      for (var i = 0; i < lines.length; i++) {
        final line = lines[i].trimLeft();
        if (line.startsWith('//')) continue;
        if (line.contains('context.pop()') ||
            line.contains('context.canPop()')) {
          violations.add('${entity.path}:${i + 1}');
        }
      }
    }
    expect(violations, isEmpty, reason: violations.join('\n'));
  });
}
