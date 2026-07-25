import '../../../core/session/session_models.dart';

/// Política do CTA público "Acessar SoloForte" e do SmartButton no shell.
///
/// Evita regressão do card fantasma no reopen (auth ainda em /public-map
/// enquanto o perfil carrega) e do FAB.extended sobreposto ao card.
///
/// Regras:
/// - CTA [AccessSoloForteButton]: só em [SessionPublic] (visitante confirmado)
/// - SmartButton no [AppShell]: só autenticado em rota privada
bool shouldShowPublicAccessCta(SessionState session) => session is SessionPublic;

/// SmartButton / SideMenu no shell — ocultos em rotas públicas.
bool shouldShowShellChrome({
  required bool isAuthenticated,
  required bool isPublicRoute,
}) =>
    isAuthenticated && !isPublicRoute;
