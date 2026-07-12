// ADR-012 — planos/presentation/providers/plano_providers.dart
//
// MÓDULOS: @MÓDULO: ESTADO_RIVERPOD | @MÓDULO: ALTERACAO_ESTRUTURAL
//
// REGRAS:
// - planoAtivoProvider: @Riverpod(keepAlive: true) — consultado por marketing/ e map/
// - referralsProvider: @riverpod autoDispose — usado só nas telas de planos/
// - meuCodigoIndicacaoProvider: @riverpod autoDispose — usado só em indicacoes_screen

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/session/session_controller.dart';
import '../../../../core/session/session_models.dart';
import '../../data/repositories/plano_repository_impl.dart';
import '../../data/services/referral_service.dart';
import '../../domain/entities/user_plan.dart';
import '../../domain/entities/referral.dart';
import '../../domain/entities/referral_code.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

part 'plano_providers.g.dart';

// ─────────────────────────────────────────────────────────────
// REPOSITÓRIO — provider interno (não exposto fora do módulo)
// ─────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
PlanoRepositoryImpl planoRepository(PlanoRepositoryRef ref) {
  return PlanoRepositoryImpl(Supabase.instance.client);
}

@Riverpod(keepAlive: true)
ReferralService referralService(ReferralServiceRef ref) {
  return ReferralService(Supabase.instance.client);
}

// ─────────────────────────────────────────────────────────────
// PLANO ATIVO — keepAlive (consultado por marketing/ e map/)
// ─────────────────────────────────────────────────────────────

/// Plano ativo do usuário autenticado.
///
/// keepAlive: true — sobrevive ao dispose de telas para que
/// marketing/ e map/ possam consultá-lo sem re-fetch.
///
/// Nunca retorna null: quando o usuário não possui plano ou não está
/// autenticado, retorna [UserPlan.free()].
///
/// Observa [sessionControllerProvider] para reagir automaticamente ao
/// logout: quando a sessão vira [SessionPublic], retorna UserPlan.free().
@Riverpod(keepAlive: true)
Future<UserPlan> planoAtivo(PlanoAtivoRef ref) async {
  // Reage a mudanças de auth: logout → SessionPublic → retorna free (não erro)
  final session = ref.watch(sessionControllerProvider);
  if (session is! SessionAuthenticated) {
    return UserPlan.free(userId: '');
  }

  final userId = session.user.id;

  try {
    return await ref.read(planoRepositoryProvider).getPlanoAtivo(userId);
  } on AuthException {
    rethrow; // propagar como AsyncError para a UI tratar
  } catch (e, st) {
    AppLogger.error('erro', tag: 'planoAtivoProvider', error: e, stackTrace: st);
    rethrow;
  }
}

// ignore: unused_element
final _planoLogoutInvalidationRegistration = () {
  SessionController.registerLogoutInvalidation(
    key: 'planoAtivoProvider',
    invalidate: (ref) => ref.invalidate(planoAtivoProvider),
  );
  return true;
}();

// ─────────────────────────────────────────────────────────────
// REFERRALS — autoDispose (usado só nas telas de planos/)
// ─────────────────────────────────────────────────────────────

@riverpod
Future<List<Referral>> referrals(ReferralsRef ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return [];

  final repo = ref.watch(planoRepositoryProvider);
  return repo.getReferrals(userId);
}

// ─────────────────────────────────────────────────────────────
// MEU CÓDIGO DE INDICAÇÃO — autoDispose
// ─────────────────────────────────────────────────────────────

@riverpod
Future<ReferralCode?> meuCodigoIndicacao(MeuCodigoIndicacaoRef ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final service = ref.watch(referralServiceProvider);
  return service.getOuCriarCodigo(userId);
}
