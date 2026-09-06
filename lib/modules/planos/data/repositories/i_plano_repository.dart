// ADR-012 — planos/data/repositories/i_plano_repository.dart
import '../../domain/entities/user_plan.dart';
import '../../domain/entities/referral.dart';
import '../../domain/entities/referral_code.dart';

/// Contrato do repositório de planos.
///
/// Fonte da verdade: Supabase (remoto). Este repositório NÃO persiste em SQLite.
/// Cache de leitura (TTL 24h) vive em `PlanoLocalCache` via PreferencesService
/// — ADR-012 Adendo 1. Não colocar cache neste contrato.
abstract class IPlanoRepository {
  /// Retorna o plano ativo do usuário, ou [UserPlan.free()] se não possui plano.
  Future<UserPlan> getPlanoAtivo(String userId);

  /// Ativa um plano para o usuário (inserção no Supabase).
  Future<UserPlan> ativarPlano(UserPlan plano);

  /// Lista todas as indicações feitas pelo [referrerId].
  Future<List<Referral>> getReferrals(String referrerId);

  /// Stream com o plano ativo em tempo real (Supabase Realtime).
  /// Emite [UserPlan.free()] quando o usuário não possui plano ou o plano expira.
  Stream<UserPlan> watchPlanoAtivo(String userId);

  /// Retorna o código de indicação do usuário, criando se não existir.
  Future<ReferralCode?> getMeuCodigoIndicacao(String userId);
}
