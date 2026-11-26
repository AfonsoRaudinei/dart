import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/carteira/domain/entities/carteira_tipo_produto.dart';
import 'package:soloforte_app/modules/carteira/presentation/providers/carteira_providers.dart';
import 'package:soloforte_app/modules/carteira/presentation/widgets/categoria_form_dialog.dart';

CategoriaFormResult? lastCategoriaFormSaveResult;

void main() {
  const userId = 'user-categoria-form';

  final tipoPadrao = CarteiraTipoProduto(
    id: 'tipo-1',
    userId: userId,
    codigo: 'rs_ha',
    label: r'R$/ha',
    converteSacasHa: true,
    sistema: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );

  Future<void> pumpDialog(
    WidgetTester tester, {
    double? initialValorReal,
    String? initialNome,
    String title = 'Nova categoria',
    bool viaSheet = false,
  }) async {
    lastCategoriaFormSaveResult = null;
    final dialog = CategoriaFormDialog(
      userId: userId,
      initialValorReal: initialValorReal,
      initialNome: initialNome,
      title: title,
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tiposProdutoProvider(userId).overrideWith((ref) async => [tipoPadrao]),
        ],
        child: MaterialApp(
          home: viaSheet
              ? Scaffold(
                  body: Builder(
                    builder: (context) => TextButton(
                      onPressed: () {
                        Navigator.of(context)
                            .push<CategoriaFormResult>(
                          MaterialPageRoute(
                            fullscreenDialog: true,
                            builder: (_) => Scaffold(body: dialog),
                          ),
                        )
                            .then((r) => lastCategoriaFormSaveResult = r);
                      },
                      child: const Text('Abrir'),
                    ),
                  ),
                )
              : Scaffold(body: dialog),
        ),
      ),
    );
    if (viaSheet) {
      await tester.tap(find.text('Abrir'));
    }
    await tester.pumpAndSettle();
  }

  testWidgets('custo/referência fica em Mais opções', (tester) async {
    await pumpDialog(tester);

    expect(find.text('Mais opções'), findsOneWidget);
    expect(find.text('Custo / Referência (opcional)'), findsNothing);

    await tester.tap(find.text('Mais opções'));
    await tester.pumpAndSettle();

    expect(find.text('Custo / Referência (opcional)'), findsOneWidget);
    expect(
      find.textContaining('não é meta de venda', findRichText: true),
      findsWidgets,
    );
  });

  testWidgets('validator de custo/referência rejeita valor inválido', (
    tester,
  ) async {
    await pumpDialog(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Categoria teste');
    await tester.tap(find.text('Mais opções'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'abc');
    await tester.tap(find.text('Salvar'));
    await tester.pumpAndSettle();

    expect(find.text('Valor inválido'), findsOneWidget);
  });

  testWidgets(
    'salvar com Mais opções fechado preserva initialValorReal ao editar',
    (tester) async {
      const initialValor = 99.5;
      await pumpDialog(
        tester,
        initialNome: 'Categoria existente',
        initialValorReal: initialValor,
        title: 'Editar categoria',
        viaSheet: true,
      );

      expect(find.text('Mais opções'), findsOneWidget);
      expect(find.text('Custo / Referência (opcional)'), findsNothing);

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoriaFormDialog), findsNothing);
      expect(lastCategoriaFormSaveResult, isNotNull);
      expect(
        lastCategoriaFormSaveResult!.valorReferencia,
        initialValor,
      );
    },
  );

  testWidgets(
    'valor inválido com seção recolhida não salva e exibe erro',
    (tester) async {
      await pumpDialog(tester, viaSheet: true);

      await tester.enterText(find.byType(TextFormField).first, 'Categoria teste');
      await tester.tap(find.text('Mais opções'));
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(1), 'abc');
      await tester.tap(find.text('Mais opções'));
      await tester.pumpAndSettle();

      expect(find.text('Custo / Referência (opcional)'), findsNothing);

      await tester.tap(find.text('Salvar'));
      await tester.pumpAndSettle();

      expect(find.byType(CategoriaFormDialog), findsOneWidget);
      expect(lastCategoriaFormSaveResult, isNull);
      expect(find.text('Valor inválido'), findsOneWidget);
    },
  );
}