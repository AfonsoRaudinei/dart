import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/store_plan_catalog.dart';
import 'loja_compra_gateway.dart';

class InAppPurchaseLojaGateway implements LojaCompraGateway {
  InAppPurchaseLojaGateway(this._client, {InAppPurchase? loja})
    : _loja = loja ?? InAppPurchase.instance {
    _assinatura = _loja.purchaseStream.listen(_aoAtualizarCompras);
  }

  final SupabaseClient _client;
  final InAppPurchase _loja;
  final _avisosController = StreamController<LojaCompraAviso>.broadcast();
  final Map<String, ProductDetails> _produtos = {};
  late final StreamSubscription<List<PurchaseDetails>> _assinatura;

  @override
  Stream<LojaCompraAviso> get avisos => _avisosController.stream;

  @override
  Future<LojaVitrine> carregar() async {
    if (!await _loja.isAvailable()) return LojaVitrine.indisponivel;
    final resposta = await _loja.queryProductDetails(
      storePlanOffers.map((offer) => offer.productId).toSet(),
    );
    _produtos
      ..clear()
      ..addEntries(resposta.productDetails.map((item) => MapEntry(item.id, item)));
    final produtos = <LojaProduto>[];
    for (final offer in storePlanOffers) {
      final detalhes = _produtos[offer.productId];
      if (detalhes == null) continue;
      produtos.add(
        LojaProduto(
          productId: offer.productId,
          titulo: offer.label,
          preco: detalhes.price,
          prazo: offer.prazo,
        ),
      );
    }
    return LojaVitrine(disponivel: true, produtos: produtos);
  }

  @override
  Future<void> comprar(String productId) async {
    final detalhes = _produtos[productId];
    if (detalhes == null) {
      _emitir('Este plano não está disponível na loja.', erro: true);
      return;
    }
    final parametro = PurchaseParam(productDetails: detalhes);
    if (defaultTargetPlatform == TargetPlatform.android) {
      await _loja.buyConsumable(purchaseParam: parametro);
    } else {
      await _loja.buyNonConsumable(purchaseParam: parametro);
    }
  }

  @override
  Future<void> restaurar() => _loja.restorePurchases();

  Future<void> _aoAtualizarCompras(List<PurchaseDetails> compras) async {
    for (final compra in compras) {
      switch (compra.status) {
        case PurchaseStatus.pending:
          _emitir('Compra pendente na loja.');
        case PurchaseStatus.canceled:
          await _concluir(compra);
          _emitir('Compra cancelada.');
        case PurchaseStatus.error:
          await _concluir(compra);
          _emitir(
            compra.error?.message ?? 'A loja não concluiu a compra.',
            erro: true,
          );
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          await _confirmar(compra);
      }
    }
  }

  Future<void> _confirmar(PurchaseDetails compra) async {
    final plataforma = switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'ios',
      TargetPlatform.android => 'android',
      _ => null,
    };
    final recibo = compra.verificationData.serverVerificationData;
    final transacao = compra.purchaseID ?? '';
    if (plataforma == null ||
        recibo.isEmpty ||
        storePlanOfferFor(compra.productID) == null ||
        (plataforma == 'ios' && transacao.isEmpty)) {
      _emitir('A loja não entregou o recibo.', erro: true);
      return;
    }

    try {
      final resposta = await _client.functions.invoke(
        'loja-verificar-compra',
        body: {
          'platform': plataforma,
          'productId': compra.productID,
          'transactionId': transacao,
          'verificationData': recibo,
        },
      );
      final dados = resposta.data;
      final status = dados is Map ? dados['status'] : null;
      if (status == 'granted' || status == 'already_granted') {
        await _concluir(compra);
        _emitir('Plano confirmado.', concedido: true);
        return;
      }
      _emitir('Não foi possível confirmar a compra.', erro: true);
    } catch (_) {
      _emitir(
        'Não foi possível confirmar a compra. Tente restaurar mais tarde.',
        erro: true,
      );
    }
  }

  Future<void> _concluir(PurchaseDetails compra) async {
    if (compra.pendingCompletePurchase) {
      await _loja.completePurchase(compra);
    }
  }

  void _emitir(String mensagem, {bool erro = false, bool concedido = false}) {
    if (_avisosController.isClosed) return;
    _avisosController.add(
      LojaCompraAviso(mensagem: mensagem, erro: erro, concedido: concedido),
    );
  }

  @override
  void dispose() {
    _assinatura.cancel();
    _avisosController.close();
  }
}
