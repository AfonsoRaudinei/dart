import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/enums/perfil_atendimento_tipo.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/providers/clients_providers.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_perfil_diagnostico_sheet.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_sheet_widgets.dart';

class _FakeClientsController extends ClientsController {
  _FakeClientsController(super.ref);

  List<PerfilAtendimentoTipo>? salvas;

  @override
  Future<void> savePerfilDiagnostico({
    required String clientId,
    required List<PerfilAtendimentoTipo> respostas,
  }) async {
    salvas = respostas;
  }
}

void main() {
  late _FakeClientsController controller;

  Future<void> abrirSheet(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientsControllerProvider.overrideWith((ref) {
            controller = _FakeClientsController(ref);
            return controller;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => showClientPerfilDiagnosticoSheet(
                  context: context,
                  clientId: 'client-1',
                  clientName: 'Ademir Rossato',
                ),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
  }

  Future<void> responder(WidgetTester tester, String opcao) async {
    await tester.ensureVisible(find.text(opcao));
    await tester.tap(find.text(opcao));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
  }

  int radiosMarcados(WidgetTester tester) => tester
      .widgetList<ClientSheetIosRadio>(find.byType(ClientSheetIosRadio))
      .where((r) => r.selected)
      .length;

  testWidgets('esconde o tipo de perfil durante o questionário', (
    tester,
  ) async {
    await abrirSheet(tester);

    expect(find.text('Pergunta 1 de 7'), findsOneWidget);
    expect(find.text('Falar da visão e oportunidades'), findsOneWidget);
    for (final tipo in PerfilAtendimentoTipo.values) {
      expect(find.text(tipo.labelDisplay), findsNothing);
    }
    expect(find.text('Voltar'), findsNothing);
  });

  testWidgets('marca a opção, aguarda a pausa e ignora toque duplo', (
    tester,
  ) async {
    await abrirSheet(tester);

    await tester.tap(find.text('Ir direto ao custo-benefício'));
    await tester.pump();
    expect(radiosMarcados(tester), 1);
    expect(find.text('Pergunta 1 de 7'), findsOneWidget);

    await tester.tap(find.text('Pedir dados e referências'));
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(find.text('Pergunta 2 de 7'), findsOneWidget);
    expect(radiosMarcados(tester), 0);

    await tester.tap(find.text('Voltar'));
    await tester.pumpAndSettle();

    expect(find.text('Pergunta 1 de 7'), findsOneWidget);
    final marcado = tester
        .widgetList<ClientSheetIosRadio>(find.byType(ClientSheetIosRadio))
        .toList();
    expect(marcado.first.selected, isTrue);
    expect(radiosMarcados(tester), 1);
  });

  testWidgets('mostra resultado no final e salva as respostas', (tester) async {
    await abrirSheet(tester);

    await responder(tester, 'Ir direto ao custo-benefício');
    await responder(tester, 'Projeções detalhadas');
    await responder(tester, 'Ação imediata');
    await responder(tester, 'Evidências técnicas');
    await responder(tester, 'Cortar excessos e decidir');
    await responder(tester, 'Quer alinhar com o time');
    await responder(tester, 'Entusiasmado');

    expect(find.text('Perfil de atendimento'), findsOneWidget);
    expect(find.text('Traço Analítico'), findsOneWidget);
    expect(find.text('Confirmar diagnóstico'), findsOneWidget);

    await tester.ensureVisible(find.text('Confirmar diagnóstico'));
    await tester.tap(find.text('Confirmar diagnóstico'));
    await tester.pumpAndSettle();

    expect(controller.salvas, const [
      PerfilAtendimentoTipo.pragmatico,
      PerfilAtendimentoTipo.analitico,
      PerfilAtendimentoTipo.pragmatico,
      PerfilAtendimentoTipo.analitico,
      PerfilAtendimentoTipo.pragmatico,
      PerfilAtendimentoTipo.afavel,
      PerfilAtendimentoTipo.expressivo,
    ]);
    expect(find.text('Confirmar diagnóstico'), findsNothing);
  });

  testWidgets('Refazer limpa as respostas e volta à primeira pergunta', (
    tester,
  ) async {
    await abrirSheet(tester);

    for (final opcao in const [
      'Pedir dados e referências',
      'Projeções detalhadas',
      'Análise de causa',
      'Evidências técnicas',
      'Questionar números',
      'Quer comparar estudos',
      'Preciso e documentado',
    ]) {
      await responder(tester, opcao);
    }

    expect(find.text('Traço Analítico'), findsNothing);

    await tester.ensureVisible(find.text('Refazer'));
    await tester.tap(find.text('Refazer'));
    await tester.pumpAndSettle();

    expect(find.text('Pergunta 1 de 7'), findsOneWidget);
    expect(radiosMarcados(tester), 0);
    expect(find.text('Ver resultado'), findsNothing);
  });
}
