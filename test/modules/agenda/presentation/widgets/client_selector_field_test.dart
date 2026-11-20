import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/modules/agenda/presentation/widgets/client_selector_field.dart';

class _FakeLookup implements IClientLookup {
  @override
  Future<List<ClientSummary>> listAtivos() async => _clientes;

  @override
  Future<ClientSummary?> findById(String id) async =>
      _clientes.where((c) => c.id == id).firstOrNull;
}

const _clientes = [
  ClientSummary(id: '1', name: 'Cláudio Gorgem', active: true, city: 'Sorriso'),
  ClientSummary(id: '2', name: 'Carlos lima', active: true),
  ClientSummary(id: '3', name: 'Paul Henke', active: true, city: 'Lucas'),
];

void main() {
  group('filtrarClientes', () {
    test('consulta vazia devolve todos', () {
      expect(filtrarClientes(_clientes, '  '), _clientes);
    });

    test('ignora acento e maiúscula', () {
      final r = filtrarClientes(_clientes, 'claudio');
      expect(r.map((c) => c.id), ['1']);
    });

    test('busca por parte do nome', () {
      expect(filtrarClientes(_clientes, 'LIM').map((c) => c.id), ['2']);
    });

    test('busca pela cidade', () {
      expect(filtrarClientes(_clientes, 'lucas').map((c) => c.id), ['3']);
    });

    test('sem correspondência devolve vazio', () {
      expect(filtrarClientes(_clientes, 'zzz'), isEmpty);
    });
  });

  group('ClientSelectorField', () {
    String? escolhido;
    final formKey = GlobalKey<FormState>();

    Future<void> montar(WidgetTester tester) async {
      escolhido = null;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [clientLookupProvider.overrideWithValue(_FakeLookup())],
          child: MaterialApp(
            home: Scaffold(
              body: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: formKey,
                  child: ClientSelectorField(onChanged: (id) => escolhido = id),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('digitar filtra e tocar na sugestão seleciona', (tester) async {
      await montar(tester);

      await tester.enterText(
        find.byKey(const Key('agenda_cliente_busca')),
        'paul',
      );
      await tester.pumpAndSettle();

      expect(find.text('Carlos lima'), findsNothing);
      await tester.tap(find.text('Paul Henke').last);
      await tester.pumpAndSettle();

      expect(escolhido, '3');
    });

    testWidgets('editar o texto depois de escolher desfaz a seleção', (
      tester,
    ) async {
      await montar(tester);
      final campo = find.byKey(const Key('agenda_cliente_busca'));

      await tester.enterText(campo, 'carlos');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Carlos lima').last);
      await tester.pumpAndSettle();
      expect(escolhido, '2');

      await tester.enterText(campo, 'carl');
      await tester.pumpAndSettle();
      expect(escolhido, isNull);
    });

    testWidgets('valida: sem escolha mostra erro', (tester) async {
      await montar(tester);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Busque e selecione um cliente'), findsOneWidget);
    });

    testWidgets('sem resultado avisa que não encontrou', (tester) async {
      await montar(tester);
      await tester.enterText(
        find.byKey(const Key('agenda_cliente_busca')),
        'zzz',
      );
      await tester.pumpAndSettle();
      expect(find.text('Nenhum cliente encontrado'), findsOneWidget);
    });

    testWidgets('funciona dentro de um AlertDialog (largura intrínseca)', (
      tester,
    ) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [clientLookupProvider.overrideWithValue(_FakeLookup())],
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () => showDialog<void>(
                    context: context,
                    builder: (_) => AlertDialog(
                      content: SingleChildScrollView(
                        child: ClientSelectorField(onChanged: (_) {}),
                      ),
                    ),
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

      await tester.enterText(
        find.byKey(const Key('agenda_cliente_busca')),
        'car',
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Carlos lima'), findsOneWidget);
    });
  });
}
