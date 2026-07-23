import 'package:flutter_test/flutter_test.dart';
import 'package:soloforte_app/core/access/app_access.dart';
import 'package:soloforte_app/core/router/app_routes.dart';

void main() {
  group('AppAccess', () {
    test('produtor não acessa agenda, clientes e carteira', () {
      expect(AppAccess.canAccessPath('produtor', AppRoutes.agenda), false);
      expect(AppAccess.canAccessPath('produtor', AppRoutes.clients), false);
      expect(AppAccess.canAccessPath('produtor', AppRoutes.carteira), false);
    });

    test('produtor acessa áreas permitidas', () {
      expect(AppAccess.canAccessPath('produtor', AppRoutes.feedback), true);
      expect(AppAccess.canAccessPath('produtor', AppRoutes.clima), true);
      expect(
        AppAccess.canAccessPath('produtor', AppRoutes.producerProperty),
        true,
      );
      expect(AppAccess.canAccessPath('produtor', AppRoutes.reports), true);
      expect(AppAccess.canAccessPath('produtor', AppRoutes.settings), true);
      expect(
        AppAccess.canAccessPath('produtor', AppRoutes.settingsEditProfile),
        true,
      );
      expect(AppAccess.canAccessPath('produtor', AppRoutes.meuPlano), true);
    });

    test('consultor acessa toda a área privada', () {
      expect(AppAccess.canAccessPath('consultor', AppRoutes.agenda), true);
      expect(AppAccess.canAccessPath('consultor', AppRoutes.clients), true);
      expect(AppAccess.canAccessPath('consultor', AppRoutes.reports), true);
      expect(AppAccess.canAccessPath('consultor', AppRoutes.carteira), true);
      expect(
        AppAccess.canAccessPath('consultor', AppRoutes.settingsEditProfile),
        true,
      );
    });

    test('rota pública continua liberada', () {
      expect(AppAccess.canAccessPath('produtor', AppRoutes.login), true);
      expect(AppAccess.canAccessPath('consultor', AppRoutes.publicMap), true);
    });

    test('papel desconhecido mantém apenas o conjunto restrito', () {
      expect(AppAccess.canAccessPath(null, AppRoutes.settings), true);
      expect(
        AppAccess.canAccessPath(null, AppRoutes.settingsEditProfile),
        true,
      );
      expect(AppAccess.canAccessPath(null, AppRoutes.agenda), false);
    });

    test('edição de perfil permanece privada e classificada como subtela', () {
      expect(
        AppRoutes.publicRoutes.contains(AppRoutes.settingsEditProfile),
        false,
      );
      expect(
        AppRoutes.getLevel(AppRoutes.settingsEditProfile),
        RouteLevel.l2Plus,
      );
    });
  });
}
