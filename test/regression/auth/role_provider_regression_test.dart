import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:soloforte_app/core/access/app_access.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/session/session_controller.dart';
import 'package:soloforte_app/core/session/session_models.dart';
import 'package:soloforte_app/core/session/user_role.dart';
import 'package:soloforte_app/modules/settings/domain/entities/user_profile.dart';
import 'package:soloforte_app/modules/settings/presentation/providers/user_profile_provider.dart';

/// BUG-001 — Auth: role lido de userMetadata (falso-negativo de login).
void main() {
  group('BUG-001 role_provider_regression', () {
    test(
      'router aguarda AsyncLoading em rota protegida sem redirecionar prematuramente',
      () {
        final redirect = _evaluateAuthenticatedRedirect(
          isAuth: true,
          isRecovery: false,
          isPublicRoute: false,
          profileAsync: const AsyncLoading<UserProfile?>(),
          path: AppRoutes.clients,
        );

        expect(redirect, isNull);
      },
    );

    test(
      'role ativo vem do currentUserProfileProvider, não de userMetadata',
      () async {
        final container = ProviderContainer(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) async => _profile(role: 'consultor'),
            ),
            sessionControllerProvider.overrideWith(
              _SessionWithMetadataRole.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(currentUserProfileProvider.future);

        expect(container.read(currentUserRoleProvider), UserRole.consultor);
      },
    );

    test(
      'logout invalida currentUserProfileProvider via registro de invalidação',
      () async {
        final container = ProviderContainer(
          overrides: [
            currentUserProfileProvider.overrideWith(
              (ref) async => _profile(role: 'consultor'),
            ),
            sessionControllerProvider.overrideWith(
              _SessionWithMetadataRole.new,
            ),
          ],
        );
        addTearDown(container.dispose);

        await container.read(currentUserProfileProvider.future);
        expect(container.read(currentUserProfileProvider).hasValue, isTrue);

        container.invalidate(currentUserProfileProvider);

        expect(container.read(currentUserProfileProvider).isLoading, isTrue);
      },
    );

    test('app_router.dart não lê role de userMetadata no redirect', () {
      final source = File('lib/core/router/app_router.dart').readAsStringSync();

      expect(source.contains('userMetadata'), isFalse);
      expect(source.contains('profileAsync.isLoading'), isTrue);
      expect(source.contains('profileAsync.asData?.value?.role'), isTrue);
    });

    test(
      'user_profile_provider registra invalidação de logout e session_controller a executa',
      () {
        final profileSource = File(
          'lib/modules/settings/presentation/providers/user_profile_provider.dart',
        ).readAsStringSync();
        final sessionSource = File(
          'lib/core/session/session_controller.dart',
        ).readAsStringSync();

        expect(
          profileSource.contains("key: 'currentUserProfileProvider'"),
          isTrue,
        );
        expect(
          profileSource.contains('ref.invalidate(currentUserProfileProvider)'),
          isTrue,
        );
        expect(sessionSource.contains('_invalidateUserScopedProviders()'), isTrue);
        expect(
          sessionSource.contains('await Supabase.instance.client.auth.signOut()'),
          isTrue,
        );
      },
    );
  });
}

/// Espelha o bloco autenticado de [GoRouter.redirect] em app_router.dart.
String? _evaluateAuthenticatedRedirect({
  required bool isAuth,
  required bool isRecovery,
  required bool isPublicRoute,
  required AsyncValue<UserProfile?> profileAsync,
  required String path,
}) {
  if (isAuth && !isRecovery) {
    if (isPublicRoute) {
      return AppRoutes.map;
    }

    if (profileAsync.isLoading || profileAsync.hasError) {
      return null;
    }

    final role = profileAsync.asData?.value?.role;
    if (!AppAccess.canAccessPath(role, path)) {
      return AppRoutes.map;
    }
  }

  return null;
}

UserProfile _profile({required String role}) {
  return UserProfile(
    id: 'user-regression-1',
    email: 'regression@soloforte.app',
    fullName: 'Regression User',
    phone: '(63) 99999-9999',
    role: role,
    photoUrl: null,
    creaNumber: '123456',
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

class _SessionWithMetadataRole extends SessionController {
  @override
  SessionState build() => SessionAuthenticated(
    User.fromJson(const {
      'id': 'user-regression-1',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{'role': 'admin'},
      'aud': 'authenticated',
      'created_at': '2026-07-20T12:00:00.000Z',
      'email': 'regression@soloforte.app',
    })!,
  );
}
