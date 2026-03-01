// ADR-012 — planos/data/repositories/plano_repository_impl.dart
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/user_plan.dart';
import '../../domain/entities/referral.dart';
import '../../domain/entities/referral_code.dart';
import 'i_plano_repository.dart';

/// Implementação do repositório de planos via Supabase.
///
/// Fonte da verdade: remoto (online-only — ADR-012).
/// Sem cache SQLite: publicar cases é fluxo que exige conectividade.
class PlanoRepositoryImpl implements IPlanoRepository {
  final SupabaseClient _client;

  const PlanoRepositoryImpl(this._client);

  @override
  Future<UserPlan?> getPlanoAtivo(String userId) async {
    final response = await _client
        .from('user_plans')
        .select()
        .eq('user_id', userId)
        .eq('ativo', true)
        .order('criado_em', ascending: false)
        .limit(1)
        .maybeSingle();

    if (response == null) return null;
    return UserPlan.fromJson(response);
  }

  @override
  Future<UserPlan> ativarPlano(UserPlan plano) async {
    final response = await _client
        .from('user_plans')
        .insert(plano.toJson())
        .select()
        .single();

    return UserPlan.fromJson(response);
  }

  @override
  Future<List<Referral>> getReferrals(String referrerId) async {
    final response = await _client
        .from('referrals')
        .select()
        .eq('referrer_id', referrerId)
        .order('criado_em', ascending: false);

    return (response as List)
        .map((json) => Referral.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Stream<UserPlan?> watchPlanoAtivo(String userId) {
    return _client
        .from('user_plans')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((rows) {
          final ativos = rows.where((r) => r['ativo'] == true).toList()
            ..sort(
              (a, b) => (b['criado_em'] as String).compareTo(
                a['criado_em'] as String,
              ),
            );
          if (ativos.isEmpty) return null;
          return UserPlan.fromJson(ativos.first);
        });
  }

  @override
  Future<ReferralCode?> getMeuCodigoIndicacao(String userId) async {
    final response = await _client
        .from('referral_codes')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (response == null) return null;
    return ReferralCode.fromJson(response);
  }
}
