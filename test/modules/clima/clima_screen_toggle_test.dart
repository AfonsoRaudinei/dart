import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/clima/domain/entities/alerta_meteorologico.dart';
import 'package:soloforte_app/modules/clima/domain/entities/clima_atual.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_diaria.dart';
import 'package:soloforte_app/modules/clima/domain/entities/previsao_horaria.dart';
import 'package:soloforte_app/modules/clima/presentation/providers/clima_providers.dart';
import 'package:soloforte_app/modules/clima/presentation/screens/clima_screen.dart';
import 'package:soloforte_app/modules/clima/presentation/widgets/clima_current_widgets.dart';

void main() {
  group('ClimaPeriodToggle', () {
    testWidgets('muda climaTabIndexProvider entre 0, 1 e 2', (tester) async {
      late ProviderContainer container;

      await tester.pumpWidget(
        ProviderScope(
          child: Builder(
            builder: (context) {
              container = ProviderScope.containerOf(context);
              return const MaterialApp(
                home: Scaffold(body: ClimaPeriodToggle()),
              );
            },
          ),
        ),
      );

      expect(container.read(climaTabIndexProvider), 0);
      expect(find.text('Agora'), findsOneWidget);
      expect(find.text('24h'), findsOneWidget);
      expect(find.text('7 dias'), findsOneWidget);

      await tester.tap(find.text('24h'));
      await tester.pump();
      expect(container.read(climaTabIndexProvider), 1);

      await tester.tap(find.text('7 dias'));
      await tester.pump();
      expect(container.read(climaTabIndexProvider), 2);

      await tester.tap(find.text('Agora'));
      await tester.pump();
      expect(container.read(climaTabIndexProvider), 0);
    });
  });

  group('ClimaScreen — toggle persistente', () {
    testWidgets(
      'chrome Agora/24h/7 dias; Ver chuva some na 24h; sem header de volta',
      (tester) async {
        await tester.pumpWidget(
          ProviderScope(
            overrides: _climaScreenOverrides(),
            child: const MaterialApp(home: ClimaScreen()),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Agora'), findsWidgets);
        expect(find.text('24h'), findsOneWidget);
        expect(find.text('7 dias'), findsOneWidget);
        expect(find.text('Ver chuva no mapa'), findsOneWidget);
        expect(find.text('☔  Próximas 24h'), findsNothing);

        await tester.tap(find.text('24h'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Ver chuva no mapa'), findsNothing);
        expect(find.text('Próximas 24 Horas'), findsNothing);
        expect(find.byIcon(Icons.arrow_back_ios_new_rounded), findsNothing);
        expect(find.byIcon(Icons.arrow_back_ios), findsNothing);
        expect(find.text('Agora'), findsWidgets);
        expect(find.text('☔  Próximas 24h'), findsNothing);
      },
    );

    test('fonte usa toggle persistente sem chips nem subheader', () {
      final screen = File(
        'lib/modules/clima/presentation/screens/clima_screen.dart',
      ).readAsStringSync();
      final current = File(
        'lib/modules/clima/presentation/widgets/clima_current_widgets.dart',
      ).readAsStringSync();
      final combined = '$screen\n$current';

      expect(screen, contains('Agora'));
      expect(screen, contains('24h'));
      expect(screen, contains('7 dias'));
      expect(screen, isNot(contains('ClimaTabChips')));
      expect(screen, isNot(contains('ClimaSubViewHeader')));
      expect(combined, contains('ClimaPeriodToggle'));
      expect(combined, isNot(contains("☔  Próximas 24h")));
      expect(current, isNot(contains('class ClimaTabChips')));
      expect(current, isNot(contains('class _TabChip')));
    });
  });
}

List<Override> _climaScreenOverrides() {
  final now = DateTime(2026, 9, 24, 12);
  final clima = ClimaAtual(
    temperatura: 28,
    sensacaoTermica: 30,
    condicao: 'céu limpo',
    condicaoCodigo: '01d',
    ventoVelocidade: 12,
    ventoDirecao: 'NE',
    umidade: 55,
    precipitacao: 0,
    pressao: 1012,
    visibilidade: 10,
    coberturaNuvens: 5,
    indiceUV: 7,
    nascerSol: DateTime(2026, 9, 24, 6),
    porSol: DateTime(2026, 9, 24, 18),
    latitude: -10.18,
    longitude: -48.33,
    cidade: 'Palmas',
    atualizadoEm: now,
  );

  return [
    climaLocationProvider.overrideWith(
      (ref) async => (lat: -10.18, lon: -48.33),
    ),
    climaAtualProvider.overrideWith((ref) async => clima),
    alertasClimaProvider.overrideWith(
      (ref) async => const <AlertaMeteorologico>[],
    ),
    previsaoHorariaProvider.overrideWith(
      (ref) async => const <PrevisaoHoraria>[],
    ),
    previsaoSemanalProvider.overrideWith(
      (ref) async => const <PrevisaoDiaria>[],
    ),
  ];
}
