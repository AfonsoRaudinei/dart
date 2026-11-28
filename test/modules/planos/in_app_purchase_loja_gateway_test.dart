import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:soloforte_app/modules/planos/data/services/in_app_purchase_loja_gateway.dart';
import 'package:soloforte_app/modules/planos/data/services/loja_compra_gateway.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class _FakeSupabaseClient implements SupabaseClient {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeInAppPurchase implements InAppPurchase {
  _FakeInAppPurchase({
    this.disponivel = true,
    this.resposta,
    this.falhaNaConsulta = false,
  });

  final bool disponivel;
  final ProductDetailsResponse? resposta;
  final bool falhaNaConsulta;
  Set<String>? idsConsultados;
  final _compras = StreamController<List<PurchaseDetails>>.broadcast();

  @override
  Stream<List<PurchaseDetails>> get purchaseStream => _compras.stream;

  @override
  Future<bool> isAvailable() async => disponivel;

  @override
  Future<ProductDetailsResponse> queryProductDetails(
    Set<String> identifiers,
  ) async {
    idsConsultados = identifiers;
    if (falhaNaConsulta) throw StateError('falha de plataforma');
    return resposta!;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ProductDetails _produto(String id, String preco) => ProductDetails(
  id: id,
  title: id,
  description: '',
  price: preco,
  rawPrice: 1,
  currencyCode: 'BRL',
);

InAppPurchaseLojaGateway _gateway(_FakeInAppPurchase loja) =>
    InAppPurchaseLojaGateway(_FakeSupabaseClient(), loja: loja);

void main() {
  test(
    'loja fechada devolve vitrine indisponível com motivo lojaFechada',
    () async {
      final gateway = _gateway(_FakeInAppPurchase(disponivel: false));
      addTearDown(gateway.dispose);

      final vitrine = await gateway.carregar();

      expect(vitrine.disponivel, isFalse);
      expect(vitrine.produtos, isEmpty);
      expect(vitrine.motivoIndisponivel, LojaMotivoIndisponivel.lojaFechada);
    },
  );

  test(
    'notFoundIDs sem produtos devolve motivo produtosNaoEncontrados',
    () async {
      final loja = _FakeInAppPurchase(
        resposta: ProductDetailsResponse(
          productDetails: const [],
          notFoundIDs: const [
            'soloforte_plano_bronze',
            'soloforte_plano_prata',
            'soloforte_plano_ouro',
          ],
        ),
      );
      final gateway = _gateway(loja);
      addTearDown(gateway.dispose);

      final vitrine = await gateway.carregar();

      expect(loja.idsConsultados, {
        'soloforte_plano_bronze',
        'soloforte_plano_prata',
        'soloforte_plano_ouro',
      });
      expect(vitrine.disponivel, isTrue);
      expect(vitrine.produtos, isEmpty);
      expect(
        vitrine.motivoIndisponivel,
        LojaMotivoIndisponivel.produtosNaoEncontrados,
      );
    },
  );

  test('erro da consulta devolve motivo erroConsulta', () async {
    final gateway = _gateway(
      _FakeInAppPurchase(
        resposta: ProductDetailsResponse(
          productDetails: const [],
          notFoundIDs: const [],
          error: IAPError(
            source: 'app_store',
            code: 'storekit_error',
            message: 'falha',
          ),
        ),
      ),
    );
    addTearDown(gateway.dispose);

    final vitrine = await gateway.carregar();

    expect(vitrine.disponivel, isTrue);
    expect(vitrine.produtos, isEmpty);
    expect(vitrine.motivoIndisponivel, LojaMotivoIndisponivel.erroConsulta);
  });

  test('exceção em queryProductDetails não propaga', () async {
    final gateway = _gateway(_FakeInAppPurchase(falhaNaConsulta: true));
    addTearDown(gateway.dispose);

    final vitrine = await gateway.carregar();

    expect(vitrine.produtos, isEmpty);
    expect(vitrine.motivoIndisponivel, LojaMotivoIndisponivel.erroConsulta);
  });

  test('retorno parcial mostra só o que a loja devolveu, sem motivo', () async {
    final gateway = _gateway(
      _FakeInAppPurchase(
        resposta: ProductDetailsResponse(
          productDetails: [_produto('soloforte_plano_prata', r'R$ 300,00')],
          notFoundIDs: const ['soloforte_plano_bronze', 'soloforte_plano_ouro'],
        ),
      ),
    );
    addTearDown(gateway.dispose);

    final vitrine = await gateway.carregar();

    expect(vitrine.disponivel, isTrue);
    expect(vitrine.produtos.map((p) => p.productId), ['soloforte_plano_prata']);
    expect(vitrine.produtos.single.preco, r'R$ 300,00');
    expect(vitrine.produtos.single.prazo, '6 meses');
    expect(vitrine.motivoIndisponivel, isNull);
  });
}
