import '../router/app_routes.dart';
import '../session/user_role.dart';

class AppAccess {
  const AppAccess._();

  static bool canAccessPath(String? role, String path) {
    final userRole = role.toUserRole();

    if (AppRoutes.publicRoutes.contains(path)) {
      return true;
    }

    if (path == AppRoutes.map || path.startsWith('${AppRoutes.map}/')) {
      return true;
    }

    if (userRole.isConsultor) {
      return true;
    }

    if (userRole.isUnknown) {
      return _producerAllowedExactRoutes.contains(path) ||
          _producerAllowedPrefixes.any(path.startsWith);
    }

    if (!userRole.isProdutor) {
      return false;
    }

    return _producerAllowedExactRoutes.contains(path) ||
        _producerAllowedPrefixes.any(path.startsWith);
  }

  static bool canSeeMenuItem(String? role, String route) {
    return canAccessPath(role, route);
  }

  static bool canSeeQuickAction(String? role, String route) {
    return canAccessPath(role, route);
  }

  static const Set<String> _producerAllowedExactRoutes = {
    AppRoutes.feedback,
    AppRoutes.clima,
    AppRoutes.producerProperty,
    AppRoutes.settings,
    AppRoutes.settingsEditProfile,
    AppRoutes.planos,
    AppRoutes.meuPlano,
    AppRoutes.planosPagamento,
    AppRoutes.planosConfirmacao,
    AppRoutes.planosIndicacoes,
  };

  static const List<String> _producerAllowedPrefixes = [];
}
