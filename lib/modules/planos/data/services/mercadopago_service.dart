// ADR-012 — planos/data/services/mercadopago_service.dart
//
// NOTA: Integração Mercado Pago requer SDK externo (mercadopago_sdk ou WebView).
// Esta classe define o contrato de interface que o provider e as telas chamam.
// A implementação real via SDK será adicionada no PASSO 2 (Edge Function + webhook).
//
// Por ora: método initCheckout retorna URL de pagamento gerada via backend.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Serviço de pagamento via Mercado Pago.
///
/// Fluxo:
/// 1. App chama [criarPreferenciaPagamento] → obtém URL de checkout MP
/// 2. App abre URL em WebView ou browser externo
/// 3. Webhook Mercado Pago notifica Edge Function → atualiza user_plans
/// 4. [watchPlanoAtivo] (via IPlanoRepository) detecta mudança via Realtime
class MercadoPagoService {
  final SupabaseClient _client;

  const MercadoPagoService(this._client);

  /// Cria uma preferência de pagamento no Mercado Pago via Edge Function.
  ///
  /// Retorna a [checkoutUrl] que deve ser aberta no browser/WebView.
  /// [plano] = 'bronze' | 'prata' | 'ouro'
  /// [metodo] = 'pix' | 'cartao'
  Future<String> criarPreferenciaPagamento({
    required String plano,
    required String metodo,
  }) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      throw UnsupportedError('Pagamentos externos desabilitados no iOS.');
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
