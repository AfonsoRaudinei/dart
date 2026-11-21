import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/ui/sheets/sheet_client_search_field.dart';

const _clientes = [
  ClientSummary(id: '1', name: 'Cláudio Gorgem', active: true, city: 'Sorriso'),
  ClientSummary(id: '2', name: 'Paul Henke', active: true),
  ClientSummary(id: '3', name: 'Ulisses Igor', active: true),
];

void main() {
  test('filterClientsByQuery ignora acento e caixa e busca na cidade', () {
    expect(filterClientsByQuery(_clientes, 'claudio').map((c) => c.id), ['1']);
    expect(filterClientsByQuery(_clientes, 'SORR').map((c) => c.id), ['1']);
    expect(filterClientsByQuery(_clientes, '  '), _clientes);
    expect(filterClientsByQuery(_clientes, 'xyz'), isEmpty);
  });

  testWidgets('digitar filtra, tocar seleciona e editar limpa', (tester) async {
    ClientSummary? escolhido;
    String? id;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => SheetClientSearchField(
              clients: _clientes,
              selectedClientId: id,
              onChanged: (c) => setState(() {
                escolhido = c;
                id = c?.id;
              }),
            ),
          ),
        ),
      ),
    );

    await tester.enterText(find.byKey(const Key('sheet_client_search')), 'ul');
    await tester.pumpAndSettle();
    expect(find.text('Paul Henke'), findsOneWidget);
    expect(find.text('Ulisses Igor'), findsOneWidget);
    expect(find.text('Cláudio Gorgem'), findsNothing);

    await tester.tap(find.text('Ulisses Igor'));
    await tester.pumpAndSettle();
    expect(escolhido?.id, '3');

    await tester.enterText(
      find.byKey(const Key('sheet_client_search')),
      'Ulis',
    );
    await tester.pumpAndSettle();
    expect(escolhido, isNull);
  });

  testWidgets('sem resultado mostra aviso e dentro de AlertDialog não quebra', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (_) => AlertDialog(
                  content: SheetClientSearchField(
                    clients: _clientes,
                    selectedClientId: null,
                    onChanged: (_) {},
                  ),
                ),
              ),
              child: const Text('abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const Key('sheet_client_search')), 'zzz');
    await tester.pumpAndSettle();
    expect(find.text('Nenhum cliente encontrado'), findsOneWidget);
  });
}
