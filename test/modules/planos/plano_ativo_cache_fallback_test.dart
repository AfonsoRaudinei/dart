import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soloforte_app/core/infra/preferences_service.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:soloforte_app/core/session/session_models.dart';
import 'package:soloforte_app/modules/planos/data/repositories/i_plano_repository.dart';
import 'package:soloforte_app/modules/planos/data/services/plano_local_cache.dart';
import 'package:soloforte_app/modules/planos/domain/entities/referral.dart';
import 'package:soloforte_app/modules/planos/domain/entities/referral_code.dart';
import 'package:soloforte_app/modules/planos/domain/entities/user_plan.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_origem.dart';
import 'package:soloforte_app/modules/planos/domain/enums/plano_tipo.dart';
import 'package:soloforte_app/modules/planos/domain/plano_cache_unavailable_exception.dart';
import 'package:soloforte_app/modules/planos/presentation/providers/plano_providers.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() {
  const userId = 'user-plano-cache';

  UserPlan _cachedPlan() => UserPlan(
        id: 'plan-cached',
        userId: userId,
        plano: PlanoTipo.prata,
        origem: PlanoOrigem.pagamento,
        ativo: true,
        iniciouEm: DateTime.utc(2026, 8, 1),
        expiraEm: DateTime.utc(2027, 8, 1),
        criadoEm: DateTime.utc(2026, 8, 1),
      );

  Future<ProviderContainer> _container({
    required Object repoError,
    bool seedCache = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    if (seedCache) {
      await PlanoLocalCache(prefs).save(_cachedPlan());
    }

    final container = ProviderContainer(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
        sessionControllerProvider.overrideWith(
          _AuthenticatedSessionController.new,
        ),
        planoRepositoryProvider.overrideWithValue(
          _ThrowingPlanoRepo(repoError),
        ),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('planoAtivoProvider cache fallback', () {
    test('SocketException com cache válido retorna o UserPlan em cache',
        () async {
      final container = await _container(
        repoError: const SocketException('Failed host lookup'),
        seedCache: true,
      );

      final plan = await container.read(planoAtivoProvider.future);
      expect(plan.id, 'plan-cached');
      expect(plan.userId, userId);
      expect(plan.plano, PlanoTipo.prata);
    });

    test('SocketException sem cache lança PlanoCacheUnavailableException',
        () async {
      final container = await _container(
        repoError: const SocketException('Failed host lookup'),
      );

      await expectLater(
        container.read(planoAtivoProvider.future),
        throwsA(
          isA<PlanoCacheUnavailableException>().having(
            (e) => e.expired,
            'expired',
            isFalse,
          ),
        ),
      );
    });

    test('AuthException não serve cache mesmo com UserPlan gravado', () async {
      final container = await _container(
        repoError: const AuthException('JWT expired'),
        seedCache: true,
      );

      await expectLater(
        container.read(planoAtivoProvider.future),
        throwsA(isA<AuthException>()),
      );
    });

    test('PostgrestException PGRST301 não serve cache', () async {
      final container = await _container(
        repoError: const PostgrestException(
          message: 'JWT expired',
          code: 'PGRST301',
        ),
        seedCache: true,
      );

      await expectLater(
        container.read(planoAtivoProvider.future),
        throwsA(isA<PostgrestException>()),
      );
    });
  });
}

class _AuthenticatedSessionController extends SessionController {
  @override
  SessionState build() => SessionAuthenticated(
        User.fromJson(const {
          'id': 'user-plano-cache',
          'app_metadata': <String, dynamic>{},
          'user_metadata': <String, dynamic>{},
          'aud': 'authenticated',
          'created_at': '2026-09-05T12:00:00.000Z',
          'email': 'cache@soloforte.app',
        })!,
      );
}

class _ThrowingPlanoRepo implements IPlanoRepository {
  _ThrowingPlanoRepo(this.error);

  final Object error;

  @override
  Future<UserPlan> getPlanoAtivo(String userId) async => throw error;

  @override
  Future<UserPlan> ativarPlano(UserPlan plano) => throw UnimplementedError();

  @override
  Future<List<Referral>> getReferrals(String referrerId) async => const [];

  @override
  Stream<UserPlan> watchPlanoAtivo(String userId) => const Stream.empty();

  @override
  Future<ReferralCode?> getMeuCodigoIndicacao(String userId) async => null;
}
