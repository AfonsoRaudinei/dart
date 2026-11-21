import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/ui/sheets/solo_forte_sheet_visuals.dart';
import 'package:soloforte_app/modules/drawing/domain/repositories/i_clients_repository.dart';
import 'package:soloforte_app/modules/drawing/presentation/widgets/drawing_hierarchy_search_field.dart';

const _clients = [
  Client(id: 'a', name: 'Cliente Alfa'),
  Client(id: 'b', name: 'Cliente Beta'),
];

const _farms = [
  Farm(id: 'f1', name: 'Fazenda Norte', city: '', state: ''),
  Farm(id: 'f2', name: 'Fazenda Sul', city: '', state: ''),
];

class _ClientHarness extends StatefulWidget {
  const _ClientHarness({
    required this.clients,
    this.selectedClient,
  });

  final List<Client> clients;
  final Client? selectedClient;

  @override
  State<_ClientHarness> createState() => _ClientHarnessState();
}

class _ClientHarnessState extends State<_ClientHarness> {
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
    return DrawingClientSearchField(
      visuals: v,
      clients: widget.clients,
      searchController: _searchController,
      query: _query,
      selectedClient: widget.selectedClient,
      onQueryChanged: (q) => setState(() => _query = q),
      onSelectClient: (_) {},
    );
  }
}

class _FarmHarness extends StatefulWidget {
  const _FarmHarness({
    required this.farms,
    this.selectedFarm,
  });

  final List<Farm> farms;
  final Farm? selectedFarm;

  @override
  State<_FarmHarness> createState() => _FarmHarnessState();
}

class _FarmHarnessState extends State<_FarmHarness> {
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
    return DrawingFarmSearchField(
      visuals: v,
      farms: widget.farms,
      searchController: _searchController,
      query: _query,
      selectedFarm: widget.selectedFarm,
      clientSelected: true,
      onQueryChanged: (q) => setState(() => _query = q),
      onSelectFarm: (_) {},
      onNewFarm: () {},
    );
  }
}

void main() {
  group('filterDrawingClients', () {
    test('consulta vazia devolve todos ordenados', () {
      final r = filterDrawingClients(_clients, '');
      expect(r.map((c) => c.name), ['Cliente Alfa', 'Cliente Beta']);
    });

    test('com texto filtra por nome', () {
      final r = filterDrawingClients(_clients, 'alfa');
      expect(r.map((c) => c.id), ['a']);
    });
  });

  group('filterDrawingFarms', () {
    test('ordena alfabeticamente ao filtrar', () {
      final r = filterDrawingFarms(_farms, '');
      expect(r.map((f) => f.name), ['Fazenda Norte', 'Fazenda Sul']);
    });
  });

  group('DrawingClientSearchField', () {
    Future<void> mountClient(
      WidgetTester tester, {
      Client? selectedClient,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: _ClientHarness(
                clients: _clients,
                selectedClient: selectedClient,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('busca vazia sem seleção não lista clientes', (tester) async {
      await mountClient(tester);

      expect(find.text('Digite para buscar…'), findsOneWidget);
      expect(find.text('Cliente Alfa'), findsNothing);
      expect(find.text('Cliente Beta'), findsNothing);
    });

    testWidgets('com cliente selecionado mostra só o tile escolhido',
        (tester) async {
      await mountClient(tester, selectedClient: _clients.first);

      expect(find.text('Cliente Alfa'), findsOneWidget);
      expect(find.text('Cliente Beta'), findsNothing);
      expect(find.text('Digite para buscar…'), findsNothing);
    });

    testWidgets('digitar na busca mostra lista filtrada', (tester) async {
      await mountClient(tester);

      await tester.enterText(find.byType(TextField), 'Beta');
      await tester.pumpAndSettle();

      expect(find.text('Cliente Beta'), findsOneWidget);
      expect(find.text('Cliente Alfa'), findsNothing);
    });
  });

  group('DrawingFarmSearchField', () {
    Future<void> mountFarm(
      WidgetTester tester, {
      Farm? selectedFarm,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: _FarmHarness(
                farms: _farms,
                selectedFarm: selectedFarm,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('com cliente ativo exibe Nova Fazenda com busca vazia',
        (tester) async {
      await mountFarm(tester);

      expect(find.text('Nova Fazenda'), findsOneWidget);
      expect(find.text('Fazenda Norte'), findsNothing);
    });

    testWidgets('digitar filtra fazendas mantendo Nova Fazenda', (tester) async {
      await mountFarm(tester);

      await tester.enterText(find.byType(TextField), 'Sul');
      await tester.pumpAndSettle();

      expect(find.text('Fazenda Sul'), findsOneWidget);
      expect(find.text('Fazenda Norte'), findsNothing);
      expect(find.text('Nova Fazenda'), findsOneWidget);
    });
  });
}