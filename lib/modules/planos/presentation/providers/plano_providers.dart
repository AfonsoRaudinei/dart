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
@Riverpod(keepAlive: true)
Future<UserPlan?> planoAtivo(PlanoAtivoRef ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;

  final repo = ref.watch(planoRepositoryProvider);
  return repo.getPlanoAtivo(userId);
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
