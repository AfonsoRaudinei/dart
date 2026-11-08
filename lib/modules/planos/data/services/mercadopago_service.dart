// ADR-012 Adendo 2 — planos/data/services/mercadopago_service.dart
//
// Fora do funil do app. iOS e Android recusam antes de chamar a Edge.
// Compra in-app, quando existir, será StoreKit ou Play Billing.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Cliente legado do Mercado Pago. Não é o funil de compra do app.
///
/// [criarPreferenciaPagamento] recusa iOS e Android antes de invocar a Edge.
class MercadoPagoService {
  final SupabaseClient _client;

  const MercadoPagoService(this._client);

  /// Recusa no iOS e no Android. Não chama `mercadopago-criar-preferencia`.
  ///
  /// [plano] = 'bronze' | 'prata' | 'ouro'
  /// [metodo] = 'pix' | 'cartao'
  Future<String> criarPreferenciaPagamento({
    required String plano,
    required String metodo,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.android) {
      throw UnsupportedError(
        'Pagamentos externos desabilitados. A compra de plano no app é pela loja.',
      );
    }

    final response = await _client.functions.invoke(
      'mercadopago-criar-preferencia',
      body: {'plano': plano, 'metodo': metodo},
    );

    if (response.status != 200) {
      throw Exception(
        'Erro ao criar preferência de pagamento: ${response.data}',
      );
    }

    final data = response.data as Map<String, dynamic>;
    final checkoutUrl =
        data['checkout_url'] as String? ?? data['init_point'] as String?;
    if (checkoutUrl == null || checkoutUrl.isEmpty) {
      throw Exception('URL de checkout Mercado Pago ausente na resposta.');
    }
    return checkoutUrl;
  }
}
