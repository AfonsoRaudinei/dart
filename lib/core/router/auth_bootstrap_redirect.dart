import '../session/session_models.dart';
import 'app_routes.dart';

/// Decisão de redirect durante a janela [isInitializing] (BUG-010).
///
/// Regras:
/// - Sessão já autenticada (sync `currentUser`) → `/map` (nunca hop por `/public-map`)
/// - Recovery → `/reset-password`
/// - Ainda desconhecido → `null` (permanece na rota atual; UI mostra hold, não o mapa público pesado)
///
/// Retorna `null` quando o redirect principal (pós-bootstrap) deve decidir.
String? authBootstrapRedirect({
  required bool isInitializing,
  required SessionState session,
  required String currentPath,
}) {
  if (!isInitializing) return null;

  if (session is SessionPasswordRecovery) {
    return currentPath == AppRoutes.resetPassword
        ? null
        : AppRoutes.resetPassword;
  }

  if (session is SessionAuthenticated) {
    return currentPath == AppRoutes.map ? null : AppRoutes.map;
  }

  // SessionUnknown / SessionPublic: não forçar remount de /public-map.
  return null;
}
