import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/router/app_routes.dart';
import 'package:soloforte_app/core/router/auth_bootstrap_redirect.dart';
import 'package:soloforte_app/core/session/session_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// BUG-010 — Reopen autenticado não deve hopar por `/public-map` nem
/// recriar o GoRouter quando o perfil carrega (flash de "clique sozinho").
void main() {
  group('BUG-010 auth_bootstrap_reopen_regression', () {
    test('autenticado durante isInitializing redireciona para /map', () {
      expect(
        authBootstrapRedirect(
          isInitializing: true,
          session: SessionAuthenticated(_user()),
          currentPath: AppRoutes.publicMap,
        ),
        AppRoutes.map,
      );
    });

    test('já em /map durante bootstrap autenticado → null (sem remount)', () {
      expect(
        authBootstrapRedirect(
          isInitializing: true,
          session: SessionAuthenticated(_user()),
          currentPath: AppRoutes.map,
        ),
        isNull,
      );
    });

    test('SessionUnknown durante bootstrap → null (hold, não força public-map)',
        () {
      expect(
        authBootstrapRedirect(
          isInitializing: true,
          session: const SessionUnknown(),
          currentPath: AppRoutes.publicMap,
        ),
        isNull,
      );
    });

    test('recovery durante bootstrap → /reset-password', () {
      expect(
        authBootstrapRedirect(
          isInitializing: true,
          session: SessionPasswordRecovery(_user()),
          currentPath: AppRoutes.publicMap,
        ),
        AppRoutes.resetPassword,
      );
    });

    test('pós-bootstrap: helper não interfere', () {
      expect(
        authBootstrapRedirect(
          isInitializing: false,
          session: SessionAuthenticated(_user()),
          currentPath: AppRoutes.publicMap,
        ),
        isNull,
      );
    });

    test('router não usa ref.watch(profile) no factory (anti-recreate)', () {
      final source =
          File('lib/core/router/app_router.dart').readAsStringSync();

      expect(source.contains('authBootstrapRedirect('), isTrue);
      expect(source.contains('PublicMapEntryScreen'), isTrue);
      expect(source.contains('refreshRedirect()'), isTrue);

      // Invariante: watch do perfil no factory recria GoRouter → flash.
      // Comentários podem citar o anti-padrão; só a chamada real conta.
      expect(
        RegExp(r'^\s*final\s+\w+\s*=\s*ref\.watch\(currentUserProfileProvider\)',
                multiLine: true)
            .hasMatch(source),
        isFalse,
      );
      expect(
        RegExp(r'^\s*ref\.watch\(currentUserProfileProvider\)', multiLine: true)
            .hasMatch(source),
        isFalse,
      );
      // Redirect ainda lê o perfil (ACL) sem invalidar o provider do router.
      expect(
        source.contains('ref.read(currentUserProfileProvider)'),
        isTrue,
      );
      // Guard antigo que forçava hop pelo public-map foi removido.
      expect(
        source.contains('return AppRoutes.publicMap; // seguro'),
        isFalse,
      );
    });

    test('RouterNotifier corta isInitializing se sessão sync já autenticada',
        () {
      final source =
          File('lib/core/router/router_notifier.dart').readAsStringSync();

      expect(source.contains('SessionAuthenticated'), isTrue);
      expect(source.contains('_isInitializing = false'), isTrue);
      expect(source.contains('void refreshRedirect()'), isTrue);
    });

    test('PublicMapEntryScreen hold durante bootstrap (sem PublicMapScreen)',
        () {
      final source = File('lib/ui/screens/public_map_entry_screen.dart')
          .readAsStringSync();

      expect(source.contains('isInitializing'), isTrue);
      expect(source.contains('_AuthBootstrapHold'), isTrue);
      expect(source.contains('PublicMapScreen'), isTrue);
    });
  });
}

User _user() => User.fromJson(const {
      'id': 'user-bug010',
      'app_metadata': <String, dynamic>{},
      'user_metadata': <String, dynamic>{},
      'aud': 'authenticated',
      'created_at': '2026-08-16T12:00:00.000Z',
    })!;
