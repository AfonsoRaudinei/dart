// ADR-012 — planos/data/services/referral_service.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/referral_code.dart';

/// Serviço de indicações (referrals).
///
/// Responsabilidades:
/// - Gerar código único de indicação para o usuário
/// - Validar código de indicação no momento do pagamento (feito pelo webhook)
class ReferralService {
  final SupabaseClient _client;

  const ReferralService(this._client);

  /// Gera e persiste um código de indicação para o [userId].
  ///
  /// Retorna o [ReferralCode] criado.
  /// Lança [Exception] se o usuário já possui código (unique constraint).
  Future<ReferralCode> gerarCodigoIndicacao(String userId) async {
    // Código: 8 caracteres alfanuméricos únicos, maiúsculos
    final code = _gerarCodigo();

    final response = await _client
        .from('referral_codes')
        .insert({'user_id': userId, 'code': code, 'indicacoes_validadas': 0})
        .select()
        .single();

    return ReferralCode.fromJson(response);
  }

  /// Retorna o código existente ou cria um novo para o [userId].
  Future<ReferralCode> getOuCriarCodigo(String userId) async {
    final existente = await _client
        .from('referral_codes')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (existente != null) {
      return ReferralCode.fromJson(existente);
    }

    return gerarCodigoIndicacao(userId);
  }

  /// Gera código de 8 caracteres alfanuméricos.
  String _gerarCodigo() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final now = DateTime.now().millisecondsSinceEpoch;
    var seed = now;
    final buffer = StringBuffer();
    for (var i = 0; i < 8; i++) {
      seed = (seed * 1664525 + 1013904223) & 0xFFFFFFFF;
      buffer.write(chars[seed % chars.length]);
    }
    return buffer.toString();
  }
}
