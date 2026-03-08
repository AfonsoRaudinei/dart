// ADR-012 — planos/presentation/providers/plano_providers.dart
//
// MÓDULOS: @MÓDULO: ESTADO_RIVERPOD | @MÓDULO: ALTERACAO_ESTRUTURAL
//
// REGRAS:
// - planoAtivoProvider: @Riverpod(keepAlive: true) — consultado por marketing/ e map/
// - referralsProvider: @riverpod autoDispose — usado só nas telas de planos/
// - meuCodigoIndicacaoProvider: @riverpod autoDispose — usado só em indicacoes_screen

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/session/session_controller.dart';
import '../../../../core/session/session_models.dart';
import '../../data/repositories/plano_repository_impl.dart';
import '../../data/services/referral_service.dart';
import '../../domain/entities/user_plan.dart';
import '../../domain/entities/referral.dart';
import '../../domain/entities/referral_code.dart';

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
/// Retorna null se o usuário não possui plano ativo.
///
/// Observa [sessionControllerProvider] para reagir automaticamente ao
/// logout: quando a sessão vira [SessionPublic], retorna null sem erro.
@Riverpod(keepAlive: true)
Future<UserPlan?> planoAtivo(PlanoAtivoRef ref) async {
  // Reage a mudanças de auth: logout → SessionPublic → retorna null (não erro)
  final session = ref.watch(sessionControllerProvider);
  if (session is! SessionAuthenticated) return null;

  final userId = session.user.id;

  try {
    return await ref.read(planoRepositoryProvider).getPlanoAtivo(userId);
  } on AuthException {
    rethrow; // propagar como AsyncError para a UI tratar
  } catch (e, st) {
    debugPrint('[planoAtivoProvider] erro: $e\n$st');
    rethrow;
  }
}

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
