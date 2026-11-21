import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_visit_client_lookup.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/modules/map/presentation/widgets/visit_sheet_inline_picker.dart';

const _clients = [
  VisitClientSummary(id: 'a', name: 'Produtor Alfa'),
  VisitClientSummary(id: 'b', name: 'Produtor Beta'),
];

class _PickerHarness extends StatefulWidget {
  const _PickerHarness({
    required this.clients,
    this.selectedClientId,
    this.clientsAsync,
    this.onRetry,
    this.onClearClient,
  });

  final List<VisitClientSummary> clients;
  final String? selectedClientId;
  final AsyncValue<List<VisitClientSummary>>? clientsAsync;
  final VoidCallback? onRetry;
  final VoidCallback? onClearClient;

  @override
  State<_PickerHarness> createState() => _PickerHarnessState();
}

class _PickerHarnessState extends State<_PickerHarness> {
  late final TextEditingController _searchController;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedId = widget.selectedClientId;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final v = SoloForteSheetVisuals.of(context);
    return VisitSheetProdutorPicker(
      visuals: v,
      clientsAsync: widget.clientsAsync ?? AsyncValue.data(widget.clients),
      searchController: _searchController,
      selectedClientId: _selectedId,
      onSelectClient: (client) => setState(() => _selectedId = client.id),
      onClearClient: () {
        setState(() => _selectedId = null);
        widget.onClearClient?.call();
      },
      onRetry: widget.onRetry ?? () {},
    );
  }
}

void main() {
  group('filterVisitClients', () {
    test('consulta vazia devolve todos ordenados', () {
      final r = filterVisitClients(_clients, '');
      expect(r.map((c) => c.name), ['Produtor Alfa', 'Produtor Beta']);
    });

    test('com texto filtra por nome', () {
      final r = filterVisitClients(_clients, 'alfa');
      expect(r.map((c) => c.id), ['a']);
    });

    test('ignora acento', () {
      final r = filterVisitClients(const [
        VisitClientSummary(id: 'j', name: 'José'),
        VisitClientSummary(id: 'a', name: 'João'),
      ], 'jose');
      expect(r.map((c) => c.id), ['j']);
    });

    test('acha com as palavras fora de ordem', () {
      final r = filterVisitClients(const [
        VisitClientSummary(id: 'p', name: 'Adriel Pasqualli'),
        VisitClientSummary(id: 'a', name: 'Produtor Alfa'),
      ], 'pasqualli adriel');
      expect(r.map((c) => c.id), ['p']);
    });

    test('nome em branco não entra', () {
      final r = filterVisitClients(const [
        VisitClientSummary(id: 'v', name: '   '),
        VisitClientSummary(id: 'a', name: 'Produtor Alfa'),
      ], '');
      expect(r.map((c) => c.id), ['a']);
    });
  });

  group('VisitSheetProdutorPicker', () {
    Future<void> mount(
      WidgetTester tester, {
      String? selectedClientId,
      AsyncValue<List<VisitClientSummary>>? clientsAsync,
      VoidCallback? onRetry,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: _PickerHarness(
                clients: _clients,
                selectedClientId: selectedClientId,
                clientsAsync: clientsAsync,
                onRetry: onRetry,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('busca vazia sem seleção não lista produtores', (tester) async {
      await mount(tester);

      expect(find.text('Digite para buscar o produtor'), findsOneWidget);
      expect(find.text('Produtor Alfa'), findsNothing);
      expect(find.text('Produtor Beta'), findsNothing);
    });

    testWidgets('digitar na busca mostra o autocomplete filtrado', (
      tester,
    ) async {
      await mount(tester);

      await tester.enterText(find.byType(TextField), 'Beta');
      await tester.pumpAndSettle();

      expect(find.text('Produtor Beta'), findsOneWidget);
      expect(find.text('Produtor Alfa'), findsNothing);
      expect(find.text('Digite para buscar o produtor'), findsNothing);
    });

    testWidgets('busca sem match avisa sem tile de nome', (tester) async {
      await mount(tester);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pumpAndSettle();

      expect(find.text('Nenhum produtor para esta busca'), findsOneWidget);
      expect(find.text('Produtor Alfa'), findsNothing);
      expect(find.text('Produtor Beta'), findsNothing);
    });

    testWidgets('foco no nome escolhido não reabre a lista', (tester) async {
      await mount(tester);

      await tester.enterText(find.byType(TextField), 'Beta');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Produtor Beta'));
      await tester.pumpAndSettle();
      await tester.tap(find.byType(TextField));
      await tester.pumpAndSettle();

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, 'Produtor Beta');
      expect(find.text('Produtor Beta'), findsOneWidget);
      expect(find.text('Produtor Alfa'), findsNothing);
    });

    testWidgets('produtor selecionado fica dentro do campo', (tester) async {
      await mount(tester, selectedClientId: 'a');

      final field = tester.widget<TextField>(find.byType(TextField));
      expect(field.controller?.text, 'Produtor Alfa');
      expect(find.text('Produtor Alfa'), findsOneWidget);
      expect(find.text('Produtor Beta'), findsNothing);
      expect(find.text('Digite para buscar o produtor'), findsNothing);
    });

    testWidgets('erro de carga não parece lista vazia', (tester) async {
      var retries = 0;
      await mount(
        tester,
        clientsAsync: AsyncValue<List<VisitClientSummary>>.error(
          Exception('falha'),
          StackTrace.empty,
        ),
        onRetry: () => retries++,
      );

      expect(
        find.text('Não foi possível carregar os produtores.'),
        findsOneWidget,
      );
      expect(find.text('Tentar de novo'), findsOneWidget);
      expect(find.text('Nenhum produtor encontrado'), findsNothing);

      await tester.tap(find.text('Tentar de novo'));
      await tester.pump();
      expect(retries, 1);
    });
  });
}
