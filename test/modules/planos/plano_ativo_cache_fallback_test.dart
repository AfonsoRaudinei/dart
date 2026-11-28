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

  UserPlan cachedPlan() => UserPlan(
    id: 'plan-cached',
    userId: userId,
    plano: PlanoTipo.prata,
    origem: PlanoOrigem.pagamento,
    ativo: true,
    iniciouEm: DateTime.utc(2026, 8, 1),
    expiraEm: DateTime.now().add(const Duration(days: 365)),
    criadoEm: DateTime.utc(2026, 8, 1),
  );

  Future<ProviderContainer> buildContainer({
    required Object repoError,
    bool seedCache = false,
    IPlanoRepository? repo,
    Future<void> Function()? refresh,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = PreferencesService(await SharedPreferences.getInstance());
    if (seedCache) {
      await PlanoLocalCache(prefs).save(cachedPlan());
    }

    final container = ProviderContainer(
      overrides: [
        preferencesServiceProvider.overrideWithValue(prefs),
        sessionControllerProvider.overrideWith(
          _AuthenticatedSessionController.new,
        ),
        planoRepositoryProvider.overrideWithValue(
          repo ?? _ThrowingPlanoRepo(repoError),
        ),
        planoSessionRefresherProvider.overrideWithValue(refresh ?? () async {}),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('planoAtivoProvider cache fallback', () {
    test(
      'SocketException com cache válido retorna o UserPlan em cache',
      () async {
        final container = await buildContainer(
          repoError: const SocketException('Failed host lookup'),
          seedCache: true,
        );

        final plan = await container.read(planoAtivoProvider.future);
        expect(plan.id, 'plan-cached');
        expect(plan.userId, userId);
        expect(plan.plano, PlanoTipo.prata);
      },
    );

    test(
      'SocketException sem cache lança PlanoCacheUnavailableException',
      () async {
        final container = await buildContainer(
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
      },
    );

    test('AuthException não serve cache mesmo com UserPlan gravado', () async {
      final container = await buildContainer(
        repoError: const AuthException('JWT expired'),
        seedCache: true,
      );

      await expectLater(
        container.read(planoAtivoProvider.future),
        throwsA(isA<AuthException>()),
      );
    });

    test('PostgrestException PGRST301 não serve cache', () async {
      final container = await buildContainer(
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

    test('erro de sessão: refresh uma vez e repetição bem-sucedida', () async {
      final repo = _SequencePlanoRepo([
        const AuthException('JWT expired'),
        cachedPlan(),
      ]);
      var refreshes = 0;
      final container = await buildContainer(
        repoError: const AuthException('unused'),
        repo: repo,
        refresh: () async => refreshes++,
      );

      final plan = await container.read(planoAtivoProvider.future);
      expect(plan.id, 'plan-cached');
      expect(refreshes, 1);
      expect(repo.calls, 2);
    });

    test(
      'erro de sessão persistente após refresh lança e não serve cache',
      () async {
        final repo = _SequencePlanoRepo([
          const AuthException('JWT expired'),
          const AuthException('still expired'),
        ]);
        var refreshes = 0;
        final container = await buildContainer(
          repoError: const AuthException('unused'),
          repo: repo,
          seedCache: true,
          refresh: () async => refreshes++,
        );

        await expectLater(
          container.read(planoAtivoProvider.future),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'JWT expired',
            ),
          ),
        );
        expect(refreshes, 1);
        expect(repo.calls, 2);
      },
    );

    test('falha no refresh mantém erro original e não serve cache', () async {
      final repo = _SequencePlanoRepo([const AuthException('JWT expired')]);
      final container = await buildContainer(
        repoError: const AuthException('unused'),
        repo: repo,
        seedCache: true,
        refresh: () async => throw const SocketException('offline'),
      );

      await expectLater(
        container.read(planoAtivoProvider.future),
        throwsA(isA<AuthException>()),
      );
      expect(repo.calls, 1);
    });

    test('erro não-auth não chama refresh e continua usando cache', () async {
      var refreshes = 0;
      final container = await buildContainer(
        repoError: const SocketException('Failed host lookup'),
        seedCache: true,
        refresh: () async => refreshes++,
      );

      final plan = await container.read(planoAtivoProvider.future);
      expect(plan.id, 'plan-cached');
      expect(refreshes, 0);
    });
  });

  group('describePlanoLoadFailure', () {
    test('distingue parse de rede e inclui tipo e código', () {
      expect(
        describePlanoLoadFailure(const FormatException('x')),
        contains('parse'),
      );
      expect(describePlanoLoadFailure(ArgumentError('x')), contains('parse'));
      final net = describePlanoLoadFailure(const SocketException('x'));
      expect(net, contains('rede/outros'));
      expect(net, contains('SocketException'));
      expect(
        describePlanoLoadFailure(
          const PostgrestException(message: 'm', code: '42P01'),
        ),
        contains('42P01'),
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
  Future<List<Referral>> getReferrals(String referrerId) async => const [];

  @override
  Stream<UserPlan> watchPlanoAtivo(String userId) => const Stream.empty();

  @override
  Future<ReferralCode?> getMeuCodigoIndicacao(String userId) async => null;
}

class _SequencePlanoRepo extends _ThrowingPlanoRepo {
  _SequencePlanoRepo(this.outcomes) : super(StateError('unused'));

  final List<Object> outcomes;
  int calls = 0;

  @override
  Future<UserPlan> getPlanoAtivo(String userId) async {
    final outcome =
        outcomes[calls < outcomes.length ? calls : outcomes.length - 1];
    calls++;
    if (outcome is UserPlan) return outcome;
    throw outcome;
  }
}
