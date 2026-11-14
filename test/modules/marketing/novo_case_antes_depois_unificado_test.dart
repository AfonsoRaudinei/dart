import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup.dart';
import 'package:soloforte_app/core/contracts/i_client_lookup_provider.dart';
import 'package:soloforte_app/modules/marketing/domain/entities/marketing_case.dart';
import 'package:soloforte_app/modules/marketing/domain/enums/case_tipo.dart';
import 'package:soloforte_app/modules/marketing/presentation/screens/novo_case_sheet.dart';
import 'package:soloforte_app/modules/marketing/presentation/widgets/foto_picker_widget.dart';

void main() {
  testWidgets('Antes/Depois unificado: adicionar e remover comparação extra', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientLookupProvider.overrideWithValue(_FakeClientLookup()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NovoCaseSheet(
              lat: -10.0,
              lng: -48.0,
              tipo: CaseTipo.antesDepois,
              onClose: () {},
              onPublicar: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Comparação 1'), findsOneWidget);
    expect(find.text('Adicionar comparação'), findsOneWidget);
    expect(find.text('Adicionar Avaliação'), findsNothing);

    await tester.ensureVisible(find.text('Adicionar comparação'));
    await tester.tap(find.text('Adicionar comparação'));
    await tester.pumpAndSettle();
    expect(find.text('Comparação 2'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();
    expect(find.text('Comparação 2'), findsNothing);
    expect(find.text('Comparação 1'), findsOneWidget);
  });

  testWidgets('CaseTipo.avaliacao abre fluxo Antes/Depois unificado', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientLookupProvider.overrideWithValue(_FakeClientLookup()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NovoCaseSheet(
              lat: -10.0,
              lng: -48.0,
              tipo: CaseTipo.avaliacao,
              onClose: () {},
              onPublicar: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Nome do Talhão (opcional)'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(find.text('Nome do Talhão (opcional)'), findsOneWidget);
    expect(find.text('Adicionar comparação'), findsOneWidget);
  });

  testWidgets('Comparação: rótulo editável, até 3 fotos e pelo menos uma', (
    tester,
  ) async {
    MarketingCase? publicado;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          clientLookupProvider.overrideWithValue(_FakeClientLookup()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NovoCaseSheet(
              lat: -10.0,
              lng: -48.0,
              tipo: CaseTipo.antesDepois,
              onClose: () {},
              onPublicar: (caso) => publicado = caso,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FotoPickerWidget), findsNWidgets(2));
    final pickers = tester.widgetList<FotoPickerWidget>(
      find.byType(FotoPickerWidget),
    );
    expect(pickers.every((picker) => picker.required == false), isTrue);

    final antes = _rotuloComTexto('Antes');
    final depois = _rotuloComTexto('Depois');
    await tester.scrollUntilVisible(
      antes,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(antes, findsOneWidget);
    expect(depois, findsOneWidget);
    expect(find.text('Texto'), findsOneWidget);
    expect(find.byTooltip('Remover foto'), findsNWidgets(2));

    await tester.enterText(antes, 'Concorrente');
    await tester.pumpAndSettle();
    expect(_rotuloComTexto('Concorrente'), findsOneWidget);
    expect(_rotuloComTexto('Antes'), findsNothing);

    await tester.ensureVisible(find.text('Adicionar foto'));
    await tester.tap(find.text('Adicionar foto'));
    await tester.pumpAndSettle();
    expect(_rotuloComTexto('Concorrente'), findsOneWidget);
    expect(find.byType(FotoPickerWidget), findsNWidgets(3));
    expect(find.text('Adicionar foto'), findsNothing);
    expect(find.byTooltip('Remover foto'), findsNWidgets(3));

    await tester.tap(find.byTooltip('Remover foto').last);
    await tester.pumpAndSettle();
    expect(find.byType(FotoPickerWidget), findsNWidgets(2));
    expect(find.text('Adicionar foto'), findsOneWidget);

    await _preencher(
      tester,
      _campoComHint('Produtor / Fazenda *'),
      'Fazenda Sul',
    );
    await _preencher(tester, _campoComHint('Produto Utilizado *'), 'Produto X');
    await _preencher(
      tester,
      _campoComHint('Localização (ex: Jataizinho - PR) *'),
      'Jataizinho - PR',
    );
    await _preencher(tester, _campoComHint('Valor *'), '60');
    await tester.ensureVisible(find.text('Publicar Case'));
    await tester.tap(find.text('Publicar Case'));
    await tester.pumpAndSettle();

    expect(publicado, isNull);
    expect(
      find.text('Adicione pelo menos uma foto na Comparação 1.'),
      findsOneWidget,
    );
  });
}

Future<void> _preencher(WidgetTester tester, Finder campo, String valor) async {
  await tester.ensureVisible(campo);
  await tester.enterText(campo, valor);
  await tester.pump();
}

Finder _rotuloComTexto(String texto) {
  return find.byWidgetPredicate(
    (widget) => widget is TextField && widget.controller?.text == texto,
  );
}

Finder _campoComHint(String hint) {
  return find.byWidgetPredicate((widget) {
    return widget is InputDecorator && widget.decoration.hintText == hint;
  });
}

class _FakeClientLookup implements IClientLookup {
  @override
  Future<ClientSummary?> findById(String id) async => null;

  @override
  Future<List<ClientSummary>> listAtivos() async => const [];
}
