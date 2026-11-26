import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/enums/perfil_atendimento_tipo.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/perfil_atendimento_abordagem.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_perfil_destaque_card.dart';

Client _client({
  PerfilAtendimentoTipo? dominante,
  PerfilAtendimentoTipo? secundario,
  int? pragmatico,
  int? analitico,
  int? afavel,
  int? expressivo,
}) {
  return Client(
    id: 'c1',
    name: 'Ademir Rossato',
    phone: '',
    city: 'Rio Verde',
    state: 'GO',
    createdAt: DateTime(2026, 1, 1),
    perfilDominante: dominante,
    perfilSecundario: secundario,
    perfilPontosPragmatico: pragmatico,
    perfilPontosAnalitico: analitico,
    perfilPontosAfavel: afavel,
    perfilPontosExpressivo: expressivo,
  );
}

void main() {
  late int rediagnosticar;
  late int abordagem;

  setUp(() {
    rediagnosticar = 0;
    abordagem = 0;
  });

  Future<void> pumpCard(WidgetTester tester, Client client) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: ClientPerfilDestaqueCard(
              client: client,
              onRediagnosticar: () => rediagnosticar++,
              onAbrirAbordagem: () => abordagem++,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('sem diagnóstico: convida e toque inicia o questionário', (
    tester,
  ) async {
    await pumpCard(tester, _client());

    expect(find.text('Iniciar diagnóstico · 7 perguntas'), findsOneWidget);
    expect(
      find.textContaining('Descubra como este cliente prefere decidir'),
      findsOneWidget,
    );
    expect(find.text('Ver como vender'), findsNothing);

    await tester.tap(find.text('Perfil de atendimento'));
    await tester.pump();
    expect(rediagnosticar, 1);

    await tester.tap(find.text('Iniciar diagnóstico · 7 perguntas'));
    await tester.pump();
    expect(rediagnosticar, 2);
    expect(abordagem, 0);
  });

  testWidgets(
    'diagnosticado: card abre o guia e Refazer só reabre o questionário',
    (tester) async {
      await pumpCard(
        tester,
        _client(
          dominante: PerfilAtendimentoTipo.pragmatico,
          secundario: PerfilAtendimentoTipo.analitico,
          pragmatico: 3,
          analitico: 2,
          afavel: 1,
          expressivo: 1,
        ),
      );

      expect(find.text('Pragmático'), findsOneWidget);
      expect(find.text('Traço Analítico'), findsOneWidget);
      expect(
        find.text(abordagemDe(PerfilAtendimentoTipo.pragmatico).abordagemIdeal),
        findsOneWidget,
      );
      expect(find.text('Ver como vender'), findsOneWidget);
      expect(
        find.byKey(ClientPerfilDestaqueCard.distribuicaoKey),
        findsOneWidget,
      );
      expect(
        find.text('Pragmático 3 · Analítico 2 · Afável 1 · Expressivo 1'),
        findsOneWidget,
      );

      await tester.tap(find.text('Ver como vender'));
      await tester.pump();
      expect(abordagem, 1);
      expect(rediagnosticar, 0);

      await tester.tap(find.text('Refazer'));
      await tester.pump();
      expect(rediagnosticar, 1);
      expect(abordagem, 1);
    },
  );

  testWidgets('320dp com padding do detalhe não estoura em texto ampliado', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(960, 2400);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    final clientes = [
      _client(
        dominante: PerfilAtendimentoTipo.pragmatico,
        secundario: PerfilAtendimentoTipo.analitico,
        pragmatico: 3,
        analitico: 2,
        afavel: 1,
        expressivo: 1,
      ),
      _client(),
    ];

    for (final escala in [1.0, 1.3, 2.0]) {
      for (final client in clientes) {
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(escala)),
              child: child!,
            ),
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: ClientPerfilDestaqueCard(
                    client: client,
                    onRediagnosticar: () => rediagnosticar++,
                    onAbrirAbordagem: () => abordagem++,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull, reason: 'escala $escala');
        if (client.perfilDominante != null) {
          expect(find.text('Ver como vender'), findsOneWidget);
        } else {
          expect(
            find.text('Iniciar diagnóstico · 7 perguntas'),
            findsOneWidget,
          );
        }
      }
    }
  });

  testWidgets('diagnosticado sem pontos: não mostra a distribuição', (
    tester,
  ) async {
    await pumpCard(tester, _client(dominante: PerfilAtendimentoTipo.afavel));

    expect(tester.takeException(), isNull);
    expect(find.text('Afável'), findsOneWidget);
    expect(find.textContaining('Traço'), findsNothing);
    expect(find.byKey(ClientPerfilDestaqueCard.distribuicaoKey), findsNothing);
    expect(find.text('Ver como vender'), findsOneWidget);
  });
}
