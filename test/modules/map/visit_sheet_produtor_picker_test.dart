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
  });

  final List<VisitClientSummary> clients;
  final String? selectedClientId;

  @override
  State<_PickerHarness> createState() => _PickerHarnessState();
}

class _PickerHarnessState extends State<_PickerHarness> {
  late final TextEditingController _searchController;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
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
      clientsAsync: AsyncValue.data(widget.clients),
      searchController: _searchController,
      clientQuery: _query,
      selectedClientId: widget.selectedClientId,
      onQueryChanged: (q) => setState(() => _query = q),
      onSelectClient: (_) {},
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
  });

  group('VisitSheetProdutorPicker', () {
    Future<void> mount(
      WidgetTester tester, {
      String? selectedClientId,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: _PickerHarness(
                clients: _clients,
                selectedClientId: selectedClientId,
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

    testWidgets('com produtor selecionado mostra só o tile escolhido', (tester) async {
      await mount(tester, selectedClientId: 'a');

      expect(find.text('Produtor Alfa'), findsOneWidget);
      expect(find.text('Produtor Beta'), findsNothing);
      expect(find.text('Digite para buscar o produtor'), findsNothing);
    });

    testWidgets('digitar na busca mostra lista filtrada', (tester) async {
      await mount(tester);

      await tester.enterText(find.byType(TextField), 'Beta');
      await tester.pumpAndSettle();

      expect(find.text('Produtor Beta'), findsOneWidget);
      expect(find.text('Produtor Alfa'), findsNothing);
      expect(find.text('Digite para buscar o produtor'), findsNothing);
    });
  });
}