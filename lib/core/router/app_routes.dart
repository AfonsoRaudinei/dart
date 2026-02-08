/// Define os níveis de navegação do SmartButton.
///
/// - [l0]: Mapa (raiz) — ícone ☰, abre SideMenu
/// - [l1]: Módulos raiz — ícone ←, vai para /dashboard via go()
/// - [l2Plus]: Subtelas — ícone ←, usa pop() com fallback para /dashboard
/// - [public]: Rotas públicas — CTA "Acessar SoloForte"
enum RouteLevel { l0, l1, l2Plus, public }

class AppRoutes {
  // Públicas
  static const String publicMap = '/public-map';
  static const String login = '/login';
  static const String signup = '/signup';

  // Privadas — L0 (Mapa/Dashboard = raiz absoluta)
  static const String dashboard = '/dashboard';

  // Privadas — L1 (Módulos raiz que voltam direto para o mapa)
  static const String settings = '/settings';
  static const String agenda = '/agenda';
  static const String feedback = '/feedback';
  static const String reports = '/consultoria/relatorios';
  static const String clients = '/consultoria/clientes';

  // Privadas — L2+ (Níveis Profundos que usam pop)
  static const String reportNew = '/consultoria/relatorios/novo';
  static String reportDetail(String id) => '/consultoria/relatorios/$id';

  static const String clientNew = '/consultoria/clientes/novo';
  static String clientDetail(String id) => '/consultoria/clientes/$id';

  static String farmDetail(String clientId, String farmId) =>
      '/consultoria/clientes/$clientId/fazendas/$farmId';

  static String fieldDetail(String clientId, String farmId, String fieldId) =>
      '/consultoria/clientes/$clientId/fazendas/$farmId/talhoes/$fieldId';

  // ════════════════════════════════════════════════════════════════════
  // CLASSIFICAÇÃO DETERMINÍSTICA DE NÍVEL DE ROTA
  // ════════════════════════════════════════════════════════════════════

  /// Set de rotas públicas (não autenticadas)
  static const Set<String> publicRoutes = {
    publicMap,
    login,
    signup,
    '/', // Landing page redirect
  };

  /// Set de rotas L1 (módulos raiz que voltam direto para o mapa)
  /// Matching EXATO por path, sem contains() ou heurísticas
  static const Set<String> level1Routes = {
    settings,
    agenda,
    feedback,
    reports,
    clients,
  };

  /// Classifica o nível de uma rota de forma DETERMINÍSTICA.
  ///
  /// Regras de classificação (em ordem de prioridade):
  /// 1. Se está em [publicRoutes] → [RouteLevel.public]
  /// 2. Se é exatamente [dashboard] ou inicia com '/dashboard/' → [RouteLevel.l0]
  /// 3. Se está em [level1Routes] (match exato) → [RouteLevel.l1]
  /// 4. Qualquer outra rota autenticada → [RouteLevel.l2Plus]
  static RouteLevel getLevel(String path) {
    // 1. Rotas públicas
    if (publicRoutes.contains(path)) {
      return RouteLevel.public;
    }

    // 2. L0 = Dashboard (mapa)
    // Suporta /dashboard e sub-rotas /dashboard/*
    if (path == dashboard || path.startsWith('$dashboard/')) {
      return RouteLevel.l0;
    }

    // 3. L1 = Módulos raiz (match exato)
    if (level1Routes.contains(path)) {
      return RouteLevel.l1;
    }

    // 4. L2+ = Qualquer outra rota autenticada (subtelas)
    return RouteLevel.l2Plus;
  }

  /// Retorna true se a rota atual permite abrir o SideMenu.
  /// SideMenu SOMENTE disponível no L0 (Dashboard/Mapa).
  static bool canOpenSideMenu(String path) {
    return getLevel(path) == RouteLevel.l0;
  }
}
