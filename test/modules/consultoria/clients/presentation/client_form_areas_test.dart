import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client_cultura.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_edit_form.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/cultura_item_widget.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/screens/client_form_screen.dart';

void main() {
  Future<void> adicionarArea(
    WidgetTester tester, {
    required String tamanho,
    required String tipo,
  }) async {
    final adicionar = find.widgetWithText(TextButton, 'Adicionar Área');
    await tester.ensureVisible(adicionar);
    await tester.tap(adicionar);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Tamanho da área (ha) *'),
      tamanho,
    );
    await tester.tap(find.text('Tipo da área *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(tipo).last);
    tester.testTextInput.hide();
    await tester.pumpAndSettle();
    final confirmar = find.widgetWithText(ElevatedButton, 'Adicionar');
    await tester.ensureVisible(confirmar);
    await tester.tap(confirmar);
    await tester.pumpAndSettle();
  }

  testWidgets('soma áreas e exibe percentuais por tipo', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ClientFormScreen())),
    );

    await adicionarArea(tester, tamanho: '75', tipo: 'Própria');
    await adicionarArea(tester, tamanho: '25', tipo: 'Arrendada');

    expect(find.text('Área cultivada total: 100 ha'), findsOneWidget);
    expect(find.text('Própria: 75.0%'), findsOneWidget);
    expect(find.text('Arrendada: 25.0%'), findsOneWidget);
  });

  testWidgets('exibe somente um sinal de adicionar cultura', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ClientFormScreen())),
    );

    expect(find.text('Adicionar Cultura'), findsOneWidget);
    expect(find.text('+ Adicionar Cultura'), findsNothing);
  });

  testWidgets('edicao lista culturas vazias e orienta talhão (sem botão +)', (
    tester,
  ) async {
    final client = Client(
      id: 'client-edit-cultura',
      name: 'Cliente Cultura',
      phone: '63999999999',
      city: 'Pugmil',
      state: 'TO',
      createdAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientEditForm(
            client: client,
            culturas: const [],
            onCancel: () {},
            onSave: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma cultura'), findsOneWidget);
    expect(
      find.text('Cultura e material são definidos em cada talhão.'),
      findsOneWidget,
    );
    expect(find.text('Adicionar Cultura'), findsNothing);
    expect(find.text('+ Adicionar Cultura'), findsNothing);
  });

  test('parse, join e format de multi-variedade', () {
    expect(ClientCultura.parseVariedades(null), isEmpty);
    expect(
      ClientCultura.parseVariedades('BRS 284, M 6410'),
      ['BRS 284', 'M 6410'],
    );
    expect(
      ClientCultura.joinVariedades(['BRS 284', 'M 6410']),
      'BRS 284, M 6410',
    );
    expect(
      ClientCultura.formatVariedades('BRS 284, M 6410'),
      'BRS 284 • M 6410',
    );
  });

  Future<void> preencherSheetCultura(
    WidgetTester tester, {
    required String area,
    String? variedadeText,
    bool tapAddVariedade = false,
  }) async {
    await tester.tap(find.text('Cultura *'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Soja').last);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, 'Área (ha) *'),
      area,
    );

    if (variedadeText != null) {
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Variedades / Cultivares'),
        variedadeText,
      );
      if (tapAddVariedade) {
        await tester.tap(find.byTooltip('Adicionar variedade'));
        await tester.pumpAndSettle();
      }
    }
  }

  testWidgets('flush variedade pendente ao confirmar sem +', (tester) async {
    ClientCultura? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                saved = await showAddCulturaSheet(
                  context: context,
                  clientId: 'client-1',
                  inputDecoration: (label) => InputDecoration(labelText: label),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await preencherSheetCultura(tester, area: '50', variedadeText: 'BRS 284');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(saved?.variedade, 'BRS 284');
  });

  testWidgets('flush aceita multiplas variedades com virgula sem +', (
    tester,
  ) async {
    ClientCultura? saved;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                saved = await showAddCulturaSheet(
                  context: context,
                  clientId: 'client-1',
                  inputDecoration: (label) => InputDecoration(labelText: label),
                );
              },
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await preencherSheetCultura(
      tester,
      area: '50',
      variedadeText: 'BRS 284, M 6410',
    );
    await tester.tap(find.widgetWithText(ElevatedButton, 'Confirmar'));
    await tester.pumpAndSettle();

    expect(saved?.variedade, 'BRS 284, M 6410');
  });

  testWidgets('cultura item exibe multiplas variedades legiveis', (
    tester,
  ) async {
    final cultura = ClientCultura(
      id: 'cult-1',
      clientId: 'client-1',
      cultura: 'soja',
      areaHa: 120,
      variedade: 'BRS 284, M 6410',
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CulturaItemWidget(cultura: cultura),
        ),
      ),
    );

    expect(find.text('BRS 284 • M 6410'), findsOneWidget);
  });

  testWidgets('edicao reaproveita area simples salva e mostra percentual', (
    tester,
  ) async {
    final client = Client(
      id: 'client-1',
      name: 'Cliente Teste',
      phone: '63999999999',
      city: 'Pugmil',
      state: 'TO',
      createdAt: DateTime(2026),
      areaTotal: 150,
      tipoPropriedade: 'propria',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientEditForm(
            client: client,
            culturas: const [],
            onCancel: () {},
            onSave: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Área cultivada total: 150 ha'), findsOneWidget);
    expect(find.text('Própria: 100.0%'), findsOneWidget);
    expect(find.text('Arrendada: 0.0%'), findsOneWidget);
    expect(find.text('Adicionar Área'), findsWidgets);
  });

  testWidgets('edicao mostra aviso legado para area mista sem detalhamento', (
    tester,
  ) async {
    final client = Client(
      id: 'client-2',
      name: 'Cliente Legado',
      phone: '63999999999',
      city: 'Pugmil',
      state: 'TO',
      createdAt: DateTime(2026),
      areaTotal: 150,
      tipoPropriedade: 'mista',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ClientEditForm(
            client: client,
            culturas: const [],
            onCancel: () {},
            onSave: (_, __) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Área total registrada: 150 ha'), findsOneWidget);
    expect(
      find.textContaining('Detalhe própria/arrendada ainda não foi preenchido'),
      findsOneWidget,
    );
  });
}
