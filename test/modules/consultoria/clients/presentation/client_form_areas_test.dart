import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/consultoria/clients/domain/client.dart';
import 'package:soloforte_app/modules/consultoria/clients/presentation/widgets/client_edit_form.dart';
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
