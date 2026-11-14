import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/modules/planos/data/services/loja_compra_gateway.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';
import 'package:soloforte_app/modules/planos/presentation/screens/meu_plano_screen.dart';

class _FakeLoja extends LojaCompraGateway {
  _FakeLoja(this.vitrine);

  final LojaVitrine vitrine;
  final comprados = <String>[];

  @override
  Stream<LojaCompraAviso> get avisos => const Stream.empty();

  @override
  Future<LojaVitrine> carregar() async => vitrine;

  @override
  Future<void> comprar(String productId) async {
    comprados.add(productId);
  }

  @override
  Future<void> restaurar() async {}

  @override
  void dispose() {}
}

UserPlan _paidBronze() {
  final now = DateTime.now();
  return UserPlan(
    id: 'plan-1',
    userId: 'u',
    plano: PlanoTipo.bronze,
    origem: PlanoOrigem.pagamento,
    ativo: true,
    iniciouEm: now,
    expiraEm: now.add(const Duration(days: 90)),
    paymentId: 'tx-1',
    criadoEm: now,
  );
}

UserPlan _expiredBronze() {
  final now = DateTime.now();
  return UserPlan(
    id: 'plan-exp',
    userId: 'u',
    plano: PlanoTipo.bronze,
    origem: PlanoOrigem.pagamento,
    ativo: true,
    iniciouEm: now.subtract(const Duration(days: 120)),
    expiraEm: now.subtract(const Duration(days: 1)),
    paymentId: 'tx-old',
    criadoEm: now.subtract(const Duration(days: 120)),
  );
}

class _ThrowingLoja extends LojaCompraGateway {
  @override
  Stream<LojaCompraAviso> get avisos => const Stream.empty();

  @override
  Future<LojaVitrine> carregar() async {
    throw StateError('loja indisponível');
  }

  @override
  Future<void> comprar(String productId) async {}

  @override
  Future<void> restaurar() async {}

  @override
  void dispose() {}
}

const _vitrineTresPlanos = LojaVitrine(
  disponivel: true,
  produtos: [
    LojaProduto(
      productId: 'soloforte_plano_bronze',
      titulo: 'Bronze',
      preco: r'R$ 49,90',
      prazo: '3 meses',
    ),
    LojaProduto(
      productId: 'soloforte_plano_prata',
      titulo: 'Prata',
      preco: r'R$ 79,90',
      prazo: '6 meses',
    ),
    LojaProduto(
      productId: 'soloforte_plano_ouro',
      titulo: 'Ouro',
      preco: r'R$ 119,90',
      prazo: '12 meses',
    ),
  ],
);

Future<void> _pumpMeuPlano(
  WidgetTester tester, {
  required LojaCompraGateway loja,
  required UserPlan plano,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        lojaCompraGatewayProvider.overrideWithValue(loja),
        planoAtivoProvider.overrideWith((ref) async => plano),
        meuCodigoIndicacaoProvider.overrideWith((ref) async => null),
      ],
      child: const MaterialApp(home: MeuPlanoScreen()),
    ),
  );
  await tester.pump();
  await tester.pump();
}

void main() {
  testWidgets('plano gratuito mostra Sem plano pago e preço como compra',
      (tester) async {
    final loja = _FakeLoja(_vitrineTresPlanos);
    await _pumpMeuPlano(
      tester,
      loja: loja,
      plano: UserPlan.free(userId: 'u'),
    );

    expect(find.text('Sem plano pago'), findsOneWidget);
    expect(find.text('via Pagamento'), findsNothing);
    expect(find.text('Sem expiração'), findsNothing);
    expect(find.text(r'R$ 49,90'), findsOneWidget);
    expect(find.text('Atual'), findsNothing);
    expect(find.text('Mudar'), findsNothing);

    await tester.tap(find.text(r'R$ 49,90'));
    await tester.pump();
    expect(loja.comprados, ['soloforte_plano_bronze']);
  });

  testWidgets('plano pago bronze mostra Atual e Mudar nos demais', (tester) async {
    final loja = _FakeLoja(_vitrineTresPlanos);
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpMeuPlano(tester, loja: loja, plano: _paidBronze());
    await tester.pumpAndSettle();

    expect(find.text('Plano Bronze'), findsOneWidget);
    expect(find.text('Atual'), findsOneWidget);
    expect(find.text('Mudar'), findsNWidgets(2));
    expect(find.text(r'R$ 49,90'), findsNothing);

    await tester.tap(find.text('Mudar').first);
    await tester.pump();
    expect(loja.comprados, ['soloforte_plano_prata']);
  });

  testWidgets('plano bronze expirado não mostra Atual e permite recompra',
      (tester) async {
    final loja = _FakeLoja(_vitrineTresPlanos);
    tester.view.physicalSize = const Size(390, 1800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpMeuPlano(tester, loja: loja, plano: _expiredBronze());
    await tester.pumpAndSettle();

    expect(find.text('Atual'), findsNothing);
    expect(find.text(r'R$ 49,90'), findsOneWidget);
    expect(find.text('Mudar'), findsNWidgets(2));
  });

  testWidgets('falha ao carregar loja não fica em loading eterno',
      (tester) async {
    await _pumpMeuPlano(
      tester,
      loja: _ThrowingLoja(),
      plano: UserPlan.free(userId: 'u'),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(
      find.text(
        'A loja não tem planos disponíveis para compra neste momento.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('loja sem produtos não mostra preço', (tester) async {
    final loja = _FakeLoja(LojaVitrine.indisponivel);
    await _pumpMeuPlano(
      tester,
      loja: loja,
      plano: UserPlan.free(userId: 'u'),
    );

    expect(
      find.text(
        'A loja não tem planos disponíveis para compra neste momento.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining(r'R$'), findsNothing);
    expect(find.text('Restaurar compras'), findsNothing);
  });
}