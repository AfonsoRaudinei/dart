// ADR-012 — planos/presentation/providers/plano_providers.dart
//
// MÓDULOS: @MÓDULO: ESTADO_RIVERPOD | @MÓDULO: ALTERACAO_ESTRUTURAL
//
// REGRAS:
// - planoAtivoProvider: @Riverpod(keepAlive: true) — consultado por marketing/ e map/
// - referralsProvider: @riverpod autoDispose — usado só nas telas de planos/
// - meuCodigoIndicacaoProvider: @riverpod autoDispose — usado só em indicacoes_screen

import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/infra/preferences_service.dart';
import '../../../../core/session/local_session_identity.dart';
import '../../../../core/session/session_controller.dart';
import '../../../../core/session/session_models.dart';
import '../../data/repositories/i_plano_repository.dart';
import '../../data/repositories/plano_repository_impl.dart';
import '../../data/services/plano_local_cache.dart';
import '../../data/services/referral_service.dart';
import '../../domain/entities/user_plan.dart';
import '../../domain/entities/referral.dart';
import '../../domain/entities/referral_code.dart';
import '../../domain/plano_cache_unavailable_exception.dart';
import 'package:soloforte_app/core/utils/app_logger.dart';

part 'plano_providers.g.dart';

// ─────────────────────────────────────────────────────────────
// REPOSITÓRIO — provider interno (não exposto fora do módulo)
// ─────────────────────────────────────────────────────────────

@Riverpod(keepAlive: true)
IPlanoRepository planoRepository(PlanoRepositoryRef ref) {
  return PlanoRepositoryImpl(Supabase.instance.client);
}

@Riverpod(keepAlive: true)
ReferralService referralService(ReferralServiceRef ref) {
  return ReferralService(Supabase.instance.client);
}

/// Cache local do último plano verificado online (TTL 24h — ADR-012 Adendo 1).
@Riverpod(keepAlive: true)
PlanoLocalCache planoLocalCache(PlanoLocalCacheRef ref) {
  return PlanoLocalCache(ref.watch(preferencesServiceProvider));
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
///
/// Offline / timeout: serve [PlanoLocalCache] se a verificação online
/// ocorreu nas últimas 24h. [AuthException] nunca usa cache (Adendo 1).
@Riverpod(keepAlive: true)
Future<UserPlan> planoAtivo(PlanoAtivoRef ref) async {
  // Reage a mudanças de auth: logout → SessionPublic → retorna free (não erro)
  final session = ref.watch(sessionControllerProvider);
  if (session is! SessionAuthenticated) {
    return UserPlan.free(userId: '');
  }

  final userId = session.user.id;
  final cache = ref.read(planoLocalCacheProvider);

  try {
    final plan = await ref.read(planoRepositoryProvider).getPlanoAtivo(userId);
    try {
      await cache.save(plan);
    } catch (e) {
      AppLogger.warning(
        'falha ao gravar cache de plano',
        tag: 'planoAtivoProvider',
        error: e,
      );
    }
    return plan;
  } catch (e, st) {
    if (isPlanoSessionOrRlsError(e)) {
      Error.throwWithStackTrace(e, st);
    }
    final cached = cache.readValid(userId);
    if (cached != null) {
      AppLogger.warning(
        'Supabase indisponível; usando UserPlan em cache (TTL 24h)',
        tag: 'planoAtivoProvider',
        error: e,
      );
      return cached;
    }
    AppLogger.error('erro', tag: 'planoAtivoProvider', error: e, stackTrace: st);
    throw PlanoCacheUnavailableException(expired: cache.isExpired(userId));
  }
}

// ignore: unused_element
final _planoLogoutInvalidationRegistration = () {
  SessionController.registerLogoutInvalidation(
    key: 'planoAtivoProvider',
    invalidate: (ref) {
      try {
        final userId = LocalSessionIdentity.resolveUserId();
        if (userId.isNotEmpty) {
          unawaited(ref.read(planoLocalCacheProvider).clear(userId));
        }
      } catch (_) {}
      ref.invalidate(planoAtivoProvider);
    },
  );
  return true;
}();

// ─────────────────────────────────────────────────────────────
// REFERRALS — autoDispose (usado só nas telas de planos/)
// ─────────────────────────────────────────────────────────────

@riverpod
Future<List<Referral>> referrals(ReferralsRef ref) async {
  final userId = LocalSessionIdentity.resolveUserId();
  if (userId.isEmpty) return [];

  final repo = ref.watch(planoRepositoryProvider);
  return repo.getReferrals(userId);
}

// ─────────────────────────────────────────────────────────────
// MEU CÓDIGO DE INDICAÇÃO — autoDispose
// ─────────────────────────────────────────────────────────────

@riverpod
Future<ReferralCode?> meuCodigoIndicacao(MeuCodigoIndicacaoRef ref) async {
  final userId = LocalSessionIdentity.resolveUserId();
  if (userId.isEmpty) return null;

  final service = ref.watch(referralServiceProvider);
  return service.getOuCriarCodigo(userId);
}
