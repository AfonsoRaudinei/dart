import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/planos/data/services/loja_compra_gateway.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/store_plan_catalog.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';
import 'package:soloforte_app/modules/planos/presentation/screens/planos_screen.dart';

class _FakeLoja extends LojaCompraGateway {
  _FakeLoja(this.vitrine);

  final LojaVitrine vitrine;
  final comprados = <String>[];
  var restauracoes = 0;

  @override
  Stream<LojaCompraAviso> get avisos => const Stream.empty();

  @override
  Future<LojaVitrine> carregar() async => vitrine;

  @override
  Future<void> comprar(String productId) async {
    comprados.add(productId);
  }

  @override
  Future<void> restaurar() async {
    restauracoes += 1;
  }

  @override
  void dispose() {}
}

void main() {
  test('catálogo da loja usa 3, 6 e 12 meses', () {
    expect(storePlanOffers.map((offer) => offer.months).toList(), [3, 6, 12]);
    expect(
      storePlanOffers.map((offer) => offer.productId).toList(),
      [
        'soloforte_plano_bronze',
        'soloforte_plano_prata',
        'soloforte_plano_ouro',
      ],
    );
  });

  testWidgets('mostra preço da loja, compra e restaurar', (tester) async {
    final loja = _FakeLoja(
      const LojaVitrine(
        disponivel: true,
        produtos: [
          LojaProduto(
            productId: 'soloforte_plano_bronze',
            titulo: 'Bronze',
            preco: r'R$ 49,90',
            prazo: '3 meses',
          ),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lojaCompraGatewayProvider.overrideWithValue(loja),
          planoAtivoProvider.overrideWith((ref) async => UserPlan.free(userId: 'u')),
        ],
        child: const MaterialApp(home: PlanosScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Bronze'), findsOneWidget);
    expect(find.textContaining(r'R$ 49,90'), findsOneWidget);
    expect(find.text('Comprar'), findsOneWidget);
    expect(find.text('Restaurar compras'), findsOneWidget);

    await tester.tap(find.text('Comprar'));
    await tester.pump();
    expect(loja.comprados, ['soloforte_plano_bronze']);

    await tester.tap(find.text('Restaurar compras'));
    await tester.pump();
    expect(loja.restauracoes, 1);
  });

  testWidgets('sem produto da loja não mostra preço nem compra', (tester) async {
    final loja = _FakeLoja(LojaVitrine.indisponivel);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          lojaCompraGatewayProvider.overrideWithValue(loja),
          planoAtivoProvider.overrideWith((ref) async => UserPlan.free(userId: 'u')),
        ],
        child: const MaterialApp(home: PlanosScreen()),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(
      find.text('A loja não tem planos disponíveis para compra neste momento.'),
      findsOneWidget,
    );
    expect(find.text('Comprar'), findsNothing);
    expect(find.text('Restaurar compras'), findsNothing);
    expect(find.textContaining(r'R$'), findsNothing);
  });
}
